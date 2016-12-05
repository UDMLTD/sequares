module Sequares
  class HistoryPage
    include Enumerable
    extend Forwardable
    attr_reader :backend, :lookup, :uncommitted

    def_delegator :@uncommitted, :<<

    def initialize(backend, lookup)
      @backend = backend
      @lookup = lookup
      @marshaller = Marshal

      uncommitted_clear
      rewind!
    end

    def each
      return to_enum(:each) unless block_given?
      cursor = 0
      per_page = 1_000
      loop do
        store_value = _mget(cursor, (cursor + per_page - 1)).collect do |event|
          _load event
        end
        if store_value.empty?
          from = (cursor - committed_length)
          to = from + 1
          range = Range.new(from, to)
          store_value = Array(uncommitted.slice(range))
        end

        break if store_value.empty?

        cursor += store_value.length

        store_value.each do |event|
          yield event
        end
      end
      self
    end
    alias each_page each

    def length
      committed_length + uncommitted_length
    end

    def uncommitted_length
      @uncommitted.length
    end

    def uncommitted_clear
      @uncommitted = []
    end

    def committed_length
      backend.llen(lookup)
    end

    def first
      _load _mget(0, 0)[0]
    end

    def last
      _load _mget(-1, -1)[0]
    end

    def rewind!
      @cursor = 0
    end

    private def _next(n)
      store_value = _mget(@cursor, (@cursor + n - 1)).collect do |event|
        _load event
      end
      if store_value.empty?
        from = (@cursor - committed_length)
        to = from + 1
        range = Range.new(from, to)
        return Array(@uncommitted.slice(range))
      end
      store_value

    ensure
      @cursor += n
    end

    private def _mget(from, to)
      if (keys = backend.lrange(lookup, from, to)).any?
        return backend.hmget("events", *keys)
      end
      []
    end

    private def _load(event)
      @marshaller.load(event)
    rescue
      nil
    end
  end
end

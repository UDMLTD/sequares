module Sequares
  class Entity
    AlreadyLocked = StandardError.new
    attr_accessor :id
    attr_reader :history
    def initialize(id=nil)
      unless id
        hashids = Hashids.new(Sequares.configuration.hashids_salt)
        id = hashids.encode_hex(SecureRandom.hex)
      end
      @id = id
      @history = HistoryPage.new(Sequares.repository.backend, "lookups:#{cache_key}")
    end

    class << self
      def uri(id)
        ActiveSupport::Inflector.underscore([name, id].join("|"))
      end

      def with_history(id, history)
        ent = new(id)
        history.each do |event|
          ent.history << event
        end
        ent
      end
    end

    def execute(cmd)
      cmd.to_proc.call(self)
      self
    end

    def uri
      ActiveSupport::Inflector.underscore([self.class.name, id].join("|"))
    end

    def cache_key
      "#{self.class.name}@#{id}"
    end
  end
end

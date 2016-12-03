module Sequares
  class Repository
    include RepositoryCommon
    attr_reader :backend
    def initialize(backend)
      @backend = backend
      @marshaller = Marshal
    end

    def save_history_for(entity)
      entity.history.uncommitted.each_slice(1_000) do |events|
        _save_events_for(entity, *events)
      end
      entity.history.uncommitted_clear
      nil
    end

    private def _unsaved_history(entity)
      exisiting_history = for_entity(entity)
      Array(entity.history.slice(Range.new(exisiting_history.length, -1)))
    end

    def reset
      backend.flushdb
    end

    def all
      HistoryPage.new(backend, "lookups:global")
    end

    def load(klass, id)
      klass.new(id).tap do |entity|
        entity.instance_variable_set(:@history, for_entity(entity))
      end
    end

    def lock_keys(entity)
      keys = []
      keys << "events:lock"
      keys << "lookups:#{entity.cache_key}:lock"
      keys
    end

    def lock(entity)
      raise ::Sequares::Entity::AlreadyLocked unless _lock(entity)
    end

    private def _lock(entity)
      backend.setnx("#{entity.cache_key}:lock", Time.now.utc)
    end

    def unlock(entity)
      backend.del("#{entity.cache_key}:lock")
    end

    def for_entity(entity)
      HistoryPage.new(backend, "lookups:#{entity.cache_key}")
    end

    def for_event_klass(klass)
      HistoryPage.new(backend, "lookups:#{klass.name}")
    end

    def entity_for_event(event)
      entity_class_for_event(event).new(entity_id_for_event(event))
    end

    def entity_class_for_event(event)
      klass = backend.get "rlookup:class:#{_hash_event(event)}"
      Object.const_get(klass.to_s)
    end

    def entity_id_for_event(event)
      backend.get("rlookup:id:#{_hash_event(event)}")
    end

    def klass_in_klasses?(needle, klasses)
      klasses.any? do |klass|
        needle.is_a?(klass) || needle.class.to_s.split("::").first.eql?(klass.to_s)
      end
    end

    def filter_events(*klasses)
      out = {}
      klasses.each do |klass|
        for_event_klass(klass).each do |event|
          out[entity_for_event(event)] = event if klass_in_klasses?(event, klasses)
        end
      end
      out.sort_by do |_entity, event|
        event.occurred_at
      end
    end

    private def _save_events_for(entity, *events)
      kv_pairs = events.collect do |event|
        [_hash_event(event), event]
      end
      backend.multi do |multi|
        multi.hmset("events", *kv_pairs.flatten.each_slice(2).collect do |addr, event|
          [addr, @marshaller.dump(event)]
        end.flatten)

        addrs = kv_pairs.collect(&:first)

        kv_pairs.flatten.each_slice(2) do |addr, event|
          multi.set "rlookup:id:#{addr}", entity.id
          multi.set "rlookup:class:#{addr}", entity.class.name
          ev_klass_split = event.class.name.split("::")
          if ev_klass_split.length > 1
            multi.rpush "lookups:#{ev_klass_split.first}", addr
          end
          multi.rpush "lookups:#{event.class.name}", addr
        end
        multi.rpush "lookups:global", addrs
        multi.rpush "lookups:#{entity.class}", addrs
        multi.rpush "lookups:#{entity.cache_key}", addrs
      end
    end
  end
end

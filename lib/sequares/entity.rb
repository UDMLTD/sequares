module Sequares
  class Entity
    include Sequares::String

    AlreadyLocked = StandardError.new
    attr_accessor :id, :history
    def initialize(id=nil)
      @history = []
      @id = id
    end

    class << self
      def load(id=nil)
        # Make a ID if not provided one
        unless id
          hashids = Hashids.new(Sequares.configuration.hashids_salt)
          id = hashids.encode_hex(SecureRandom.hex)
        end

        obj = new(id)
        history = Sequares.configuration.store.fetch_history_for_aggregate(obj)

        with_history(id, history)
      end

      def uri(id)
        ActiveSupport::Inflector.underscore([name, id].join("|"))
      end

      def with_history(id, history)
        ent = new(id)
        ent.history = history
        ent
      end
    end

    def execute(cmd)
      cmd.to_proc.call(self)
      self
    end

    def apply(event)
      history << event
    end

    def uri
      ActiveSupport::Inflector.underscore([self.class.name, id].join("|"))
    end
  end
end

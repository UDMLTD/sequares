module Sequares
  class Entity
    AlreadyLocked = StandardError.new
    attr_accessor :id, :history
    def initialize
      @history = []
    end

    class << self
      def load(id=nil)
        # Make a ID if not provided one
        unless id
          hashids = Hashids.new(Sequares.configuration.hashids_salt)
          id = hashids.encode_hex(SecureRandom.hex)
        end

        obj = new
        obj.id = id
        history = Sequares.configuration.store.fetch_history_for_aggregate(obj)

        with_history(id, history)
      end

      def uri(id)
        [name.downcase, id].join("/")
      end

      def with_history(id, history)
        ent = new
        ent.id = id
        ent.history = history
        ent
      end
    end

    def execute(cmd)
      cmd.to_proc.call(self)
      self
    end

    def uri
      [self.class.name.downcase, id].join("/")
    end
  end
end

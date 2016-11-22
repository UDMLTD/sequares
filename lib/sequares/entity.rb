module Sequares
  class Entity
    include Sequares::String

    AlreadyLocked = StandardError.new
    attr_accessor :id, :history, :pending_events
    def initialize
      @history = []
      @pending_events = []
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

    def apply(event)
      do_apply event
      history << event
      pending_events << event
    end

    def do_apply(event)
      method_name = "on_#{event.key}"
      method(method_name).call(event) if respond_to? method_name
    end

    def uri
      [self.class.name.downcase, id].join("/")
    end
  end
end

module Sequares
  class Event
    include Sequares::String

    class << self
      alias subclass_new new
    end

    def self.new(*attrs, &block)
      attr_sym_names = attrs.push(:occurred_at).map do |a|
        case a
        when Symbol
          a
        when String
          sym = a.to_sym
          unless sym.is_a? Symbol
            raise TypeError, "#to_sym didn't return a symbol"
          end
          sym
        else
          raise TypeError, "#{a.inspect} is not a symbol"
        end
      end

      klass = Class.new self do
        attr_accessor(*attr_sym_names)
        attr_accessor :entity_id, :entity_klass

        def self.new(**args, &block)
          # args is a hash of key-value pairs representing the keyword arguments
          subclass_new(**args, &block)
        end

        const_set :EVENT_ATTRS, attr_sym_names
      end

      klass.module_eval(&block) if block

      klass
    end

    define_method(:initialize) do |**kwargs|
      attrs = _attrs

      kwargs[:occurred_at] = Time.now.utc unless kwargs.key? :occurred_at

      unless kwargs.keys.sort == attrs.sort
        extra   = kwargs.keys - attrs
        missing = attrs - kwargs.keys

        raise ArgumentError, <<-MESSAGE
          keys do not match expected list:
          -- missing keys: #{missing}
          -- extra keys:   #{extra}
    MESSAGE
      end

      kwargs.map do |k, v|
        instance_variable_set "@#{k}", v
      end
    end
    private :initialize

    def to_h
      h = {}
      _attrs.each do |attr_name|
        h[attr_name] = instance_variable_get("@#{attr_name}")
      end
      h
    end

    def eql?(other)
      return false if self.class != other.class
      to_h.eql?(other.to_h)
    end

    def key
      underscore(self.class.name.to_s)
    end

    private def _attrs # :nodoc:
      self.class::EVENT_ATTRS
    end
  end
end

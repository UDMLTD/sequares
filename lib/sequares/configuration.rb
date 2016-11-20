module Sequares
  class Configuration
    attr_accessor :store, :use_cache, :cache, :hashids_salt
    def initialize
      @store = Sequares::Store::Redis.new
      @use_cache = true
      @hashids_salt = "sequares"
      # @cache = ::Memcached.new('localhost:11211')
    end
  end
end

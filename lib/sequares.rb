require "redis"
require "delegate"
require "time"
require "forwardable"
require "hashids"
require "securerandom"

require "active_support/inflector"

require "sequares/version"
require "sequares/configuration"

require "sequares/event_bus/base"
require "sequares/event_bus/memory"
require "sequares/event_bus/redis"

require "sequares/command"
require "sequares/entity"
require "sequares/error"
require "sequares/event"
require "sequares/value_object"

require "sequares/ext/hash_extensions"
require "sequares/backend/memory"
require "sequares/helpers"
require "sequares/repository"
require "sequares/repository_with_callback"
require "sequares/history_page"

module Sequares
  AlreadyLocked = StandardError.new
  class << self
    attr_writer :configuration
    attr_reader :repository

    # def_delegators :@configuration, :store

    # delegate :cache_key_for, to: :store

    def configuration
      @configuration ||= Configuration.new
    end

    def repository
      @repository = configuration.repository
    end

    def configure
      yield(configuration)
    end

    def reset
      @configuration = Configuration.new
    end

    def filter_events(*klasses)
      @configuration.repository.filter_events(klasses)
    end

    def with_entities(entities_array)
      entities = entities_array.each_slice(2).collect do |klass, id|
        entity = repository.load(klass, id)
        # repository.lock(entity) # NOTE: for another day
        entity
      end

      yield(*entities) if block_given?
      entities
    ensure
      entities.each do |entity|
        repository.save_history_for(entity)
        # repository.unlock(entity) #
      end
      entities
    end
  end
end

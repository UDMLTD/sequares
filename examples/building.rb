require "byebug"
require "singleton"
require "forwardable"

class EmailAddressesInUseService
  include Singleton
  extend Forwardable

  def_delegators :@mutex_instance, :synchronize
  attr_accessor :last_updated_at, :emails_in_use

  def initialize
    @mutex_instance = Mutex.new
    @last_updated_at ||= 0
    @emails_in_use ||= Set.new
  end

  def handle_message(entity, event)
    synchronize do
      _handle_message(entity, event)
      # write to a cache here
    end
    # warmup
  end

  private def _handle_message(entity, event)
    entity_set = Sequares.repository.load(User, entity.id)
    dead_email = entity_set.history.select do |i|
      i.occurred_at < event.occurred_at
    end.last

    emails_in_use.delete?(user_id: entity.id, email: dead_email.email) if dead_email
    emails_in_use << { user_id: entity.id, email: event.email }
    @last_updated_at = event.occurred_at
  end

  def warmup
    synchronize do
      entity_event_pairs = Sequares.filter_events(::User::Event::EmailChanged)
      entity_event_pairs.each do |entity, event|
        _handle_message(entity, event) if event.occurred_at > last_updated_at
      end
      # write to a cache here
    end
  end

  def has_email?(email)
    emails_in_use.any? do |item|
      item[:email].eql? email
    end
  end
end

class User < Sequares::Entity
  module Error
    class EmailNotUnique < StandardError; end
  end
  module Cmd
    class SetEmail < Sequares::Command.new(:email)
      def to_proc
        lambda do |entity|
          raise ::User::Error::EmailNotUnique if EmailAddressesInUseService.instance.has_email?(email)
          entity.history << ::User::Event::EmailChanged.new(to_h)
        end
      end
    end
  end
  module Event
    EmailChanged = Sequares::Event.new(:email)
  end
end

Address = Sequares::ValueObject.new(
  :line1,
  :line2,
  :locality,
  :administrative_area,
  :postal_code,
  :country
)

module BuildingCommands
  class SetName < Sequares::Command.new(:name)
    def to_proc
      lambda do |entity|
        entity.history << Building::Event::NameChanged.new(to_h)
      end
    end
  end

  class SetAddress < Sequares::Command.new(:address)
    def to_proc
      lambda do |ent|
        ent.history << Building::Event::AddressChanged.new(to_h)
      end
    end
  end

  class AddArea < Sequares::Command.new(:area_id)
    def to_proc
      lambda do |ent|
        ent.history << Building::Event::AreaAdded.new(to_h)
      end
    end
  end

  class RemoveArea < Sequares::Command.new(:area_id)
    def to_proc
      lambda do |ent|
        ent.history << Building::Event::AreaRemoved.new(to_h)
      end
    end
  end
end

class Building < Sequares::Entity
  include BuildingCommands

  module Event
    NameChanged = Sequares::Event.new(:name)
    AddressChanged = Sequares::Event.new(:address)
    AreaAdded = Sequares::Event.new(:area_id)
    AreaRemoved = Sequares::Event.new(:area_id)
  end

  def name
    obj = history.dup.select do |i|
      i.is_a? Event::NameChanged
    end.last
    obj.name if obj
  end

  def address
    obj = history.dup.select do |i|
      i.is_a? Event::AddressChanged
    end.last
    obj.address if obj
  end
end

class BuildingPresenter
  extend Forwardable
  attr_reader :entity
  def_delegators :@entity, :history, :name, :address

  def initialize(entity)
    @entity = entity
  end

  def created_at
    history.first.occurred_at
  end

  def updated_at
    history.last.occurred_at
  end

  def area_ids
    local_history = history.dup
    ids = local_history.select do |i|
      i.is_a? Building::Event::AreaAdded
    end.collect(&:area_id)
    removed_ids = local_history.select do |i|
      i.is_a? Building::Event::AreaRemoved
    end.collect(&:area_id)
    ids - removed_ids
  end

  def to_h
    {
      name: name,
      created_at: created_at,
      updated_at: updated_at,
      address: address.to_h,
      area_ids: area_ids
    }
  end
end

module AreaCommands
  class SetName < Sequares::Command.new(:name)
    def to_proc
      lambda do |ent|
        ent.history << Area::Event::NameChanged.new(to_h)
      end
    end
  end

  class SetType < Sequares::Command.new(:type)
    def to_proc
      lambda do |ent|
        ent.history << Area::Event::TypeChanged.new(to_h)
      end
    end
  end

  class AssignBuilding < Sequares::Command.new(:building_id)
    def to_proc
      lambda do |ent|
        ent.history << Area::Event::BuildingAssignment.new(to_h)
      end
    end
  end
end

class Area < Sequares::Entity
  include AreaCommands

  module Event
    NameChanged = Sequares::Event.new(:name)
    TypeChanged = Sequares::Event.new(:type)
    BuildingAssignment = Sequares::Event.new(:building_id)
  end
end

class AreaPresenter
  extend Forwardable
  attr_reader :entity, :building
  def_delegators :@entity, :history, :name, :address

  def initialize(entity)
    @entity = entity
  end

  def created_at
    history.first.occurred_at
  end

  def updated_at
    history.last.occurred_at
  end

  def name
    obj = history.dup.select do |i|
      i.is_a? Area::Event::NameChanged
    end.last
    obj.name if obj
  end

  def building
    @building ||= Sequares.repository.load(Building, building_id)
  end

  def building_id
    obj = history.dup.select do |i|
      i.is_a? Area::Event::BuildingAssignment
    end.last
    obj.building_id if obj
  end

  def building_name
    obj = building.history.dup.select do |i|
      i.is_a? Building::Event::NameChanged
    end.last
    obj.name if obj
  end

  def area_type
    obj = history.dup.select do |i|
      i.is_a? Area::Event::TypeChanged
    end.last
    obj.type if obj
  end

  def to_h
    {
      name: name,
      type: area_type,
      building_name: building_name,
      building_id: building_id
    }
  end
end

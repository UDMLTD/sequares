require "spec_helper"

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
    obj = history.select do |i|
      i.is_a? Event::NameChanged
    end.last
    obj.name if obj
  end

  def address
    obj = history.select do |i|
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
    ids = history.select do |i|
      i.is_a? Building::Event::AreaAdded
    end.collect(&:area_id)
    removed_ids = history.select do |i|
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
    obj = history.select do |i|
      i.is_a? Area::Event::NameChanged
    end.last
    obj.name if obj
  end

  def building
    @building ||= Building.load(building_id)
  end

  def building_id
    obj = history.select do |i|
      i.is_a? Area::Event::BuildingAssignment
    end.last
    obj.building_id if obj
  end

  def building_name
    building.history.select do |i|
      i.is_a? Building::Event::NameChanged
    end.last.name
  end

  def area_type
    history.select do |i|
      i.is_a? Area::Event::TypeChanged
    end.last.type
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

Sequares.configure do |config|
  config.use_cache = false
end

describe "Intergration Example" do
  let(:address) do
    Address.new(
      line1: "1600 Amphitheatre Parkway",
      line2: nil,
      locality: "San Francisco",
      administrative_area: "CA",
      postal_code: "94043",
      country: "US"
    )
  end

  before :each do
    Timecop.freeze
  end

  after :each do
    Timecop.return
    Sequares.reset
  end

  it "adds name to history" do
    resources = Sequares.with_lock([Building, nil]) do |building|
      building
        .execute(Building::SetName.new(name: "Google HQ"))
        .execute(Building::SetAddress.new(address: address))
    end

    building = resources.first
    expect(building.history.length).to be 2
    expect(building.name).to eql "Google HQ"
    expect(building.address.to_h).to eql address.to_h
    expect(BuildingPresenter.new(building).to_h).to eql(
      address: {
        line1: "1600 Amphitheatre Parkway",
        line2: nil,
        locality: "San Francisco",
        administrative_area: "CA",
        postal_code: "94043",
        country: "US"
      },
      created_at: Time.now.utc,
      name: "Google HQ",
      updated_at: Time.now.utc,
      area_ids: []
    )
  end

  it "adds a room to a building" do
    resources = Sequares.with_lock([Building, nil, Area, nil]) do |building, area|
      building.execute(Building::SetName.new(name: "Google HQ"))
      area.execute(Area::SetType.new(type: "room"))
      area.execute(Area::SetName.new(name: "Conference Room"))
      area.execute(Area::AssignBuilding.new(building_id: building.id))
      building.execute(Building::AddArea.new(area_id: area.id))
    end
    building = resources.first
    area = resources[1]

    expect(AreaPresenter.new(area).to_h).to eql(
      name: "Conference Room",
      type: "room",
      building_name: "Google HQ",
      building_id: building.id
    )

    expect(BuildingPresenter.new(building).to_h).to eql(
      address: {},
      created_at: Time.now.utc,
      name: "Google HQ",
      updated_at: Time.now.utc,
      area_ids: [area.id]
    )
  end
end

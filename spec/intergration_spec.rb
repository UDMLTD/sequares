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
end

class Building < Sequares::Entity
  include BuildingCommands

  module Event
    NameChanged = Sequares::Event.new(:name)
    AddressChanged = Sequares::Event.new(:address)
  end

  def name
    history.select do |i|
      i.is_a? Event::NameChanged
    end.last.name
  end

  def address
    history.select do |i|
      i.is_a? Event::AddressChanged
    end.last.address
  end
end

class BuildingPresenter
  extend Forwardable
  attr_reader :building
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

  def to_h
    {
      name: name,
      created_at: created_at,
      updated_at: updated_at,
      address: address.to_h
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
      updated_at: Time.now.utc
    )
  end
end

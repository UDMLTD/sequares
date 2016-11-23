require "spec_helper"
require_relative "../../examples/building"

describe "Example / Building" do
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
    Sequares.configure do |config|
      config.store = Sequares::Store::Memory.new
    end
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

  xit "finds buildings by event" do
    Sequares.with_lock([User, 1]) do |user|
      user.execute(
        User::Cmd::SetEmail.new(email: "test@example.com")
      )
    end

    events = Sequares.configuration.store.filter_events(::User::Event::EmailChanged)

    expect(events.length).to eql 1
  end

  it "doesnt allow the email to be added again" do
    resources = Sequares.with_lock([User, 1]) do |user|
      user.execute(
        User::Cmd::SetEmail.new(email: "test@example.com")
      )
    end

    expect do
      resources = Sequares.with_lock([User, 2]) do |user|
        user.execute(
          User::Cmd::SetEmail.new(email: "test@example.com")
        )
      end
    end.to raise_error User::Error::EmailNotUnique

    expect do
      resources = Sequares.with_lock([User, 2]) do |user|
        user.execute(
          User::Cmd::SetEmail.new(email: "test123@example.com")
        )
      end
    end.to_not raise_error
  end
end

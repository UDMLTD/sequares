require "spec_helper"

describe Sequares::Configuration do
  context "defaults" do
    describe "#store" do
      it "default store is Redis" do
        expect(subject.repository).to be_a Sequares::Repository
      end
    end

    xdescribe "#event_bus" do
      it "returns the default bus which is Redis" do
        expect(subject.event_bus).to be_a Sequares::EventBus::Redis
      end
    end
  end

  context "settings config" do
    before :each do
      Sequares.configure do |config|
        config.repository = Sequares::Repository.new(::Redis.new)
        config.event_bus = Sequares::EventBus::Memory.new
      end
    end
    after :each do
      Sequares.reset
    end

    it "sets the repository to Memory" do
      expect(Sequares.configuration.repository).to be_a Sequares::Repository
    end

    xit "sets the event_bus to Memory" do
      expect(Sequares.configuration.event_bus).to be_a Sequares::EventBus::Memory
    end
  end
end

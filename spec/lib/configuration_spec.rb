require "spec_helper"

describe Sequares::Configuration do
  context "defaults" do
    describe "#store" do
      it "default store is Redis" do
        expect(subject.store).to be_a Sequares::Store::Redis
      end
    end

    describe "#use_cache" do
      it "returns true" do
        expect(subject.use_cache).to be_truthy
      end
    end

    describe "#event_bus" do
      it "returns the default bus which is Redis" do
        expect(subject.event_bus).to be_a Sequares::EventBus::Redis
      end
    end
  end

  context "settings config" do
    before :each do
      Sequares.configure do |config|
        config.store = Sequares::Store::Memory.new
        config.use_cache = false
        config.event_bus = Sequares::EventBus::Memory.new
      end
    end
    after :each do
      Sequares.reset
    end

    it "sets the store to Memory" do
      expect(Sequares.configuration.store).to be_a Sequares::Store::Memory
    end

    it "sets use_cache to false" do
      expect(Sequares.configuration.use_cache).to be_falsy
    end

    it "sets the event_bus to Memory" do
      expect(Sequares.configuration.event_bus).to be_a Sequares::EventBus::Memory
    end
  end
end

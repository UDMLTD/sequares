require "spec_helper"
require "benchmark"

describe Sequares::Store::WithCallback do
  before :each do
    Sequares.configure do |config|
      config.store = Sequares::Store::Memory.new
      config.store = Sequares::Store::WithCallback.new(config.store)
    end
    EventFoo = Sequares::Event.new(:name)
    module EventNS
      EventFoo = Sequares::Event.new(:name)
    end
    class ::EntityFoo < Sequares::Entity
    end
  end
  after :each do
    Object.send(:remove_const, :EventFoo)
    Object.send(:remove_const, :EntityFoo)
    Object.send(:remove_const, :EventNS)
  end

  let(:event) { EventFoo.new(name: "bar") }
  let(:ns_event) { EventNS::EventFoo.new(name: "bar") }
  let(:entity) { EntityFoo.load("1") }
  subject { described_class.new(Sequares::Store::Memory.new) }

  describe "#save_history_for_aggregate" do
    it "should call callback when saving" do
      callback = double('callback')
      subject.add_callback(callback)
      expect(callback).to receive(:call).with(instance_of(EntityFoo), event)

      entity.history << event
      subject.save_history_for_aggregate(entity)
    end
  end
end

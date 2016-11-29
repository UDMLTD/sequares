require "spec_helper"

describe Sequares::Entity do
  before :each do
    EventFoo = Sequares::Event.new(:name)
    class EntityFoo < described_class
    end
  end
  after :each do
    Object.send(:remove_const, :EventFoo)
    Object.send(:remove_const, :EntityFoo)
  end

  let(:event) { EventFoo.new(name: "Hello World") }

  describe "#apply" do
    it "adds the event to this history" do
      subject.id = 1
      subject.apply(event)
      expect(subject.history.last).to be_a EventFoo
      expect(event.entity_id).to eql 1
      expect(event.entity_klass).to eql described_class.name
    end

    it "calls on_event_foo when applying event" do
      expect(Sequares.configuration.event_bus).to receive(:publish).with(event)
      subject.apply(event)
    end
  end
end

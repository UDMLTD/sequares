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

  describe "#apply" do
    it "adds the event to this history" do
      subject.apply(EventFoo.new(name: 'Hello World'))
      expect(subject.history.last).to be_a EventFoo
    end

    it "calls on_event_foo when applying event" do
      event = EventFoo.new(name: 'Hello World')
      expect(subject).to receive(:on_event_foo).with(event)
      subject.apply(event)
    end
  end
end

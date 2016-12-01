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
    end
  end
end

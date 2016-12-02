require "spec_helper"

xdescribe Sequares::EventBus::Memory do
  before :each do
    EventFoo = Sequares::Event.new(:name)
    class EntityFoo < Sequares::Entity; end
  end

  after :each do
    Object.send(:remove_const, :EventFoo)
    Object.send(:remove_const, :EntityFoo)
  end

  let(:event) { EventFoo.new(name: "hello world") }
  let(:entity) { EntityFoo.new }

  describe "#subscribe" do
    it "subscribes a entity to an event" do
      block_body = lambda do |event|
      end
      expect(subject.subscriptions["event_foo"]).to receive(:<<).with(block_body)
      subject.subscribe("event_foo", &block_body)
    end
  end

  describe "#publish" do
    it "pushes the event onto the event bus" do
      block_body = lambda do |event|
      end
      subject.subscribe("event_foo", &block_body)
      expect(block_body).to receive(:call).with(event)
      subject.publish(event)
    end
  end
end

require "spec_helper"

xdescribe Sequares::EventBus::Redis do
  let(:redis_mock) { double("Redis") }
  subject { described_class.new(redis_mock) }
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
      expect(redis_mock).to receive(:publish).with("events", Marshal.dump(event))
      subject.publish(event)
    end
  end

  describe "#start" do
    it "starts a redis process" do
      sub_event = double("SubscriptionEvent")
      allow(sub_event).to receive(:message) do |&block|
        @message_block = block
      end
      allow(redis_mock).to receive(:subscribe) do |event_key, &block|
        @event_key = event_key
        @block = block
      end
      block_body = lambda do |event|
      end
      subject.subscribe("event_foo", &block_body)
      expect(block_body).to receive(:call).with(event)
      subject.start
      @block.call(sub_event)
      @message_block.call("channel1", event)
    end
  end
end

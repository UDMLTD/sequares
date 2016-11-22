require "spec_helper"

describe Sequares::Store::Memory do
  describe "#histories" do
    it "has histories" do
      expect(subject.histories).to be_empty
    end
  end

  before :each do
    EventFoo = Sequares::Event.new(:name)
    module EventNS
      EventFoo = Sequares::Event.new(:name)
    end
    class EntityFoo < Sequares::Entity
    end
  end
  after :each do
    Object.send(:remove_const, :EventFoo)
    Object.send(:remove_const, :EntityFoo)
    Object.send(:remove_const, :EventNS)
  end

  describe '#filter_events' do
    it "queries the history for given events" do
      ev = EventFoo.new(name: "bar")

      # assign
      ent = double("Entity")
      allow(ent).to receive(:uri).and_return("document/1")
      allow(ent).to receive(:history).and_return([ev])

      subject.save_history_for_aggregate(ent)

      events = subject.filter_events(EventFoo)
      # assert
      expect(events.length).to be 1
      expect(events.first).to eql ev
    end

    it 'queries the history by namespace' do
      ev = EventNS::EventFoo.new(name: 'bar')
      ent = double("Entity")
      allow(ent).to receive(:uri).and_return("document/1")
      allow(ent).to receive(:history).and_return([ev])

      subject.save_history_for_aggregate(ent)

      events = subject.filter_events(EventNS)
      expect(events.length).to be 1
      expect(events.first).to eql ev
    end
  end

  describe ".cache_key_for" do
    it "returns cache key for given entity" do
      key = subject.cache_key_for(EntityFoo, 1)
      expect(key).to eql("entityfoo/1|0")
    end
  end

  describe ".cache_keys_for" do
    it "returns cache keys for given entities" do
      keys = subject.cache_keys_for([EntityFoo, 1, EntityFoo, 2])
      expect(keys).to eql(
        [
          "entityfoo/1|0",
          "entityfoo/2|0"
        ]
      )
    end
  end

  describe ".etag_for" do
    it "returns the etag_for given entity" do
      etag = subject.etag_for(EntityFoo, 1)
      expect(etag).to eql "c3f9e6cc09685704ed255d01626da572"
    end
  end

  describe ".etags_for" do
    it "returns etag strings for given entities" do
      etags = subject.etags_for([EntityFoo, 1, EntityFoo, 2])
      expect(etags).to eql(
        %w(
          c3f9e6cc09685704ed255d01626da572
          cbc99d646e5f53fec80ed04cb7bdef8e
        )
      )
    end
  end

  describe "#save_history_for_aggregate" do
    it "writes to history" do
      ev = EventFoo.new(name: "bar")

      ent = double("Entity")
      allow(ent).to receive(:uri).and_return("document/1")
      allow(ent).to receive(:history).and_return([ev])

      subject.save_history_for_aggregate(ent)

      expect(subject.fetch_history_for_aggregate(ent).last).to be_a EventFoo
      expect(subject.fetch_history_for_aggregate(ent).last).to eql ev
    end
  end

  describe "#lock" do
    it "raises thread error" do
      store = described_class.new
      ent = double("Entity")
      allow(ent).to receive(:uri).and_return("document/1")
      store.lock(ent)
      expect do
        Thread.new do
          store.lock(ent)
        end.join
      end.to raise_error ::Sequares::Entity::AlreadyLocked
    end
  end
end

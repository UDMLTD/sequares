require "spec_helper"

describe Sequares::Store::Redis do
  before :each do
    EventFoo = Sequares::Event.new(:name)
    class EntityFoo < Sequares::Entity
    end
  end
  after :each do
    Object.send(:remove_const, :EventFoo)
    Object.send(:remove_const, :EntityFoo)
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

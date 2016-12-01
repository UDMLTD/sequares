RSpec.shared_examples "store" do
  before :each do
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

  describe "#filter_events" do
    before :each do
      entity.history << event
      entity.history << ns_event
      subject.save_history_for_aggregate(entity)
    end

    it "queries the history for given events" do
      events_pair = subject.filter_events(EventFoo)
      # assert
      expect(events_pair.size).to be 1
      events_pair.each do |ent, ev|
        expect(ent).to be_a EntityFoo
        expect(ev).to eql event
      end
    end

    it "queries the history by namespace" do
      subject.save_history_for_aggregate(entity)

      events_pair = subject.filter_events(EventNS)
      # assert
      expect(events_pair.length).to be 1
      events_pair.each do |ent, ev|
        expect(ent).to be_a EntityFoo
        expect(ev).to eql ns_event
      end
    end
  end

  describe ".cache_key_for" do
    it "returns cache key for given entity" do
      key = subject.cache_key_for(EntityFoo, 1)
      expect(key).to eql("entity_foo|1#0")
    end
  end

  describe ".cache_keys_for" do
    it "returns cache keys for given entities" do
      keys = subject.cache_keys_for([EntityFoo, 1, EntityFoo, 2])
      expect(keys).to eql(
        [
          "entity_foo|1#0",
          "entity_foo|2#0"
        ]
      )
    end
  end

  describe ".etag_for" do
    it "returns the etag_for given entity" do
      etag = subject.etag_for(EntityFoo, 1)
      expect(etag).to eql "23514ed174bd71d0664afc966f238b95"
    end
  end

  describe ".etags_for" do
    it "returns etag strings for given entities" do
      etags = subject.etags_for([EntityFoo, 1, EntityFoo, 2])
      expect(etags).to eql(
        %w(
          23514ed174bd71d0664afc966f238b95
          22498f0cc89e5ba86ead21df9835e8f3
        )
      )
    end
  end

  describe "#save_history_for_aggregate" do
    it "writes to history" do
      entity.history << event
      subject.save_history_for_aggregate(entity)

      expect(subject.fetch_history_for_aggregate(entity).last).to be_a EventFoo
      expect(subject.fetch_history_for_aggregate(entity).last).to eql event
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

  describe "#unsaved_history" do
    it "returns an empty array" do
      expect(subject.unsaved_history(entity)).to be_a Array
    end

    it "returns a range of array events" do
      new_event = EventFoo.new(name: "bar")
      entity.history << event
      expect(subject.unsaved_history(entity)).to include event
      subject.save_history_for_aggregate(entity)
      entity.history << new_event
      expect(subject.unsaved_history(entity)).not_to include event
      expect(subject.unsaved_history(entity)).to include new_event
    end
  end
end

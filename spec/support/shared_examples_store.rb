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
  let(:entity) { Sequares.repository.load(EntityFoo, "1") }

  describe "#filter_events" do
    before :each do
      entity.history << event
      entity.history << ns_event
      subject.save_history_for(entity)
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
      events_pair = subject.filter_events(EventNS)
      # assert
      expect(events_pair.length).to be 1
      events_pair.each do |ent, ev|
        expect(ent).to be_a EntityFoo
        expect(ev).to eql ns_event
      end
    end
  end

  xdescribe ".cache_key_for" do
    it "returns cache key for given entity" do
      key = subject.cache_key_for(EntityFoo, 1)
      expect(key).to eql("entity_foo|1#0")
    end
  end

  xdescribe ".cache_keys_for" do
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

  xdescribe ".etag_for" do
    it "returns the etag_for given entity" do
      etag = subject.etag_for(EntityFoo, 1)
      expect(etag).to eql "23514ed174bd71d0664afc966f238b95"
    end
  end

  xdescribe ".etags_for" do
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

  describe "#save_history_for" do
    it "writes to history" do
      entity.history << event
      subject.save_history_for(entity)

      expect(subject.for_entity(entity).last).to be_a EventFoo
      expect(subject.for_entity(entity).last).to eql event
    end
  end

  describe "#history.length" do
    it "returns the length of the history includeing uncommitted history" do
      new_instance = subject.load(entity.class, entity.id)

      expect(new_instance.history.length).to eql 0
      new_instance.history << event
      expect(new_instance.history.length).to eql 1
    end
  end

  describe "#history.uncommitted" do
    it "has committed and uncommitted history" do
      entity.history << event
      subject.save_history_for(entity)
      new_instance = subject.load(entity.class, entity.id)
      new_instance.history << ns_event

      expect(new_instance.history.length).to eql 2
      expect(new_instance.history).to include event
      expect(new_instance.history).to include ns_event
    end

    it "adds history to store" do
      entity.history << event
      subject.save_history_for(entity)

      new_instance = subject.load(entity.class, entity.id)
      new_instance.history << ns_event
      subject.save_history_for(new_instance)

      assert_instance = subject.load(entity.class, entity.id)

      expect(assert_instance.history.length).to eql 2
      expect(assert_instance.history).to include event
      expect(assert_instance.history).to include ns_event
    end
  end
end

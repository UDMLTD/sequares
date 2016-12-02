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
end

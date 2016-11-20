require "spec_helper"

describe Sequares::Event do
  before :each do
    Timecop.freeze
  end
  after :each do
    Object.send(:remove_const, :Foo)
    Timecop.return
  end

  it "can create simple structs with occurred_at" do
    Foo = described_class.new(:name)
    subject = Foo.new(name: "hello world")
    expect(subject.name).to eql("hello world")
    expect(subject.occurred_at).to eql(Time.now.utc)
  end
end

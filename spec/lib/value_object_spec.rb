require "spec_helper"

describe Sequares::ValueObject do
  before :each do
    Timecop.freeze
  end
  after :each do
    Object.send(:remove_const, :Foo)
    Timecop.return
  end

  it "can create simple structs" do
    Foo = described_class.new(:name)
    subject = Foo.new(name: "hello world")
    expect(subject.name).to eql("hello world")
  end
end

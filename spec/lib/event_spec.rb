require "spec_helper"

describe Sequares::Event do
  before :each do
    Timecop.freeze
    Foo = described_class.new(:name)
  end
  after :each do
    Object.send(:remove_const, :Foo)
    Timecop.return
  end

  subject {Foo.new(name: "hello world")}

  it "can create simple structs with occurred_at" do
    # subject = Foo.new(name: "hello world")
    expect(subject.name).to eql("hello world")
    expect(subject.occurred_at).to eql(Time.now.utc)
  end

  describe "#key" do
    it 'returns the class name as a underscore_key' do
      expect(subject.key).to eql "foo"
    end
  end
end

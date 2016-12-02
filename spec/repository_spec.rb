require "spec_helper"

describe Sequares::Repository do
  describe "Redis Backend" do
    before :each do
      Sequares.configure do |config|
        config.repository = Sequares::Repository.new(Redis.new)
      end
    end
    subject { Sequares.repository }
    it_behaves_like "store"
  end

  describe "Memory Backend" do
    before :each do
      Sequares.configure do |config|
        config.repository = Sequares::Repository.new(Sequares::Backend::Memory.new)
      end
    end
    subject { Sequares.repository }
    it_behaves_like "store"
  end
end

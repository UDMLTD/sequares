require "spec_helper"

describe Sequares::Store::Memory do
  before :each do
    Sequares.configure do |config|
      config.store = Sequares::Store::Memory.new
    end
  end

  it_behaves_like "store"
end

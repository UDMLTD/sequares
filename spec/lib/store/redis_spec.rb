require "spec_helper"

describe Sequares::Store::Redis do
  before :each do
    Sequares.configure do |config|
      config.store = Sequares::Store::Redis.new
    end
  end

  it_behaves_like 'store'
end

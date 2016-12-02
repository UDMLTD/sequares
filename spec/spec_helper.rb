$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "sequares"
require "timecop"
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }
RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.order = "random"

  config.before :each do
    Sequares.configure do |sequares_config|
      sequares_config.repository = Sequares::Repository.new(Sequares::Backend::Memory.new)
    end
  end
  config.after :each do
    Sequares.repository.reset
  end
end

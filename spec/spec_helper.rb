$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "sequares"
require "timecop"
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }
RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.order = "random"

  config.before :each do
    Sequares.configuration.store.reset
  end
end

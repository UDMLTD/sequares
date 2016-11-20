[![Build Status](https://travis-ci.org/kylewelsby/sequares.svg?branch=master)](https://travis-ci.org/kylewelsby/sequares)
# Sequares

Sequares is CQRS as it sounds spoken fast.

Command-Query Responsibility Segregation (CQRS) with Event Sourcing.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sequares'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sequares

## Usage

```
Address = Sequares::ValueObject.new(
  :line1,
  :line2,
  :locality,
  :administrative_area,
  :postal_code,
  :country
)

module BuildingCommands
  class SetName < Sequares::Command.new(:name)
    def to_proc
      lambda do |entity|
        entity.history << Building::Event::NameChanged.new(to_h)
      end
    end
  end

  class SetAddress < Sequares::Command.new(:address)
    def to_proc
      lambda do |ent|
        ent.history << Building::Event::AddressChanged.new(to_h)
      end
    end
  end
end

class Building < Sequares::Entity
  include BuildingCommands

  module Event
    NameChanged = Sequares::Event.new(:name)
    AddressChanged = Sequares::Event.new(:address)
  end

  def name
    history.select do |i|
      i.is_a? Event::NameChanged
    end.last.name
  end

  def address
    history.select do |i|
      i.is_a? Event::AddressChanged
    end.last.address
  end
end

class BuildingPresenter
  extend Forwardable
  attr_reader :building
  def_delegators :@entity, :history, :name, :address

  def initialize(entity)
    @entity = entity
  end

  def created_at
    history.first.occurred_at
  end

  def updated_at
    history.last.occurred_at
  end

  def to_h
    {
      name: name,
      created_at: created_at,
      updated_at: updated_at,
      address: address.to_h
    }
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kylewelsby/sequares. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Special Thanks

- [Lee Hambley](https://github.com/leehambley)
- [Greg Young](https://github.com/gregoryyoung)

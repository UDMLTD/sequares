[![Build Status](https://travis-ci.org/kylewelsby/sequares.svg?branch=master)](https://travis-ci.org/kylewelsby/sequares)
# Sequares

_Warning:  This project is Work In Progress and has not been officially released yet.  The defined specifics may change without notice_

Sequares is CQRS as it sounds spoken fast. _se-qu-ar-es_

Command-Query Responsibility Segregation (CQRS) with Event Sourcing.


## Todo

- event_slice - a processed event e.g. all emails in array,  has to catch up with live. so at event 700 and has to caatchup historeis 800. (maybe its a saga)
- replay history
- projection is a ideal case

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

### Simple Example - Create a Building with an AddressChanged

For more detailed examples see [Integration Spec](https://github.com/kylewelsby/sequares/blob/master/spec/integration_spec.rb)


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

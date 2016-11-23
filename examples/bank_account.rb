# app/commands
module Commands
  module Account
    class Deposit < Sequares::Command.new(:amount)
      def to_proc
        lambda do |entity|
          balance = entity.balance.deposit(amount)
          event = ::Account::Event::Deposited.new(
            amount: amount,
            balance: balance
          )
          entity.apply(event)
        end
      end
    end

    class Withdraw < Sequares::Command.new(:amount)
      def to_proc
        lambda do |entity|
          event = ::Account::Event::Withdrawed.new(to_h)
          entity.apply(event)
        end
      end
    end
  end
end

## app/events
module Events
  module Account
    Deposited = Sequares::Event.new(:amount)
    Withdrawed = Sequares::Event.new(:amount)
  end
end

## app/entities
class Account < Entity
  module Event
    include Events::Account
  end
  module Cmd
    include Commands::Account
  end
end

## app/presenters
class AccountPresenter
  attr_accessor :entity
  def initialize(entity)
    @entity = entity
  end
end

## app/value_objects
class Balance < Sequares::ValueObject.new(:amount)
  def deposit(deposited_amount)
    new(amount + deposited_amount)
  end

  def withdraw(withdrawn_amount)
    new(amount - withdrawn_amount)
  end
end

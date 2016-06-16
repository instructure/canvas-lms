# manually require since ::MessageableUser satisfies
# AddressBook::MessageableUser and prevents the autoload
require_relative 'address_book/messageable_user'

# see AddressBook::Base for primary documentation of the interface
module AddressBook

  def self.registry
    RequestStore.store[:address_books] ||= {}
  end

  # instantiates an address book for the sender. in the near future, will
  # choose the implementation of address book according to the plugin setting
  def self.for(sender)
    registry[sender] ||= AddressBook::MessageableUser.new(sender)
  end

  # partitions the list of recipients into user ids and context asset strings
  def self.partition_recipients(recipients)
    users = ::MessageableUser.individual_recipients(recipients)
    contexts = ::MessageableUser.context_recipients(recipients)
    return users, contexts
  end

  # filters the list of users to only those that are "available" (but not
  # necessarily known to any particular sender)
  def self.available(users)
    Shackles.activate(:slave) do
      ::MessageableUser.available.where(id: users).to_a
    end
  end

  def self.valid_context?(context_code)
    context_code =~ ::MessageableUser::Calculator::CONTEXT_RECIPIENT
  end
end

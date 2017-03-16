# manually require since ::MessageableUser satisfies
# AddressBook::MessageableUser and prevents the autoload
require_relative 'address_book/messageable_user'

# see AddressBook::Base for primary documentation of the interface
module AddressBook
  STRATEGIES = {
    'messageable_user' => { implementation: AddressBook::MessageableUser, label: lambda{ I18n.t('MessageableUser library') } }.freeze,
    'microservice' => { implementation: AddressBook::Service, label: lambda{ I18n.t('AddressBook microservice') } }.freeze,
    'performance_tap' => { implementation: AddressBook::PerformanceTap, label: lambda{ I18n.t('AddressBook performance tap') } }.freeze,
    'empty' => { implementation: AddressBook::Empty, label: lambda{ I18n.t('Empty stub (for testing only)') } }.freeze
  }.freeze
  DEFAULT_STRATEGY = 'messageable_user'

  def self.registry
    RequestStore.store[:address_books] ||= {}
  end

  # choose the implementation of address book according to the plugin setting
  def self.strategy
    strategy = Canvas::Plugin.find('address_book').settings[:strategy]
    unless STRATEGIES.has_key?(strategy)
      # plugin setting specifies an invalid strategy. (TODO: logger.warn or
      # something.) gracefully fall back on default
      strategy = DEFAULT_STRATEGY
    end
    strategy
  end

  def self.implementation
    return STRATEGIES[strategy][:implementation]
  end

  # instantiates an address book for the sender
  def self.for(sender)
    registry[sender] ||= implementation.new(sender)
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

#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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

  def self.decompose_context(context_code)
    context_code &&
    context_code =~ ::MessageableUser::Calculator::CONTEXT_RECIPIENT &&
    Regexp.last_match.to_a[1..-1]
  end

  def self.valid_context?(context_code)
    decompose_context(context_code).present?
  end

  def self.load_context(context_code)
    context_type, context_id = decompose_context(context_code)
    return nil unless context_id
    context_class =
      case context_type
      when 'course' then Course
      when 'section' then CourseSection
      when 'group' then Group
      end
    context_class.find(context_id)
  end
end

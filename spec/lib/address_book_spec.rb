# frozen_string_literal: true

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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe AddressBook do
  describe "for" do
    it "returns an instance of AddressBook::MessageableUser for 'messageable_user' strategy" do
      expect(AddressBook.for(user_model)).to be_a(AddressBook::MessageableUser)
    end

    it "returns an address book for the specified sender" do
      sender = user_model
      address_book = AddressBook.for(sender)
      expect(address_book.sender).to be(sender)
    end

    it "returns the same address book instance for multiple copies of the sender" do
      sender = user_model
      clone = User.find(sender.id)
      address_book1 = AddressBook.for(sender)
      address_book2 = AddressBook.for(clone)
      expect(address_book1.object_id).to be(address_book2.object_id)
    end

    it "resets the address book instance between requests" do
      sender = user_model
      address_book1 = AddressBook.for(sender)
      RequestStore.clear!
      address_book2 = AddressBook.for(sender)
      expect(address_book1.object_id).not_to be(address_book2.object_id)
    end
  end

  describe "partition_recipients" do
    it "splits individuals from contexts" do
      recipients = ['123', 'course_456']
      individuals, contexts = AddressBook.partition_recipients(recipients)
      expect(individuals).to eql([123])
      expect(contexts).to eql(['course_456'])
    end
  end

  describe "available" do
    it "restricts to the supplied users" do
      recipient = user_model # available
      user_model # also available
      available = AddressBook.available([recipient])
      expect(available.map(&:id)).to eql([recipient.id])
    end

    it "restricts to available users" do
      recipient = user_model(workflow_state: 'available') # available
      other = user_model(workflow_state: 'deleted') # unavailable
      available = AddressBook.available([recipient, other])
      expect(available.map(&:id)).to eql([recipient.id])
    end
  end
end

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

describe AddressBook::Empty do
  before do
    @address_book = AddressBook::Empty.new(user_model)
  end

  describe "known_users" do
    it "returns an empty array" do
      other_user = user_model
      expect(@address_book.known_users([other_user])).to eql([])
    end
  end

  describe "known_user" do
    it "returns nil" do
      other_user = user_model
      expect(@address_book.known_user(other_user)).to be_nil
    end
  end

  describe "common_courses" do
    it "returns an empty hash" do
      other_user = user_model
      expect(@address_book.common_courses(other_user)).to eql({})
    end
  end

  describe "common_groups" do
    it "returns an empty hash" do
      other_user = user_model
      expect(@address_book.common_groups(other_user)).to eql({})
    end
  end

  describe "known_in_context" do
    it "returns an empty array" do
      course = course_factory(active_all: true)
      expect(@address_book.known_in_context(course.asset_string)).to eql([])
    end
  end

  describe "count_in_contexts" do
    it "returns empty hash" do
      course = course_factory(active_all: true)
      expect(@address_book.count_in_contexts([course.asset_string])).to eql({})
    end
  end

  describe "search_users" do
    it "returns an empty but paginatable collection" do
      known_users = @address_book.search_users(search: "Bob")
      expect(known_users).to respond_to(:paginate)
      expect(known_users.paginate(per_page: 1).size).to be(0)
    end
  end

  describe "sections" do
    it "returns an empty array" do
      expect(@address_book.sections).to eql([])
    end
  end

  describe "groups" do
    it "returns an empty array" do
      expect(@address_book.groups).to eql([])
    end
  end
end

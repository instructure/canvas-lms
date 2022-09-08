# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
#

describe Lti::ContextToolFinder do
  before(:once) do
    @root_account = Account.default
    @account = account_model(root_account: @root_account, parent_account: @root_account)
    course_model(account: @account)
  end

  describe "all_tools_for" do
    it "returns a scope" do
      expect(Lti::ContextToolFinder.all_tools_for(@course)).to be_a(ActiveRecord::Relation)
    end

    it "retrieves all tools in alphabetical order" do
      @tools = []
      @tools << @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tools << @root_account.context_external_tools.create!(name: "e", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @tools << @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tools << @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @tools << @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tools << @account.context_external_tools.create!(name: "c", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      expect(Lti::ContextToolFinder.all_tools_for(@course).to_a).to eql(@tools.sort_by(&:name))
    end

    it "returns all tools that are selectable" do
      @tools = []
      @tools << @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tools << @root_account.context_external_tools.create!(name: "e", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret", not_selectable: true)
      @tools << @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tools << @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret", not_selectable: true)
      tools = Lti::ContextToolFinder.all_tools_for(@course, selectable: true)
      expect(tools.count).to eq 2
    end

    it "returns multiple requested placements" do
      tool1 = @course.context_external_tools.create!(name: "First Tool", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
      tool2 = @course.context_external_tools.new(name: "Another Tool", consumer_key: "key", shared_secret: "secret")
      tool2.settings[:editor_button] = { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 }.with_indifferent_access
      tool2.save!
      tool3 = @course.context_external_tools.new(name: "Third Tool", consumer_key: "key", shared_secret: "secret")
      tool3.settings[:resource_selection] = { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 }.with_indifferent_access
      tool3.save!
      placements = Lti::ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS + ["resource_selection"]
      expect(Lti::ContextToolFinder.all_tools_for(@course, placements: placements).to_a).to eql([tool1, tool3].sort_by(&:name))
    end

    it "honors only_visible option" do
      course_with_student(active_all: true, user: user_with_pseudonym, account: @account)
      @tools = []
      @tools << @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tools << @course.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret",
                                                       settings: { assignment_view: { visibility: "admins" } })
      @tools << @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret",
                                                       settings: { assignment_view: { visibility: "members" } })
      tools = Lti::ContextToolFinder.all_tools_for(@course)
      expect(tools.count).to eq 3
      tools = Lti::ContextToolFinder.all_tools_for(@course, only_visible: true, current_user: @user, visibility_placements: ["assignment_view"])
      expect(tools.count).to eq 1
      expect(tools[0].name).to eq "a"
    end
  end
end

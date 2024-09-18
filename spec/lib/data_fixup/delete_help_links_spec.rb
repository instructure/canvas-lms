# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe DataFixup::DeleteHelpLinks do
  let(:existing_help_links) do
    [
      {
        text: "Help Link 1",
        id: :help_link_1,
        url: "http://example.com/help_link_1",
        available_to: ["student"]
      },
      {
        text: "Covid Help Link",
        id: :covid,
        url: "http://example.com/covid",
        available_to: ["student"]
      },
      {
        text: "Help Link 2",
        id: :help_link_2,
        url: "http://example.com/help_link_2",
        available_to: ["student"]
      }
    ].freeze
  end

  let(:edited_help_links) do
    [
      {
        text: "Help Link 1",
        id: :help_link_1,
        url: "http://example.com/help_link_1",
        available_to: ["student"]
      },
      {
        text: "Help Link 2",
        id: :help_link_2,
        url: "http://example.com/help_link_2",
        available_to: ["student"]
      }
    ].freeze
  end

  before(:once) do
    @account = Account.create!(root_account_id: nil)
  end

  describe "when the account has no custom help links" do
    before do
      @account.settings[:custom_help_links] = nil
      @account.save!
    end

    it "does nothing" do
      DataFixup::DeleteHelpLinks.run("covid")
      links = @account.reload.settings[:custom_help_links]
      expect(links).to be_nil
    end
  end

  describe "when the account does not have the specified help link" do
    before do
      @account.settings[:custom_help_links] = existing_help_links
      @account.save!
    end

    it "does nothing" do
      DataFixup::DeleteHelpLinks.run("non_existent")
      links = @account.reload.settings[:custom_help_links]
      expect(links).to match_array(existing_help_links)
    end
  end

  describe "when the account does have the specified link" do
    before do
      @account.settings[:custom_help_links] = existing_help_links
      @account.save!
    end

    it "removes the specified link" do
      DataFixup::DeleteHelpLinks.run("covid")
      links = @account.reload.settings[:custom_help_links]
      expect(links).to match_array(edited_help_links)
    end
  end
end

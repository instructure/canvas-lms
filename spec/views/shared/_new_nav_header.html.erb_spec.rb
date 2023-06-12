# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../views_helper"

describe "shared/_new_nav_header" do
  before do
    assign(:domain_root_account, Account.default)
  end

  context "'Courses' menu" do
    it "renders courses with logged in user" do
      assign(:current_user, user_factory)
      render "shared/_new_nav_header"
      doc = Nokogiri::HTML5(response.body)

      expect(doc.at_css("#global_nav_courses_link")).not_to be_nil
    end

    it "does not render courses when not logged in" do
      render "shared/_new_nav_header"
      doc = Nokogiri::HTML5(response.body)

      expect(doc.at_css("#global_nav_courses_link")).to be_nil
    end
  end

  context "'Admin' menu" do
    it "renders admin accounts link if the user is an admin" do
      assign(:current_user, account_admin_user)
      render "shared/_new_nav_header"
      doc = Nokogiri::HTML5(response.body)

      expect(doc.at_css("#global_nav_accounts_link")).not_to be_nil
    end

    it "does not render admin accounts link if the user is not an admin" do
      assign(:current_user, user_factory)
      render "shared/_new_nav_header"
      doc = Nokogiri::HTML5(response.body)

      expect(doc.at_css("#global_nav_accounts_link")).to be_nil
    end

    context "cross-shard" do
      specs_require_sharding

      it "renders admin accounts link if the user is a cross-shard admin" do
        user = user_factory
        @shard1.activate do
          account = Account.create!
          account.account_users.create!(user:)
        end
        assign(:current_user, user)
        render "shared/_new_nav_header"
        doc = Nokogiri::HTML5(response.body)

        expect(doc.at_css("#global_nav_accounts_link")).not_to be_nil
      end
    end
  end
end

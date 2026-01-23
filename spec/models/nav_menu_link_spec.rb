# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "../lib/validates_as_url"

describe NavMenuLink do
  before :once do
    @account = Account.default
    @course = course_factory
  end

  def make_nav_menu_link(context, nav_type)
    NavMenuLink.new(context:, nav_type:, label: "Foo", url: "https://example.com")
  end

  include_context "url validation tests"
  it "checks url validity" do
    cl = make_nav_menu_link(@account, "account")
    cl.save!
    test_url_validation(cl, nullable: false)
  end

  describe "nav_type_matches_context validation" do
    it "accepts NavMenuLinks with matching nav_type and context" do
      expect(make_nav_menu_link(@account, "account").valid?).to be true
      expect(make_nav_menu_link(@account, "user").valid?).to be true
      expect(make_nav_menu_link(@course, "course").valid?).to be true
    end

    it "rejects NavMenuLinks with non-matching nav_type and context" do
      expect(make_nav_menu_link(@account, "course").valid?).to be false
      expect(make_nav_menu_link(@course, "account").valid?).to be false
      expect(make_nav_menu_link(@course, "user").valid?).to be false
    end
  end
end

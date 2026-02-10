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

  def make_nav_menu_link(context, course_nav: false, account_nav: false, user_nav: false)
    NavMenuLink.new(
      context:,
      course_nav:,
      account_nav:,
      user_nav:,
      label: "Foo",
      url: "https://example.com"
    )
  end

  include_context "url validation tests"
  it "checks url validity" do
    cl = make_nav_menu_link(@account, account_nav: true)
    cl.save!
    test_url_validation(cl, nullable: false)
  end

  describe "nav type validations" do
    describe "at_least_one_nav_type_enabled" do
      it "accepts NavMenuLinks with at least one nav type enabled" do
        expect(make_nav_menu_link(@account, account_nav: true).valid?).to be true
        expect(make_nav_menu_link(@account, user_nav: true).valid?).to be true
        expect(make_nav_menu_link(@account, account_nav: true, user_nav: true).valid?).to be true
        expect(make_nav_menu_link(@course, course_nav: true).valid?).to be true
      end

      it "rejects NavMenuLinks with no nav types enabled" do
        link = make_nav_menu_link(@account)
        expect(link.valid?).to be false
        expect(link.errors[:base]).to include("at least one nav type must be enabled")
      end
    end

    describe "nav_types_match_context" do
      context "with course context" do
        it "accepts NavMenuLinks with only course_nav enabled" do
          expect(make_nav_menu_link(@course, course_nav: true).valid?).to be true
        end

        it "rejects NavMenuLinks with account_nav enabled" do
          link = make_nav_menu_link(@course, course_nav: true, account_nav: true)
          expect(link.valid?).to be false
          expect(link.errors[:base]).to include("course-context link can only have course navigation enabled")
        end

        it "rejects NavMenuLinks with user_nav enabled" do
          link = make_nav_menu_link(@course, course_nav: true, user_nav: true)
          expect(link.valid?).to be false
          expect(link.errors[:base]).to include("course-context link can only have course navigation enabled")
        end

        it "rejects NavMenuLinks without course_nav enabled" do
          link = make_nav_menu_link(@course, account_nav: true)
          expect(link.valid?).to be false
          expect(link.errors[:base]).to include("course-context link can only have course navigation enabled")
        end
      end

      context "with account context" do
        it "accepts NavMenuLinks with account_nav enabled" do
          expect(make_nav_menu_link(@account, account_nav: true).valid?).to be true
        end

        it "accepts NavMenuLinks with user_nav enabled" do
          expect(make_nav_menu_link(@account, user_nav: true).valid?).to be true
        end

        it "accepts NavMenuLinks with both account_nav and user_nav enabled" do
          expect(make_nav_menu_link(@account, account_nav: true, user_nav: true).valid?).to be true
        end

        it "accepts NavMenuLinks with course_nav enabled" do
          expect(make_nav_menu_link(@account, course_nav: true, account_nav: true).valid?).to be true
        end

        it "accepts NavMenuLinks with only course_nav enabled" do
          expect(make_nav_menu_link(@account, course_nav: true).valid?).to be true
        end
      end
    end
  end
end

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
  before do
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

  describe ".as_existing_link_objects" do
    before do
      @link1 = NavMenuLink.create!(context: @account, label: "Link One", url: "https://example.com/1", course_nav: true)
      @link2 = NavMenuLink.create!(context: @account, label: "Link Two", url: "https://example.com/2", course_nav: true)
      @link3 = NavMenuLink.create!(context: @account, label: "Link Three", url: "https://example.com/3", course_nav: true, workflow_state: :deleted)
    end

    it "returns an array of link objects with type, id, and label" do
      result = NavMenuLink.active.where(context: @account).order(:id).as_existing_link_objects
      expect(result).to eq([
                             { type: "existing", id: @link1.id, label: "Link One" },
                             { type: "existing", id: @link2.id, label: "Link Two" },
                           ])
    end
  end

  describe ".sync_with_link_objects_json" do
    it "parses valid JSON, calls sync_with_link_objects, and returns true on success" do
      json_data = '[{"type":"new","url":"https://example.com","label":"New Link"}]'
      expect(NavMenuLink).to receive(:sync_with_link_objects).with(context: @account, link_objects: JSON.parse(json_data))
      result = NavMenuLink.sync_with_link_objects_json(context: @account, link_objects_json: json_data)
      expect(result).to be true
    end

    it "logs error and returns false on invalid JSON" do
      invalid_json = "not valid json"
      expect(Rails.logger).to receive(:error).with(/Failed to parse link_objects_json/)
      result = NavMenuLink.sync_with_link_objects_json(context: @account, link_objects_json: invalid_json)
      expect(result).to be false
    end
  end

  describe ".sync_with_link_objects" do
    before do
      @link1 = NavMenuLink.create!(context: @account, label: "Existing Link 1", url: "https://example.com/1", course_nav: true)
      @link2 = NavMenuLink.create!(context: @account, label: "Existing Link 2", url: "https://example.com/2", course_nav: true)
    end

    it "handles both creating new links and removing old links" do
      link_objects = [
        { type: "existing", id: @link1.id.to_s, label: "Existing Link 1" },
        { type: "new", url: "https://example.com/new1", label: "New Link 1" },
        { type: "new", url: "https://example.com/new2", label: "New Link 2" }
      ]

      expect do
        NavMenuLink.sync_with_link_objects(context: @account, link_objects:)
      end.to change { NavMenuLink.active.where(context: @account).count }.by(1)

      expect(NavMenuLink.active.where(id: @link1.id).exists?).to be true
      expect(NavMenuLink.active.where(id: @link2.id).exists?).to be false
      expect(NavMenuLink.active.where(context: @account, label: "New Link 1").exists?).to be true
      expect(NavMenuLink.active.where(context: @account, label: "New Link 2").exists?).to be true
    end

    it "handles string and symbol keys in link objects" do
      link_objects = [
        { "type" => "new", "url" => "https://example.com/new", "label" => "New Link" }
      ]

      expect do
        NavMenuLink.sync_with_link_objects(context: @account, link_objects:)
      end.to change { NavMenuLink.active.where(context: @account).count }.by(-1)

      new_link = NavMenuLink.active.where(context: @account).order(:id).last
      expect(new_link.label).to eq("New Link")
    end

    it "only affects links for the specified context" do
      other_account = Account.create!
      other_link = NavMenuLink.create!(context: other_account, label: "Other Account Link", url: "https://example.com/other", course_nav: true)

      link_objects = [
        { type: "existing", id: @link1.id.to_s, label: "Existing Link 1" }
      ]

      NavMenuLink.sync_with_link_objects(context: @account, link_objects:)

      expect(NavMenuLink.active.where(id: other_link.id).exists?).to be true
    end
  end
end

# frozen_string_literal: true

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

require_relative "../spec_helper"

describe NavMenuLinkTabs do
  before :once do
    course_with_teacher(active_all: true)
    account_model
  end

  describe ".sync_course_links_with_tabs" do
    subject do
      @link1 = NavMenuLink.create!(context: @course, course_nav: true, label: "Link 1", url: "https://example1.com")
      @link2 = NavMenuLink.create!(context: @course, course_nav: true, label: "Link 2", url: "https://example2.com")

      @link_wrong_context = NavMenuLink.create!(context: @account, account_nav: true, label: "Wrong", url: "https://wrong.example.com")
      @link_deleted = NavMenuLink.create!(context: @course, course_nav: true, label: "Link 2", url: "https://example2.com", workflow_state: :deleted)

      tabs = [
        { "id" => "assignments" },
        { "href" => "nav_menu_link_url", "args" => ["https://new1.com"], "label" => "New 1" },
        { "id" => "nav_menu_link_#{@link1.id}", "label" => "Keep", "hidden" => true },
        { "href" => "nav_menu_link_url", "args" => ["https://new2.com"], "label" => "New 2", "hidden" => true },
        { "id" => "nav_menu_link_#{@link_wrong_context.id}" },
        { "id" => "nav_menu_link_#{@link_deleted.id}" },
      ]

      NavMenuLinkTabs.sync_course_links_with_tabs(course: @course, tabs:)
    end

    it "preserves existing links and passes through non-link" do
      expect(subject[0]).to eq({ "id" => "assignments" })
      expect(subject[2]).to eq({ "id" => "nav_menu_link_#{@link1.id}", "label" => "Keep", "hidden" => true })
    end

    it "creates and delete links" do
      subject

      links = NavMenuLink.active.where(context: @course, course_nav: true).to_a
      expect(links.map(&:id)).to include(@link1.id)
      expect(links.map(&:id)).not_to include(@link2.id)
      expect(links.map(&:label)).to include("New 1", "New 2")

      new1 = links.find { |link| link.label == "New 1" }
      new2 = links.find { |link| link.label == "New 2" }

      expect(subject[1]).to eq({ "id" => "nav_menu_link_#{new1.id}" })
      expect(subject[3]).to eq({ "id" => "nav_menu_link_#{new2.id}", "hidden" => true })

      expect(new1.url).to eq("https://new1.com")
      expect(new2.url).to eq("https://new2.com")
    end

    it "filters irrelevant links" do
      expect(subject.length).to eq(4)
    end
  end

  describe ".course_tabs" do
    it "returns tabs for course navigation links" do
      link1 = NavMenuLink.create!(context: @course, course_nav: true, label: "Course Link 1", url: "https://course1.com")
      link2 = NavMenuLink.create!(context: @course, course_nav: true, label: "Course Link 2", url: "https://course2.com")

      # Should not be included
      NavMenuLink.create!(context: @account, account_nav: true, label: "Account Link", url: "https://account.com")
      NavMenuLink.create!(context: @account, user_nav: true, label: "Other User Link", url: "https://other.com")

      tabs = NavMenuLinkTabs.course_tabs(@course)

      expect(tabs.length).to eq(2)
      expect(tabs[0]).to include(
        id: "nav_menu_link_#{link1.id}",
        label: "Course Link 1",
        href: :nav_menu_link_url,
        args: ["https://course1.com"],
        external: true,
        css_class: "nav_menu_link_#{link1.id}",
        target: "_blank"
      )
      expect(tabs[1]).to include(
        id: "nav_menu_link_#{link2.id}",
        label: "Course Link 2",
        href: :nav_menu_link_url,
        args: ["https://course2.com"],
        external: true,
        css_class: "nav_menu_link_#{link2.id}",
        target: "_blank"
      )
    end
  end

  describe ".nav_menu_link_tab_id?" do
    it "returns true for nav menu link tab ids" do
      expect(NavMenuLinkTabs.nav_menu_link_tab_id?("nav_menu_link_123")).to be true
      expect(NavMenuLinkTabs.nav_menu_link_tab_id?("nav_menu_link_456")).to be true
    end

    it "returns false for other tab ids" do
      expect(NavMenuLinkTabs.nav_menu_link_tab_id?("assignments")).to be false
      expect(NavMenuLinkTabs.nav_menu_link_tab_id?("context_external_tool_123")).to be false
      expect(NavMenuLinkTabs.nav_menu_link_tab_id?(nil)).to be false
      expect(NavMenuLinkTabs.nav_menu_link_tab_id?(123)).to be false
    end
  end
end

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

describe NavMenuLinkTabs do
  before :once do
    account_model
    course_with_teacher(active_all: true, account: @account)
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

      NavMenuLinkTabs.sync_course_links_with_tabs(course: @course, tabs:, can_manage_links: true)
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

    context "with account-level links" do
      before do
        @account_link = NavMenuLink.create!(context: @account, course_nav: true, label: "Account Link", url: "https://account.com")
        @course_link = NavMenuLink.create!(context: @course, course_nav: true, label: "Course Link", url: "https://course.com")
      end

      it "preserves account-level links in tab list" do
        tabs = [
          { "id" => "assignments" },
          { "id" => "nav_menu_link_#{@account_link.id}" }
        ]

        result = NavMenuLinkTabs.sync_course_links_with_tabs(course: @course, tabs:, can_manage_links: true)

        expect(result.length).to eq(2)
        expect(result[1]).to eq({ "id" => "nav_menu_link_#{@account_link.id}" })

        # Course link should be deleted since it's not in tabs
        expect(NavMenuLink.active.where(id: @course_link.id).exists?).to be false

        # Account link should remain untouched
        expect(NavMenuLink.active.where(id: @account_link.id).exists?).to be true
      end

      it "allows reordering with account-level links" do
        course_link = NavMenuLink.create!(context: @course, course_nav: true, label: "Course Link", url: "https://course.com")

        tabs = [
          { "id" => "assignments" },
          { "id" => "nav_menu_link_#{@account_link.id}" },
          { "id" => "nav_menu_link_#{course_link.id}" },
          { "id" => "people" }
        ]

        result = NavMenuLinkTabs.sync_course_links_with_tabs(course: @course, tabs:, can_manage_links: true)

        expect(result.length).to eq(4)
        expect(result[0]["id"]).to eq("assignments")
        expect(result[1]["id"]).to eq("nav_menu_link_#{@account_link.id}")
        expect(result[2]["id"]).to eq("nav_menu_link_#{course_link.id}")
        expect(result[3]["id"]).to eq("people")
      end

      it "rejects invalid and wrong-account links from different account chains" do
        other_account = account_model
        other_link = NavMenuLink.create!(context: other_account, course_nav: true, label: "Other Account Link", url: "https://other.com")

        tabs = [
          { "id" => "assignments" },
          { "id" => "nav_menu_link_#{other_link.id}" },
          { "id" => "nav_menu_link_#{NavMenuLink.last.id + 1}" } # Non-existent link
        ]

        result = NavMenuLinkTabs.sync_course_links_with_tabs(course: @course, tabs:, can_manage_links: true)

        # Should filter out the other account's link
        expect(result.length).to eq(1)
        expect(result[0]["id"]).to eq("assignments")
      end
    end

    context "with can_manage_links: false" do
      it "skips creating new links" do
        @link1 = NavMenuLink.create!(context: @course, course_nav: true, label: "Existing Link", url: "https://existing.com")

        tabs = [
          { "id" => "assignments" },
          { "id" => "nav_menu_link_#{@link1.id}" },
          { "href" => "nav_menu_link_url", "args" => ["https://new.com"], "label" => "New Link" },
        ]

        result = NavMenuLinkTabs.sync_course_links_with_tabs(course: @course, tabs:, can_manage_links: false)

        # Should preserve existing link
        expect(result[1]).to eq({ "id" => "nav_menu_link_#{@link1.id}" })

        # Should not create new link
        expect(result.length).to eq(2) # assignments + existing link (new link skipped)

        links = NavMenuLink.active.where(context: @course).to_a
        expect(links.length).to eq(1)
        expect(links[0].id).to eq(@link1.id)
      end

      it "skips deleting existing links" do
        @link1 = NavMenuLink.create!(context: @course, course_nav: true, label: "Keep Link", url: "https://keep.com")
        @link2 = NavMenuLink.create!(context: @course, course_nav: true, label: "Also Keep", url: "https://alsokeep.com")

        tabs = [
          { "id" => "assignments" },
          { "id" => "nav_menu_link_#{@link1.id}" },
          # link2 is not in tabs, but should not be deleted when can_manage_links: false
        ]

        NavMenuLinkTabs.sync_course_links_with_tabs(course: @course, tabs:, can_manage_links: false)

        # Both links should still exist
        links = NavMenuLink.active.where(context: @course).to_a
        expect(links.map(&:id)).to contain_exactly(@link1.id, @link2.id)
      end

      it "still allows rearranging existing links" do
        @link1 = NavMenuLink.create!(context: @course, course_nav: true, label: "Link 1", url: "https://link1.com")
        @link2 = NavMenuLink.create!(context: @course, course_nav: true, label: "Link 2", url: "https://link2.com")

        tabs = [
          { "id" => "assignments" },
          { "id" => "nav_menu_link_#{@link2.id}" }, # link2 first
          { "id" => "nav_menu_link_#{@link1.id}" }, # link1 second
          { "id" => "people" }
        ]

        result = NavMenuLinkTabs.sync_course_links_with_tabs(course: @course, tabs:, can_manage_links: false)

        expect(result[1]["id"]).to eq("nav_menu_link_#{@link2.id}")
        expect(result[2]["id"]).to eq("nav_menu_link_#{@link1.id}")

        # Both links should still exist
        links = NavMenuLink.active.where(context: @course).to_a
        expect(links.length).to eq(2)
      end
    end

    context "with request_host and request_port" do
      it "strips matching host from new link URLs" do
        tabs = [
          { "id" => "assignments" },
          { "href" => "nav_menu_link_url", "args" => ["https://canvas.instructure.com/courses/123"], "label" => "Course Link" }
        ]

        NavMenuLinkTabs.sync_course_links_with_tabs(
          course: @course,
          tabs:,
          can_manage_links: true,
          request_host: "canvas.instructure.com",
          request_port: 443
        )

        new_link = NavMenuLink.active.where(context: @course, course_nav: true).last
        expect(new_link.url).to eq("/courses/123")
        expect(new_link.label).to eq("Course Link")
      end

      it "preserves external URLs when host does not match" do
        tabs = [
          { "id" => "assignments" },
          { "href" => "nav_menu_link_url", "args" => ["https://external-site.com/page"], "label" => "External Link" }
        ]

        NavMenuLinkTabs.sync_course_links_with_tabs(
          course: @course,
          tabs:,
          can_manage_links: true,
          request_host: "canvas.instructure.com",
          request_port: 443
        )

        new_link = NavMenuLink.active.where(context: @course, course_nav: true).last
        expect(new_link.url).to eq("https://external-site.com/page")
      end

      it "handles relative URLs without stripping" do
        tabs = [
          { "id" => "assignments" },
          { "href" => "nav_menu_link_url", "args" => ["/courses/123/pages/home"], "label" => "Relative Link" }
        ]

        NavMenuLinkTabs.sync_course_links_with_tabs(
          course: @course,
          tabs:,
          can_manage_links: true,
          request_host: "canvas.instructure.com",
          request_port: 443
        )

        new_link = NavMenuLink.active.where(context: @course, course_nav: true).last
        expect(new_link.url).to eq("/courses/123/pages/home")
      end

      it "works without request_host and request_port" do
        tabs = [
          { "id" => "assignments" },
          { "href" => "nav_menu_link_url", "args" => ["https://example.com/page"], "label" => "Link" }
        ]

        NavMenuLinkTabs.sync_course_links_with_tabs(
          course: @course,
          tabs:,
          can_manage_links: true
        )

        new_link = NavMenuLink.active.where(context: @course, course_nav: true).last
        expect(new_link.url).to eq("https://example.com/page")
      end

      it "preserves query strings when stripping host" do
        tabs = [
          { "id" => "assignments" },
          { "href" => "nav_menu_link_url", "args" => ["https://canvas.instructure.com/files/123?wrap=1"], "label" => "File Link" }
        ]

        NavMenuLinkTabs.sync_course_links_with_tabs(
          course: @course,
          tabs:,
          can_manage_links: true,
          request_host: "canvas.instructure.com",
          request_port: 443
        )

        new_link = NavMenuLink.active.where(context: @course, course_nav: true).last
        expect(new_link.url).to eq("/files/123?wrap=1")
      end

      it "preserves fragments when stripping host" do
        tabs = [
          { "id" => "assignments" },
          { "href" => "nav_menu_link_url", "args" => ["https://canvas.instructure.com/courses/123#section-2"], "label" => "Anchored Link" }
        ]

        NavMenuLinkTabs.sync_course_links_with_tabs(
          course: @course,
          tabs:,
          can_manage_links: true,
          request_host: "canvas.instructure.com",
          request_port: 443
        )

        new_link = NavMenuLink.active.where(context: @course, course_nav: true).last
        expect(new_link.url).to eq("/courses/123#section-2")
      end

      it "normalizes '//' returned by strip_host for URLs with a double slash after the host" do
        # https://canvas.instructure.com//double-slash strips to //double-slash;
        # the gsub collapses it to /double-slash so it isn't treated as protocol-relative
        tabs = [
          { "id" => "assignments" },
          { "href" => "nav_menu_link_url", "args" => ["https://canvas.instructure.com//double-slash"], "label" => "Double Slash Link" }
        ]

        NavMenuLinkTabs.sync_course_links_with_tabs(
          course: @course,
          tabs:,
          can_manage_links: true,
          request_host: "canvas.instructure.com",
          request_port: 443
        )

        new_link = NavMenuLink.active.where(context: @course, course_nav: true).last
        expect(new_link.url).to eq("/double-slash")
      end
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
        target: "_blank",
        link_context_type: "course"
      )
      expect(tabs[1]).to include(
        id: "nav_menu_link_#{link2.id}",
        label: "Course Link 2",
        href: :nav_menu_link_url,
        args: ["https://course2.com"],
        external: true,
        css_class: "nav_menu_link_#{link2.id}",
        target: "_blank",
        link_context_type: "course"
      )
    end

    it "returns both course-level and account-level links" do
      NavMenuLink.create!(context: @course, course_nav: true, label: "Course Link", url: "https://course.com")
      NavMenuLink.create!(context: @account, course_nav: true, label: "Account Link", url: "https://account.com")

      tabs = NavMenuLinkTabs.course_tabs(@course)

      expect(tabs.length).to eq(2)
      expect(tabs[0][:link_context_type]).to eq("course")
      expect(tabs[1][:link_context_type]).to eq("account")
    end

    def make_link(context, label)
      NavMenuLink.create!(context:, course_nav: true, label:, url: "https://#{label}.com")
    end

    it "returns links for whole account chain, ordered by account then id" do
      # Create a new parent account and child account to avoid conflicts
      parent_account = Account.create!(name: "Parent Account")
      child_account = Account.create!(name: "Child Account", parent_account:)

      # Create course in the child account
      course = Course.create!(name: "Test Course", account: child_account)

      make_link(parent_account, "parent1")
      make_link(child_account, "child1")
      make_link(parent_account, "parent2")
      make_link(child_account, "child2")

      tabs = NavMenuLinkTabs.course_tabs(course)

      expect(tabs.pluck(:label)).to eq %w[parent1 parent2 child1 child2]
      expect(tabs.pluck(:link_context_type).uniq).to eq ["account"]
    end
  end

  describe ".account_tabs" do
    it "returns tabs for account navigation links" do
      link1 = NavMenuLink.create!(context: @account, account_nav: true, label: "Account Link 1", url: "https://account1.com")
      link2 = NavMenuLink.create!(context: @account, account_nav: true, label: "Account Link 2", url: "https://account2.com")

      # Should not be included
      NavMenuLink.create!(context: @account, course_nav: true, label: "Course Link", url: "https://course.com")
      NavMenuLink.create!(context: @account, user_nav: true, label: "User Link", url: "https://user.com")

      tabs = NavMenuLinkTabs.account_tabs(@account)

      expect(tabs.length).to eq(2)
      expect(tabs[0]).to include(
        id: "nav_menu_link_#{link1.id}",
        label: "Account Link 1",
        href: :nav_menu_link_url,
        external: true,
        target: "_blank",
        link_context_type: "account"
      )
      expect(tabs[1]).to include(id: "nav_menu_link_#{link2.id}", label: "Account Link 2")
    end

    it "returns account nav links from the account chain" do
      parent_account = Account.create!(name: "Parent Account")
      child_account = Account.create!(name: "Child Account", parent_account:)

      NavMenuLink.create!(context: parent_account, account_nav: true, label: "Parent Link", url: "https://parent.com")
      NavMenuLink.create!(context: child_account, account_nav: true, label: "Child Link", url: "https://child.com")

      tabs = NavMenuLinkTabs.account_tabs(child_account)

      expect(tabs.pluck(:label)).to include("Parent Link", "Child Link")
    end

    it "does not include account nav links from unrelated accounts" do
      other_account = Account.create!(name: "Unrelated Account")
      NavMenuLink.create!(context: other_account, account_nav: true, label: "Other Link", url: "https://other.com")

      tabs = NavMenuLinkTabs.account_tabs(@account)

      expect(tabs.pluck(:label)).not_to include("Other Link")
    end
  end

  describe ".user_tabs" do
    it "returns tabs for user navigation links" do
      link1 = NavMenuLink.create!(context: @account, user_nav: true, label: "User Link 1", url: "https://user1.com")
      link2 = NavMenuLink.create!(context: @account, user_nav: true, label: "User Link 2", url: "https://user2.com")

      # Should not be included
      NavMenuLink.create!(context: @account, course_nav: true, label: "Course Link", url: "https://course.com")
      NavMenuLink.create!(context: @account, account_nav: true, label: "Account Link", url: "https://account.com")

      tabs = NavMenuLinkTabs.user_tabs(@account)

      expect(tabs.length).to eq(2)
      expect(tabs[0]).to include(
        id: "nav_menu_link_#{link1.id}",
        label: "User Link 1",
        href: :nav_menu_link_url,
        external: true,
        target: "_blank",
        link_context_type: "account"
      )
      expect(tabs[1]).to include(id: "nav_menu_link_#{link2.id}", label: "User Link 2")
    end

    it "returns user nav links from the account chain" do
      parent_account = Account.create!(name: "Parent Account")
      child_account = Account.create!(name: "Child Account", parent_account:)

      NavMenuLink.create!(context: parent_account, user_nav: true, label: "Parent Link", url: "https://parent.com")
      NavMenuLink.create!(context: child_account, user_nav: true, label: "Child Link", url: "https://child.com")

      tabs = NavMenuLinkTabs.user_tabs(child_account)

      expect(tabs.pluck(:label)).to include("Parent Link", "Child Link")
    end

    it "does not include user nav links from unrelated accounts" do
      other_account = Account.create!(name: "Unrelated Account")
      NavMenuLink.create!(context: other_account, user_nav: true, label: "Other Link", url: "https://other.com")

      tabs = NavMenuLinkTabs.user_tabs(@account)

      expect(tabs.pluck(:label)).not_to include("Other Link")
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

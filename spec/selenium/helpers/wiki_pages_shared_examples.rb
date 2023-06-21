# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

RSpec.shared_examples "course_pages_granular_permissions" do
  def update_role_override(permission, role, is_enabled = true)
    RoleOverride.create!(
      permission: permission.to_s,
      enabled: is_enabled,
      role:,
      account: @course.root_account
    )
  end

  before do
    @role = Role.get_built_in_role(@enrollment.type, root_account_id: Account.default.id)
    unless @role.base_role_type == "TeacherEnrollment"
      raise "only base role type of TeacherEnrollment supported"
    end
  end

  context "user only having manage_wiki_create permission" do
    before do
      update_role_override("manage_wiki_create", @role, true)
      update_role_override("manage_wiki_update", @role, false)
      update_role_override("manage_wiki_delete", @role, false)
    end

    context "show page" do
      it "hides ability to edit or delete page" do
        visit_wiki_page_view(@course.id, @page.title)
        expect(published_status_published).to be_displayed
        expect(wiki_page_show).not_to contain_css(edit_btn_selector)
      end
    end

    context "index page" do
      it "hides ability to edit or delete page" do
        visit_course_wiki_index_page(@course.id)
        expect(page_index_new_page_btn).to be_displayed
        click_manage_wiki_page_item_button(@page.title)
        expect(page_index_duplicate_wiki_page_menu_item).to be_displayed
        expect(page_index_more_options_menu_open).not_to contain_css(edit_menu_item_selector)
        expect(page_index_more_options_menu_open).not_to contain_css(delete_menu_item_selctor)
      end
    end
  end

  context "user only having manage_wiki_update permission" do
    before do
      update_role_override("manage_wiki_create", @role, false)
      update_role_override("manage_wiki_update", @role, true)
      update_role_override("manage_wiki_delete", @role, false)
    end

    context "show page" do
      it "hides ability to delete page" do
        visit_wiki_page_view(@course.id, @page.title)
        expect(published_btn).to be_displayed
        expect(wiki_page_show).to contain_css(edit_btn_selector)
        expect(wiki_page_show).to contain_css(more_options_btn_selector)
        click_more_options_menu
        expect(wiki_page_more_options_menu_open).not_to contain_css(delete_page_menu_item_selector)
      end
    end

    context "index page" do
      it "hides ability to create or delete a page" do
        visit_course_wiki_index_page(@course.id)
        expect(page_index_content_container).not_to contain_css(new_page_btn_selector)
        click_manage_wiki_page_item_button(@page.title)
        expect(page_index_more_options_menu_open).to contain_css(edit_menu_item_selector)
        expect(page_index_more_options_menu_open).not_to contain_css(delete_menu_item_selctor)
      end
    end
  end

  context "user only having manage_wiki_delete permission" do
    before do
      update_role_override("manage_wiki_create", @role, false)
      update_role_override("manage_wiki_update", @role, false)
      update_role_override("manage_wiki_delete", @role, true)
    end

    context "show page" do
      it "hides ability to create or edit page" do
        visit_wiki_page_view(@course.id, @page.title)
        expect(published_status_published).to be_displayed
        expect(wiki_page_show).not_to contain_css(edit_btn_selector)
        click_more_options_menu
        expect(wiki_page_more_options_menu_open).to contain_css(delete_page_menu_item_selector)
      end
    end

    context "index page" do
      it "hides ability to create or edit a page" do
        visit_course_wiki_index_page(@course.id)
        expect(page_index_content_container).not_to contain_css(new_page_btn_selector)
        click_manage_wiki_page_item_button(@page.title)
        expect(page_index_more_options_menu_open).not_to contain_css(edit_menu_item_selector)
        expect(page_index_more_options_menu_open).to contain_css(delete_menu_item_selctor)
      end
    end
  end
end

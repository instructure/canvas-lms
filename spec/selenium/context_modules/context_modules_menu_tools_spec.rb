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

require_relative "../helpers/context_modules_common"
require_relative "page_objects/modules_index_page"
require_relative "page_objects/modules_settings_tray"

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray

  context "module index tool placement" do
    before do
      course_with_teacher_logged_in

      @tool = Account.default.context_external_tools.new(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool.module_index_menu = { url: "http://www.example.com", text: "Import Stuff" }
      @tool.module_group_menu = { url: "http://www.example.com", text: "Import Stuff Here" }
      @tool.save!
      @module1 = @course.context_modules.create!(name: "module1")
      @module2 = @course.context_modules.create!(name: "module2")
    end

    it "is able to launch the index menu tool via the tray", custom_timeout: 30 do
      visit_modules_index_page(@course.id)
      modules_index_settings_button.click
      expect(module_index_settings_menu).to include_text("Import Stuff")

      module_index_menu_tool_link("Import Stuff").click
      wait_for_ajaximations
      expect(tool_dialog_header).to include_text("Import Stuff")
      expect(tool_dialog_iframe["src"]).to include("/courses/#{@course.id}/external_tools/#{@tool.id}")

      query_params = Rack::Utils.parse_nested_query(URI.parse(tool_dialog_iframe["src"]).query)
      expect(query_params["launch_type"]).to eq "module_index_menu"
      expect(query_params["com_instructure_course_allow_canvas_resource_selection"]).to eq "true"
      expect(query_params["com_instructure_course_canvas_resource_type"]).to eq "module"
      expect(query_params["com_instructure_course_accept_canvas_resource_types"]).to match_array(%w[
                                                                                                   assignment audio discussion_topic document image module quiz page video
                                                                                                 ])
      expect(query_params["com_instructure_course_available_canvas_resources"].values).to eq [{
        "course_id" => @course.id.to_s, "type" => "module"
      }] # will replace with the modules on the variable expansion
    end

    it "is able to work with granular permisions properly" do
      @teacher.account.enable_feature!(:granular_permissions_manage_course_content)
      visit_modules_index_page(@course.id)
      modules_index_settings_button.click
      expect(module_index_settings_menu).to include_text("Import Stuff")
    end

    it "is able to launch the individual module menu tool via the tray", custom_timeout: 60 do
      visit_modules_index_page(@course.id)
      manage_module_button(@module2).click
      expect(module_settings_menu(@module2.id)).to include_text("Import Stuff Here")

      module_index_menu_tool_link("Import Stuff Here").click
      wait_for_ajaximations
      expect(tool_dialog_header).to include_text("Import Stuff Here")

      expect(tool_dialog_iframe["src"]).to include("/courses/#{@course.id}/external_tools/#{@tool.id}")

      query_params = Rack::Utils.parse_nested_query(URI.parse(tool_dialog_iframe["src"]).query)
      expect(query_params["launch_type"]).to eq "module_group_menu"
      expect(query_params["com_instructure_course_allow_canvas_resource_selection"]).to eq "false"
      expect(query_params["com_instructure_course_canvas_resource_type"]).to eq "module"
      expect(query_params["com_instructure_course_accept_canvas_resource_types"]).to match_array(%w[
                                                                                                   assignment audio discussion_topic document image module quiz page video
                                                                                                 ])
      module_data = [@module2].map { |m| { "id" => m.id.to_s, "name" => m.name } } # just @module2
      expect(query_params["com_instructure_course_available_canvas_resources"].values).to match_array(module_data)
    end
  end

  context "menu tools", priority: "1" do
    before do
      course_with_teacher_logged_in

      @tool = Account.default.context_external_tools.new(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool.assignment_menu = { url: "http://www.example.com", text: "Export Assignment" }
      @tool.module_menu = { url: "http://www.example.com", text: "Export Module" }
      @tool.quiz_menu = { url: "http://www.example.com", text: "Export Quiz" }
      @tool.wiki_page_menu = { url: "http://www.example.com", text: "Export Wiki Page" }
      @tool.save!

      @module1 = @course.context_modules.create!(name: "module1")
      @assignment = @course.assignments.create!(name: "pls submit", submission_types: ["online_text_entry"], points_possible: 20)
      @assignment_tag = @module1.add_item(id: @assignment.id, type: "assignment")
      @quiz = @course.quizzes.create!(title: "score 10")
      @quiz.publish!
      @quiz_tag = @module1.add_item(id: @quiz.id, type: "quiz")
      @wiki_page = @course.wiki_pages.create!(title: "title", body: "")
      @wiki_page.workflow_state = "active"
      @wiki_page.save!
      @wiki_page_tag = @module1.add_item(id: @wiki_page.id, type: "wiki_page")
      @subheader_tag = @module1.add_item(type: "context_module_sub_header", title: "subheader")
    end

    def should_have_menu_tool_link_in_gear
      gear = f("#context_module_#{@module1.id} .header .al-trigger")
      gear.click
      link = f("#context_module_#{@module1.id} .header li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:module_menu))
      expect(link["href"]).to eq course_external_tool_url(@course, @tool, launch_type: "module_menu", modules: [@module1.id])
    end

    it "shows tool launch links in the gear for modules" do
      get "/courses/#{@course.id}/modules"
      should_have_menu_tool_link_in_gear
    end

    it "shows tool launch links in the gear for modules on course home if set to modules" do
      @course.default_view = "modules"
      @course.save!
      get "/courses/#{@course.id}"
      should_have_menu_tool_link_in_gear
    end

    it "shows tool launch links in the gear for exportable module items" do
      get "/courses/#{@course.id}/modules"

      type_to_tag = {
        assignment_menu: @assignment_tag,
        quiz_menu: @quiz_tag,
        wiki_page_menu: @wiki_page_tag
      }
      type_to_tag.each do |type, tag|
        gear = f("#context_module_item_#{tag.id} .al-trigger")
        gear.click

        type_to_tag.each_key do |other_type|
          next if other_type == type

          expect(f("#content")).not_to contain_css("#context_module_item_#{tag.id} li.#{other_type} a.menu_tool_link")
        end

        link = f("#context_module_item_#{tag.id} li.#{type} a.menu_tool_link")
        expect(link).to be_displayed
        expect(link.text).to match_ignoring_whitespace(@tool.label_for(type))
        expect(link["href"]).to eq course_external_tool_url(@course, @tool, launch_type: type, module_items: [tag.id])
        # need to close gear menu
        gear.click
      end

      gear = f("#context_module_item_#{@subheader_tag.id} .al-trigger")
      gear.click
      expect(f("#context_module_item_#{@subheader_tag.id}")).not_to contain_css("a.menu_tool_link")
    end

    it "adds links to newly created modules" do
      Account.site_admin.disable_feature! :differentiated_modules
      get "/courses/#{@course.id}/modules"
      f(".add_module_link").click
      wait_for_ajaximations
      form = f("#add_context_module_form")
      replace_content(form.find_element(:id, "context_module_name"), "new module")
      submit_form(form)
      wait_for_ajaximations

      new_module = ContextModule.last
      expect(new_module.name).to eq "new module"

      gear = f("#context_module_#{new_module.id} .header .al-trigger")
      gear.click
      link = f("#context_module_#{new_module.id} .header li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:module_menu))
      expect(link["href"]).to eq course_external_tool_url(@course, @tool, launch_type: "module_menu", modules: [new_module.id])
    end

    it "adds links to newly created modules with differentiated modules tray" do
      differentiated_modules_on

      go_to_modules
      click_new_module_link
      update_module_name("new module")
      click_add_tray_add_module_button

      new_module = ContextModule.last
      expect(new_module.name).to eq "new module"

      gear = f("#context_module_#{new_module.id} .header .al-trigger")
      gear.click
      link = f("#context_module_#{new_module.id} .header li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:module_menu))
      expect(link["href"]).to eq course_external_tool_url(@course, @tool, launch_type: "module_menu", modules: [new_module.id])
    end

    it "adds links to newly created module items" do
      get "/courses/#{@course.id}/modules"
      f("#context_module_#{@module1.id} .add_module_item_link").click
      wait_for_ajaximations

      click_option("#add_module_item_select", "wiki_page", :value)
      click_option("#wiki_pages_select .module_item_select", "new", :value)
      replace_content(f("#wiki_pages_select .item_title"), "new page")
      fj(".add_item_button.ui-button").click
      wait_for_ajaximations

      new_page = WikiPage.last
      expect(new_page.title).to eq "new page"

      new_tag = ContentTag.last
      expect(new_tag.content).to eq new_page

      gear = f("#context_module_item_#{new_tag.id} .al-trigger")
      gear.click

      [:assignment_menu, :quiz_menu].each do |other_type|
        link = f("#context_module_item_#{new_tag.id} li.#{other_type} a.menu_tool_link")
        expect(link).not_to be_displayed
      end

      link = f("#context_module_item_#{new_tag.id} li.wiki_page_menu a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:wiki_page_menu))
      expect(link["href"]).to eq course_external_tool_url(@course, @tool, launch_type: "wiki_page_menu", module_items: [new_tag.id])
    end

    it "does not show add links to newly created module items if not exportable" do
      get "/courses/#{@course.id}/modules"

      f("#context_module_#{@module1.id} .add_module_item_link").click
      wait_for_ajaximations
      click_option("#add_module_item_select", "external_url", :value)
      replace_content(f("#content_tag_create_url"), "http://www.example.com")
      replace_content(f("#content_tag_create_title"), "new item")

      fj(".add_item_button.ui-button").click
      wait_for_ajaximations

      new_tag = ContentTag.last

      gear = f("#context_module_item_#{new_tag.id} .al-trigger")
      gear.click
      link = f("#context_module_item_#{new_tag.id} li.ui-menu-item a.menu_tool_link")
      expect(link).not_to be_displayed
    end

    context "visibility for roles" do
      before do
        @tool.module_index_menu_modal = { enabled: true, message_type: "LtiResourceLinkRequest" }
        @tool.save!
      end

      shared_examples "does not show the module_index_tools menu" do
        it "in the modules Page" do
          get "/courses/#{@course.id}/modules"
          expect(f(".header-bar-right__buttons")).not_to contain_css(".module_index_tools")
        end

        it "in the course home page" do
          get "/courses/#{@course.id}"
          expect(f(".header-bar-right__buttons")).not_to contain_css(".module_index_tools")
        end
      end

      shared_examples "shows the module_index_tools menu" do
        it "in the modules Page" do
          get "/courses/#{@course.id}/modules"
          expect(f(".header-bar-right__buttons")).to contain_css(".module_index_tools")
          expect(f(".module_index_tools")).to be_displayed
        end

        it "in the course home page" do
          get "/courses/#{@course.id}"
          expect(f(".header-bar-right__buttons")).to contain_css(".module_index_tools")
          expect(f(".module_index_tools")).to be_displayed
        end
      end

      context "when the user is a student" do
        before { user_session(student_in_course(course: @course, name: "student", active_all: true).user) }

        it_behaves_like "does not show the module_index_tools menu"
      end

      context "when the user is a observer" do
        before { user_session(observer_in_course(course: @course, name: "observer", active_all: true).user) }

        it_behaves_like "does not show the module_index_tools menu"
      end

      context "when the user is a teacher" do
        before { user_session(teacher_in_course(course: @course, name: "teacher", active_all: true).user) }

        it_behaves_like "shows the module_index_tools menu"
      end

      context "when the user is a ta" do
        before { user_session(ta_in_course(course: @course, name: "ta", active_all: true).user) }

        it_behaves_like "shows the module_index_tools menu"
      end

      context "when the user is a designer" do
        before { user_session(designer_in_course(course: @course, name: "designer", active_all: true).user) }

        it_behaves_like "shows the module_index_tools menu"
      end
    end
  end
end

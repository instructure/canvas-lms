# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../common"
require_relative "page_objects/new_content_migration_page"
require_relative "page_objects/new_select_content_page"
require_relative "page_objects/new_course_copy_page"

def visit_page
  @course.reload
  get "/courses/#{@course.id}/content_migrations"
end

def select_migration_type(type = nil)
  type ||= @type
  ContentMigrationPage.migration_type_dropdown.click
  ContentMigrationPage.migration_type_option_by_id(type).click
end

def select_migration_file(opts = {})
  filename = opts[:filename] || @filename

  new_filename, fullpath, _data = get_file(filename, opts[:data])
  ContentMigrationPage.migration_file_upload_input.send_keys(fullpath)
  new_filename
end

def fill_migration_form(opts = {})
  select_migration_type("empty") unless opts[:type] == "empty"
  select_migration_type(opts[:type])
  select_migration_file(opts)
end

def submit
  @course.reload
  # depending on the type of migration, we need to wait for it to have one of these states
  scope = { workflow_state: %w[queued exporting exported] }
  count = @course.content_migrations.where(scope).count
  ContentMigrationPage.add_import_queue_button.click
  keep_trying_until do
    expect(@course.content_migrations.where(scope).count).to eq count + 1
  end
end

def run_migration(cm = nil)
  cm ||= @course.content_migrations.last
  cm.reload
  cm.skip_job_progress = false
  cm.reset_job_progress
  worker_class = Canvas::Migration::Worker.const_get(Canvas::Plugin.find(cm.migration_type).settings["worker"])
  worker_class.new(cm.id).perform
end

def import(cm = nil)
  cm ||= @course.content_migrations.last
  cm.reload
  cm.set_default_settings
  cm.import_content
end

def test_selective_content(source_course = nil)
  visit_page

  # Open selective dialog
  expect(ContentMigrationPage.progress_status_label).to include_text("Waiting for Selection")
  ContentMigrationPage.select_content_button.click
  wait_for_ajaximations

  ContentMigrationPage.all_assignments_checkbox.click

  # Submit selection
  ContentMigrationPage.select_content_submit_button.click
  wait_for_ajaximations

  source_course ? run_migration : import

  visit_page

  expect(ContentMigrationPage.progress_status_label).to include_text("Completed")
  expect(@course.assignments.count).to eq(source_course ? source_course.assignments.count : 1)
end

describe "content migrations", :non_parallel do
  before(:once) do
    Account.site_admin.enable_feature! :instui_for_import_page
  end

  include_context "in-process server selenium tests"

  def test_selective_outcome(source_course = nil)
    visit_page

    # Open selective dialog
    ContentMigrationPage.select_content_button.click

    # Expand learning outcomes
    SelectContentPage.outcome_parent.click

    # Expand first group
    SelectContentPage.outcome_options(1)

    # Select subgroup
    SelectContentPage.outcome_checkboxes(2)

    # Submit selection
    SelectContentPage.submit_button

    source_course ? run_migration : import

    visit_page

    # root + subgroup1
    expect(@course.learning_outcome_groups.count).to eq 2
    groups = @course.root_outcome_group.child_outcome_groups
    expect(groups.count).to eq 1
    subgroup1 = groups.first
    expect(subgroup1.title).to eq "subgroup1"

    # non-root2 + non-root3
    expect(@course.created_learning_outcomes.count).to eq 2
    outcome_links = subgroup1.child_outcome_links
    expect(outcome_links.map { |l| l.learning_outcome_content.short_description })
      .to match_array(["non-root2", "non-root3"])
  end

  context "canvas cartridge importing" do
    before do
      course_with_teacher_logged_in
      @type = "canvas_cartridge_importer"
      @filename = "cc_outcomes.imscc"
    end

    context "with selectable_outcomes_in_course_copy enabled" do
      before do
        @course.root_account.enable_feature!(:selectable_outcomes_in_course_copy)
      end

      it "selectively copies outcomes", skip: "learning outcomes not working" do
        visit_page

        fill_migration_form

        ContentMigrationPage.specific_content_radio.click
        submit
        run_migration

        test_selective_outcome
      end
    end
  end

  context "common cartridge importing" do
    before do
      course_with_teacher_logged_in
      @type = "common_cartridge_importer"
      @filename = "cc_full_test.zip"
    end

    it "shows each form" do
      visit_page

      ContentMigrationPage.migration_type_dropdown.click
      migration_types = CourseCopyPage.migration_type_options_values.pluck("value") - ["empty"]
      ContentMigrationPage.migration_type_dropdown.click
      migration_types.each do |type|
        select_migration_type(type)
        expect(ContentMigrationPage.add_import_queue_button).to be_displayed
        select_migration_type("empty")
        expect(element_exists?(ContentMigrationPage.add_import_queue_button_selector)).to be false
      end

      # Cancel not implemented

      # select_migration_type
      # cancel_btn = CourseCopyPage.cancel_copy_button
      # expect(cancel_btn).to be_displayed
      # cancel_btn.click

      # expect(ContentMigrationPage.content).not_to contain_css(ContentMigrationPage.migration_file_upload_input_id)
    end

    it "submit's queue and list migrations", skip: "no file upload" do
      visit_page
      fill_migration_form
      ContentMigrationPage.all_content_radio.click
      submit

      expect(ContentMigrationPage.migration_progress_items.count).to eq 1

      fill_migration_form(filename: "cc_ark_test.zip")

      ContentMigrationPage.all_content_radio.click
      submit

      visit_page
      expect(@course.content_migrations.count).to eq 2

      progress_items = ContentMigrationPage.migration_progress_items
      expect(progress_items.count).to eq 2

      source_links = []
      progress_items.each do |item|
        expect(item.find_element(:css, ".migrationName")).to include_text("Common Cartridge")
        expect(item.find_element(:css, ".progressStatus")).to include_text("Queued")

        source_links << item.find_element(:css, ".sourceLink a")
      end

      hrefs = source_links.map { |a| a.attribute(:href) }

      @course.content_migrations.each do |cm|
        expect(hrefs.find { |href| href.include?("/files/#{cm.attachment_id}/download") }).not_to be_nil
      end
    end

    it "shifts dates", skip: "not implemented" do
      visit_page
      fill_migration_form
      CourseCopyPage.date_adjust_checkbox.click
      ContentMigrationPage.all_content_radio.click
      replace_and_proceed(CourseCopyPage.old_start_date_input, "7/1/2014")
      replace_and_proceed(CourseCopyPage.old_end_date_input, "Jul 11, 2014")
      replace_and_proceed(CourseCopyPage.new_start_date_input, "8-5-2014")
      replace_and_proceed(CourseCopyPage.new_end_date_input, "Aug 15, 2014")
      2.times { CourseCopyPage.add_day_substitution_button.click }
      click_option("#daySubstitution ul > div:nth-child(1) .currentDay", "1", :value)
      click_option("#daySubstitution ul > div:nth-child(1) .subDay", "2", :value)
      click_option("#daySubstitution ul > div:nth-child(2) .currentDay", "5", :value)
      click_option("#daySubstitution ul > div:nth-child(2) .subDay", "4", :value)
      submit
      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      expect(opts["shift_dates"]).to eq "1"
      expect(opts["day_substitutions"]).to eq({ "1" => "2", "5" => "4" })
      expect(Date.parse(opts["old_start_date"])).to eq Date.new(2014, 7, 1)
      expect(Date.parse(opts["old_end_date"])).to eq Date.new(2014, 7, 11)
      expect(Date.parse(opts["new_start_date"])).to eq Date.new(2014, 8, 5)
      expect(Date.parse(opts["new_end_date"])).to eq Date.new(2014, 8, 15)
    end
  end

  context "course copy", skip: "issues with cc search" do
    before do
      # the "true" param is important, it forces the cache clear
      #  without it this spec group fails if
      #  you run it with the whole suite
      #  because of a cached default account
      #  that no longer exists in the db
      Account.clear_special_account_cache!(true)
      @copy_from = course_factory
      @copy_from.update_attribute(:name, "copy from me")
      data = File.read(File.dirname(__FILE__) + "/../../fixtures/migration/cc_full_test_smaller.zip")

      cm = ContentMigration.new(context: @copy_from, migration_type: "common_cartridge_importer")
      cm.migration_settings = { import_immediately: true,
                                migration_ids_to_import: { copy: { everything: true } } }
      cm.skip_job_progress = true
      cm.save!

      att = attachment_model(context: cm,
                             filename: "cc_full_test_smaller.zip",
                             uploaded_data: stub_file_data("cc_full_test_smaller.zip", data, "application/zip"))
      cm.attachment = att
      cm.save!

      worker_class = Canvas::Migration::Worker.const_get(Canvas::Plugin.find(cm.migration_type).settings["worker"])
      worker_class.new(cm.id).perform

      @course = nil
      @type = "course_copy_importer"
    end

    before do
      course_with_teacher_logged_in(active_all: true)
      @copy_from.enroll_teacher(@user).accept
    end

    it "only shows courses the user is authorized to see", priority: "1" do
      new_course = Course.create!(name: "please don't see me")
      visit_page
      select_migration_type
      wait_for_ajaximations

      ContentMigrationPage.course_search_input.send_keys(@copy_from.name)
      ContentMigrationPage.course_search_input.send_keys(:enter)
      wait_for_ajaximations
      expect(ContentMigrationPage.course_search_result(@copy_from.id.to_s)).to be_displayed

      ContentMigrationPage.course_search_input.send_keys(new_course.name)
      expect(ContentMigrationPage.course_search_result(new_course.id.to_s)).not_to be_displayed

      user_logged_in(active_all: true)
      @course.enroll_teacher(@user, enrollment_state: "active")
      new_course.enroll_teacher(@user, enrollment_state: "active")

      visit_page
      select_migration_type
      wait_for_ajaximations

      ContentMigrationPage.course_search_input.send_keys(new_course.name)
      expect(ContentMigrationPage.course_search_result(new_course.id)).not_to be_displayed
    end

    it "includes completed courses when checked", priority: "1" do
      new_course = Course.create!(name: "completed course")
      new_course.enroll_teacher(@user).accept
      new_course.complete!

      visit_page

      select_migration_type
      wait_for_ajaximations
      ContentMigrationPage.course_search_input.send_keys(new_course.name)
      expect(ContentMigrationPage.course_search_result(new_course.id)).not_to be_displayed

      ContentMigrationPage.include_completed_courses_checkbox.click
      wait_for_ajaximations
      ContentMigrationPage.course_search_input.send_keys(new_course.name)
      expect(ContentMigrationPage.course_search_result(new_course.id)).not_to be_displayed
    end

    it "finds courses in other accounts", priority: "1" do
      new_account1 = account_model
      enrolled_course = Course.create!(name: "faraway course", account: new_account1)
      enrolled_course.enroll_teacher(@user).accept

      new_account2 = account_model
      admin_course = Course.create!(name: "another course", account: new_account2)
      account_admin_user(user: @user, account: new_account2)

      visit_page

      select_migration_type
      wait_for_ajaximations

      search = ContentMigrationPage.course_search_input
      search.send_keys("another")
      wait_for_ajaximations
      expect(ContentMigrationPage.course_search_results_visible[0].text).to eq admin_course.name

      search.clear
      search.send_keys("faraway")
      wait_for_ajaximations
      expect(ContentMigrationPage.course_search_results_visible[0].text).to eq enrolled_course.name
    end

    context "Qti Enabled" do
      before do
        data = File.read(File.dirname(__FILE__) + "/../../fixtures/migration/cc_full_test.zip")

        cm = ContentMigration.new(context: @copy_from, migration_type: "common_cartridge_importer")
        cm.migration_settings = { import_immediately: true,
                                  migration_ids_to_import: { copy: { everything: true } } }
        cm.skip_job_progress = true
        cm.save!

        att = attachment_model(context: cm,
                               filename: "cc_full_test.zip",
                               uploaded_data: stub_file_data("cc_full_test.zip", data, "application/zip"))
        cm.attachment = att
        cm.save!

        worker_class = Canvas::Migration::Worker.const_get(Canvas::Plugin.find(cm.migration_type).settings["worker"])
        worker_class.new(cm.id).perform
      end

      it "copies all content from a course", priority: "1" do
        skip unless Qti.qti_enabled?
        visit_page

        select_migration_type
        wait_for_ajaximations

        click_option("#courseSelect", @copy_from.id.to_s, :value)
        ContentMigrationPage.all_content_radio.click
        submit

        run_migration

        expect(@course.attachments.count).to eq 10
        expect(@course.discussion_topics.count).to eq 2
        expect(@course.context_modules.count).to eq 3
        expect(@course.context_external_tools.count).to eq 2
        expect(@course.quizzes.count).to eq 1
        expect(@course.quizzes.first.quiz_questions.count).to eq 11
      end

      it "selectively copies content", priority: "1" do
        skip unless Qti.qti_enabled?
        visit_page

        select_migration_type
        wait_for_ajaximations

        click_option("#courseSelect", @copy_from.id.to_s, :value)
        ContentMigrationPage.specific_content_radio.click
        submit

        test_selective_content(@copy_from)
      end
    end

    context "with selectable_outcomes_in_course_copy enabled" do
      before do
        @course.root_account.enable_feature!(:selectable_outcomes_in_course_copy)
        root = @copy_from.root_outcome_group(true)
        outcome_model(context: @copy_from, title: "root1")

        group = root.child_outcome_groups.create!(context: @copy_from, title: "group1")
        outcome_model(context: @copy_from, outcome_group: group, title: "non-root1")

        subgroup = group.child_outcome_groups.create!(context: @copy_from, title: "subgroup1")
        outcome_model(context: @copy_from, outcome_group: subgroup, title: "non-root2")
        outcome_model(context: @copy_from, outcome_group: subgroup, title: "non-root3")
      end

      after do
        @course.root_account.disable_feature!(:selectable_outcomes_in_course_copy)
      end

      it "selectively copies outcomes", skip: "issues with CC search" do
        visit_page

        select_migration_type
        wait_for_ajaximations

        ContentMigrationPage.specific_content_radio.click
        submit

        test_selective_outcome(@copy_from)
      end
    end

    it "sets day substitution and date adjustment settings", priority: "1" do
      # TODO: fix click_option
      new_course = Course.create!(name: "day sub")
      new_course.enroll_teacher(@user).accept

      visit_page
      select_migration_type
      wait_for_ajaximations
      click_option("#courseSelect", new_course.id.to_s, :value)

      CourseCopyPage.date_adjust_checkbox.click
      3.times do
        CourseCopyPage.add_day_substitution_button.click
      end

      expect(CourseCopyPage.day_substitution_containers.count).to eq 3
      CourseCopyPage.day_substitution_delete_button.click # Remove day substitution
      expect(CourseCopyPage.day_substitution_containers.count).to eq 2

      click_option("#daySubstitution ul > div:nth-child(1) .currentDay", "1", :value)
      click_option("#daySubstitution ul > div:nth-child(1) .subDay", "2", :value)

      click_option("#daySubstitution ul > div:nth-child(2) .currentDay", "2", :value)
      click_option("#daySubstitution ul > div:nth-child(2) .subDay", "3", :value)

      CourseCopyPage.old_start_date_input.send_keys("7/1/2012")
      CourseCopyPage.old_end_date_input.send_keys("Jul 11, 2012")
      CourseCopyPage.new_start_date_input.clear
      CourseCopyPage.new_start_date_input.send_keys("8-5-2012")
      CourseCopyPage.new_end_date_input.send_keys("Aug 15, 2012")

      ContentMigrationPage.all_content_radio.click
      submit

      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      expect(opts["shift_dates"]).to eq "1"
      expect(opts["day_substitutions"]).to eq({ "1" => "2", "2" => "3" })
      expected = {
        "old_start_date" => "Jul 1, 2012",
        "old_end_date" => "Jul 11, 2012",
        "new_start_date" => "Aug 5, 2012",
        "new_end_date" => "Aug 15, 2012"
      }
      expected.each do |k, v|
        expect(Date.parse(opts[k].to_s)).to eq Date.parse(v)
      end
    end

    it "sets pre-populate date adjustment settings" do
      new_course = Course.create!(name: "date adjust", start_at: "Jul 1, 2012", conclude_at: "Jul 11, 2012")
      new_course.enroll_teacher(@user).accept

      @course.start_at = "Aug 5, 2012"
      @course.conclude_at = "Aug 15, 2012"
      @course.save!

      visit_page
      select_migration_type
      wait_for_ajaximations
      click_option("#courseSelect", new_course.id.to_s, :value)

      CourseCopyPage.date_adjust_checkbox.click
      ContentMigrationPage.all_content_radio.click

      submit

      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      expect(opts["shift_dates"]).to eq "1"
      expect(opts["day_substitutions"]).to eq({})
      expected = {
        "old_start_date" => "Jul 1, 2012",
        "old_end_date" => "Jul 11, 2012",
        "new_start_date" => "Aug 5, 2012",
        "new_end_date" => "Aug 15, 2012"
      }
      expected.each do |k, v|
        expect(Date.parse(opts[k].to_s)).to eq Date.parse(v)
      end
    end

    it "removes dates", priority: "1" do
      new_course = Course.create!(name: "date remove", start_at: "Jul 1, 2014", conclude_at: "Jul 11, 2014")
      new_course.enroll_teacher(@user).accept

      visit_page
      select_migration_type
      wait_for_ajaximations
      click_option("#courseSelect", new_course.id.to_s, :value)

      CourseCopyPage.date_adjust_checkbox.click
      CourseCopyPage.date_remove_option.click
      ContentMigrationPage.all_content_radio.click

      submit

      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      expect(opts["remove_dates"]).to eq "1"
    end

    it "retains announcement content settings after course copy", priority: "2" do
      @announcement = @copy_from.announcements.create!(title: "Migration", message: "Here is my message")
      @copy_from.lock_all_announcements = true
      @copy_from.save!

      visit_page
      select_migration_type
      wait_for_ajaximations
      click_option("#courseSelect", @copy_from.id.to_s, :value)
      ContentMigrationPage.all_content_radio.click
      submit
      run_jobs
      # Wait until the item is imported on the back-end, otherwise the selenium tools will fail the test due to runtime
      keep_trying_until { ContentMigration.last.workflow_state == "imported" }
      @course.reload
      expect(@course.announcements.last.locked).to be_truthy
      expect(@course.lock_all_announcements).to be_truthy
    end

    it "persists topic 'allow liking' settings across course copy", priority: "2" do
      @copy_from.discussion_topics.create!(
        title: "Liking Allowed Here",
        message: "Like I said, liking is allowed",
        allow_rating: true
      )

      visit_page
      select_migration_type
      wait_for_ajaximations
      click_option("#courseSelect", @copy_from.id.to_s, :value)
      ContentMigrationPage.all_content_radio.click
      submit
      run_jobs
      # Wait until the item is imported on the back-end, otherwise the selenium tools will fail the test due to runtime
      keep_trying_until { ContentMigration.last.workflow_state == "imported" }
      @course.reload
      expect(@course.discussion_topics.last.allow_rating).to be_truthy
    end
  end

  context "importing LTI content", skip: "LTI not implemented" do
    let(:import_course) do
      account = account_model
      course_with_teacher_logged_in(account:).course
    end
    let(:import_tool) do
      tool = import_course.context_external_tools.new({
                                                        name: "test lti import tool",
                                                        consumer_key: "key",
                                                        shared_secret: "secret",
                                                        url: "http://www.example.com/ims/lti",
                                                      })
      tool.migration_selection = {
        url: "http://#{HostUrl.default_host}/selection_test",
        text: "LTI migration text",
        selection_width: 500,
        selection_height: 500,
        icon_url: "/images/add.png",
      }
      tool.save!
      tool
    end
    let(:other_tool) do
      tool = import_course.context_external_tools.new({
                                                        name: "other lti tool",
                                                        consumer_key: "key",
                                                        shared_secret: "secret",
                                                        url: "http://www.example.com/ims/lti",
                                                      })
      tool.resource_selection = {
        url: "http://#{HostUrl.default_host}/selection_test",
        text: "other resource text",
        selection_width: 500,
        selection_height: 500,
        icon_url: "/images/add.png",
      }
      tool.save!
      tool
    end

    it "shows LTI tools with migration_selection in the select control" do
      import_tool
      other_tool
      visit_page
      migration_type_options = CourseCopyPage.migration_type_options
      migration_type_values = migration_type_options.pluck("value")
      migration_type_texts = migration_type_options.map(&:text)
      expect(migration_type_values).to include(import_tool.asset_string)
      expect(migration_type_texts).to include(import_tool.label_for(:migration_selection))
      expect(migration_type_values).not_to include(other_tool.asset_string)
      expect(migration_type_texts).not_to include(other_tool.label_for(:resource_selection))
    end

    it "shows LTI view when LTI tool selected" do
      import_tool
      visit_page
      select_migration_type(import_tool.asset_string)
      expect(ContentMigrationPage.external_tool_launch).to be_displayed
      expect(ContentMigrationPage.lti_select_content).to be_displayed
    end

    it "launches LTI tool on browse and get content link" do
      import_tool
      visit_page
      select_migration_type(import_tool.asset_string)
      ContentMigrationPage.external_tool_launch_button.click
      tool_iframe = ContentMigrationPage.lti_iframe
      expect(ContentMigrationPage.lti_title.text).to eq import_tool.label_for(:migration_selection)

      in_frame(tool_iframe, "#basic_lti_link") do
        ContentMigrationPage.basic_lti_link.click
      end

      expect(ContentMigrationPage.file_name_label).to include_text "lti embedded link"
    end

    it "has content selection option" do
      import_tool
      visit_page
      select_migration_type(import_tool.asset_string)
      expect(ContentMigrationPage.selective_import_dropdown.size).to eq 2
    end
  end

  it "is able to selectively import common cartridge submodules", skip: "CC 1.1 not implemented" do
    course_with_teacher_logged_in
    cm = ContentMigration.new(context: @course, user: @user)
    cm.migration_type = "common_cartridge_importer"
    cm.save!

    package_path = File.join(File.dirname(__FILE__) + "/../../fixtures/migration/cc_full_test.zip")
    attachment = Attachment.new
    attachment.context = cm
    attachment.filename = "file.zip"
    attachment.uploaded_data = File.open(package_path, "rb")
    attachment.save!

    cm.attachment = attachment
    cm.save!

    cm.queue_migration
    run_jobs

    visit_page

    ContentMigrationPage.select_content_button.click
    wait_for_ajaximations
    ContentMigrationPage.module.click
    wait_for_ajaximations

    submod = ContentMigrationPage.submodule
    expect(submod).to include_text("1 sub-module")
    submod.find_element(:css, "a.checkbox-caret").click
    wait_for_ajaximations

    expect(submod.find_element(:css, ".module_options")).to_not be_displayed

    sub_submod = submod.find_element(:css, "li.normal-treeitem")
    expect(sub_submod).to include_text("Study Guide")

    sub_submod.find_element(:css, 'input[type="checkbox"]').click
    wait_for_ajaximations

    expect(submod.find_element(:css, ".module_options")).to be_displayed # should show the module option now
    # select to import submodules individually
    radio_to_click = submod.find_element(:css, 'input[type="radio"][value="separate"]')
    move_to_click("label[for=#{radio_to_click["id"]}]")

    ContentMigrationPage.select_content_submit_button.click
    wait_for_ajaximations

    run_jobs

    expect(@course.context_modules.count).to eq 1
    expect(@course.context_modules.first.name).to eq "Study Guide"
  end
end

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
require_relative "page_objects/new_content_migration_progress_item"
require_relative "page_objects/new_select_content_page"
require_relative "page_objects/new_course_copy_page"

describe "content migrations", :non_parallel do
  include_context "in-process server selenium tests"

  def visit_page
    @course.reload
    get "/courses/#{@course.id}/content_migrations"
  end

  def select_migration_type(type = nil)
    type ||= @type
    NewContentMigrationPage.migration_type_dropdown.click
    Selenium::WebDriver::Wait.new(timeout: 5).until do
      NewContentMigrationPage.migration_type_dropdown.attribute("aria-expanded") == "true"
    end
    NewContentMigrationPage.migration_type_option_by_id(type).click
  end

  def select_migration_file(opts = {})
    filename = opts[:filename] || @filename

    new_filename, fullpath, _data = get_file(filename, opts[:data])
    NewContentMigrationPage.migration_file_upload_input.send_keys(fullpath)
    new_filename
  end

  def fill_migration_form(opts = {})
    select_migration_type(opts[:type])
    select_migration_file(opts)
  end

  def submit
    @course.reload
    # depending on the type of migration, we need to wait for it to have one of these states
    scope = { workflow_state: %w[queued exporting exported] }
    count = @course.content_migrations.where(scope).count
    NewContentMigrationPage.add_import_queue_button.click
    keep_trying_until do
      expect(@course.content_migrations.where(scope).count).to eq count + 1
    end
  end

  def run_migration(content_migration = nil)
    content_migration ||= @course.content_migrations.last
    content_migration.reload
    content_migration.skip_job_progress = false
    content_migration.reset_job_progress
    worker_class = Canvas::Migration::Worker.const_get(Canvas::Plugin.find(content_migration.migration_type).settings["worker"])
    worker_class.new(content_migration.id).perform
  end

  def test_search_course_field(course)
    input_canvas_select(NewContentMigrationPage.course_search_input, course.name)
    option_text = instui_select_option(NewContentMigrationPage.course_search_input, course.id, select_by: :id).text
    expect(option_text).to eq "#{course.name}\nTerm: #{course.term_name}"
  end

  def import(content_migration = nil)
    content_migration ||= @course.content_migrations.last
    content_migration.reload
    content_migration.set_default_settings
    content_migration.import_content
  end

  def test_selective_content(source_course = nil)
    visit_page

    # Open selective dialog
    expect(NewContentMigrationPage.progress_status_label).to include_text("Waiting for selection")
    NewContentMigrationPage.select_content_button.click
    wait_for_ajaximations

    NewContentMigrationPage.all_assignments_checkbox.click

    # Submit selection
    NewContentMigrationPage.select_content_submit_button.click
    wait_for_ajaximations

    source_course ? run_migration : import

    visit_page

    expect(NewContentMigrationPage.progress_status_label).to include_text("Completed")
    expect(@course.assignments.count).to eq(source_course ? source_course.assignments.count : 1)
  end

  def test_selective_outcome(source_course = nil)
    visit_page

    # Open selective dialog
    NewContentMigrationPage.select_content_button.click

    # Expand learning outcomes
    NewSelectContentPage.outcome_parent.click

    # Expand first group
    NewSelectContentPage.outcome_option_caret_by_name("group1").click

    # Select subgroup
    NewSelectContentPage.outcome_option_checkbox_by_name("subgroup1").click

    # Submit selection
    NewSelectContentPage.submit_button.click
    wait_for_ajax_requests

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

    it "selectively copies outcomes" do
      visit_page

      fill_migration_form

      NewContentMigrationPage.specific_content_radio.click
      submit
      run_migration

      test_selective_outcome
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

      NewContentMigrationPage.migration_type_dropdown.click
      migration_types = NewCourseCopyPage.migration_type_options_values.pluck("value") - ["empty"]
      NewContentMigrationPage.migration_type_dropdown.click
      migration_types.each do |type|
        select_migration_type(type)
        expect(NewContentMigrationPage.add_import_queue_button).to be_displayed
        expect(NewContentMigrationPage.clear_button).to be_displayed
        NewContentMigrationPage.clear_button.click
        expect(element_exists?(NewContentMigrationPage.add_import_queue_button_selector)).to be false
      end

      # Cancel not implemented

      # select_migration_type
      # cancel_btn = CourseCopyPage.cancel_copy_button
      # expect(cancel_btn).to be_displayed
      # cancel_btn.click

      # expect(NewContentMigrationPage.content).not_to contain_css(NewContentMigrationPage.migration_file_upload_input_id)
    end

    it "submit's queue and list migrations" do
      visit_page
      fill_migration_form
      NewContentMigrationPage.all_content_radio.click
      submit

      expect(NewContentMigrationPage.migration_progress_items.count).to eq 1

      fill_migration_form(filename: "cc_ark_test.zip")

      NewContentMigrationPage.all_content_radio.click
      submit

      visit_page
      expect(@course.content_migrations.count).to eq 2

      progress_items = NewContentMigrationPage.migration_progress_items
      expect(progress_items.count).to eq 2

      progress_items.each do |item|
        progress_item = NewContentMigrationProgressItem.new(item)
        expect(progress_item.content_type).to include_text("Common Cartridge")
        expect(progress_item.status).to include_text("Queued")

        download_url = progress_item.source_link.attribute(:href)
        expect(download_url).to include("download")
      end
    end

    it "shifts dates" do
      visit_page
      fill_migration_form
      NewContentMigrationPage.date_adjust_checkbox.click
      NewContentMigrationPage.all_content_radio.click
      replace_and_proceed(NewContentMigrationPage.old_start_date_input, "7/1/2014")
      replace_and_proceed(NewContentMigrationPage.old_end_date_input, "Jul 11, 2014")
      replace_and_proceed(NewContentMigrationPage.new_start_date_input, "8-5-2014")
      replace_and_proceed(NewContentMigrationPage.new_end_date_input, "Aug 15, 2014")
      2.times { NewContentMigrationPage.add_day_substitution_button.click }
      NewContentMigrationPage.select_day_substition_range(1, "Monday", "Tuesday")
      NewContentMigrationPage.select_day_substition_range(2, "Friday", "Thursday")
      submit
      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      expect(opts["shift_dates"]).to be true
      expect(opts["day_substitutions"]).to eq({ "1" => "2", "5" => "4" })
      expect(Date.parse(opts["old_start_date"])).to eq Date.new(2014, 7, 1)
      expect(Date.parse(opts["old_end_date"])).to eq Date.new(2014, 7, 11)
      expect(Date.parse(opts["new_start_date"])).to eq Date.new(2014, 8, 5)
      expect(Date.parse(opts["new_end_date"])).to eq Date.new(2014, 8, 15)
    end
  end

  context "course copy" do
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

      input_canvas_select(NewContentMigrationPage.course_search_input, @copy_from.name)
      expect(NewContentMigrationPage.course_search_input_has_options?).to be true

      input_canvas_select(NewContentMigrationPage.course_search_input, new_course.name)
      expect(driver.find_elements(css: '[id="empty-option"]').any?).to be true

      user_logged_in(active_all: true)
      @course.enroll_teacher(@user, enrollment_state: "active")
      new_course.enroll_teacher(@user, enrollment_state: "active")

      visit_page
      select_migration_type
      wait_for_ajaximations

      input_canvas_select(NewContentMigrationPage.course_search_input, new_course.name)
      expect(driver.find_elements(css: '[id="empty-option"]').any?).to be true
    end

    it "includes completed courses when checked", priority: "1" do
      new_course = Course.create!(name: "completed course")
      new_course.enroll_teacher(@user).accept
      new_course.complete!

      visit_page

      select_migration_type
      wait_for_ajaximations
      input_canvas_select(NewContentMigrationPage.course_search_input, new_course.name)
      expect(NewContentMigrationPage.course_search_input_has_options?).to be true

      NewContentMigrationPage.include_completed_courses_checkbox.click
      wait_for_ajaximations
      input_canvas_select(NewContentMigrationPage.course_search_input, new_course.name)
      expect(driver.find_elements(css: '[id="empty-option"]').any?).to be true
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

      test_search_course_field(admin_course)
      test_search_course_field(enrolled_course)
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

        search_for_option(NewContentMigrationPage.course_search_input_selector, @copy_from.name, @copy_from.id.to_s, :id)
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

        search_for_option(NewContentMigrationPage.course_search_input_selector, @copy_from.name, @copy_from.id.to_s, :id)
        NewContentMigrationPage.specific_content_radio.click
        submit

        test_selective_content(@copy_from)
      end
    end

    context "with selectable_outcomes_in_course_copy enabled" do
      before do
        root = @copy_from.root_outcome_group(true)
        outcome_model(context: @copy_from, title: "root1")

        group = root.child_outcome_groups.create!(context: @copy_from, title: "group1")
        outcome_model(context: @copy_from, outcome_group: group, title: "non-root1")

        subgroup = group.child_outcome_groups.create!(context: @copy_from, title: "subgroup1")
        outcome_model(context: @copy_from, outcome_group: subgroup, title: "non-root2")
        outcome_model(context: @copy_from, outcome_group: subgroup, title: "non-root3")
      end

      it "selectively copies outcomes" do
        visit_page

        select_migration_type
        wait_for_ajaximations

        search_for_option(NewContentMigrationPage.course_search_input_selector, @copy_from.name, @copy_from.id.to_s, :id)
        NewContentMigrationPage.specific_content_radio.click
        submit

        test_selective_outcome(@copy_from)
      end
    end

    it "sets day substitution and date adjustment settings", priority: "1" do
      new_course = Course.create!(name: "day sub")
      new_course.enroll_teacher(@user).accept

      visit_page
      select_migration_type
      wait_for_ajaximations
      search_for_option(NewContentMigrationPage.course_search_input_selector, new_course.name, new_course.id.to_s, :id)

      NewContentMigrationPage.date_adjust_checkbox.click
      3.times { NewContentMigrationPage.add_day_substitution_button.click }

      expect(NewContentMigrationPage.number_of_day_substitutions).to eq 3
      NewContentMigrationPage.day_substitution_delete_button_by_index(3).click
      expect(NewContentMigrationPage.number_of_day_substitutions).to eq 2

      NewContentMigrationPage.select_day_substition_range(1, "Monday", "Tuesday")
      NewContentMigrationPage.select_day_substition_range(2, "Tuesday", "Wednesday")

      replace_and_proceed(NewContentMigrationPage.old_start_date_input, "7/1/2012")
      replace_and_proceed(NewContentMigrationPage.old_end_date_input, "Jul 11, 2012")
      replace_and_proceed(NewContentMigrationPage.new_start_date_input, "8-5-2012")
      replace_and_proceed(NewContentMigrationPage.new_end_date_input, "Aug 15, 2012")

      NewContentMigrationPage.all_content_radio.click
      submit

      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      expect(opts["shift_dates"]).to be true
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
      search_for_option(NewContentMigrationPage.course_search_input_selector, new_course.name, new_course.id.to_s, :id)

      NewContentMigrationPage.date_adjust_checkbox.click
      NewContentMigrationPage.all_content_radio.click

      submit

      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      expect(opts["shift_dates"]).to be true
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
      search_for_option(NewContentMigrationPage.course_search_input_selector, new_course.name, new_course.id.to_s, :id)

      NewContentMigrationPage.date_adjust_checkbox.click
      NewContentMigrationPage.date_remove_radio.click
      NewContentMigrationPage.all_content_radio.click

      submit

      opts = @course.content_migrations.last.migration_settings["date_shift_options"]
      expect(opts["remove_dates"]).to be true
    end

    it "retains announcement content settings after course copy", priority: "2" do
      @announcement = @copy_from.announcements.create!(title: "Migration", message: "Here is my message")
      @copy_from.lock_all_announcements = true
      @copy_from.save!

      visit_page
      select_migration_type
      wait_for_ajaximations
      search_for_option(NewContentMigrationPage.course_search_input_selector, @copy_from.name, @copy_from.id.to_s, :id)
      NewContentMigrationPage.all_content_radio.click
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
      search_for_option(NewContentMigrationPage.course_search_input_selector, @copy_from.name, @copy_from.id.to_s, :id)
      NewContentMigrationPage.all_content_radio.click
      submit
      run_jobs
      # Wait until the item is imported on the back-end, otherwise the selenium tools will fail the test due to runtime
      keep_trying_until { ContentMigration.last.workflow_state == "imported" }
      @course.reload
      expect(@course.discussion_topics.last.allow_rating).to be true
    end
  end

  context "importing LTI content" do
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
      migration_type_options = NewContentMigrationPage.migration_type_options
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
      expect(NewContentMigrationPage.external_tool_launch).to be_displayed
      expect(NewContentMigrationPage.lti_select_content).to be_displayed
    end

    it "launches LTI tool on browse and get content link" do
      import_tool
      visit_page
      select_migration_type(import_tool.asset_string)
      NewContentMigrationPage.external_tool_launch_button.click
      expect(NewContentMigrationPage.lti_title(import_tool.migration_selection["text"]).text).to eq import_tool.label_for(:migration_selection)
      tool_iframe = NewContentMigrationPage.lti_iframe

      in_frame(tool_iframe, "#basic_lti_link") do
        NewContentMigrationPage.basic_lti_link.click
      end

      expect(NewContentMigrationPage.file_name_label).to include_text "lti embedded link"
    end

    it "has content selection option" do
      import_tool
      visit_page
      select_migration_type(import_tool.asset_string)
      expect(NewContentMigrationPage.selective_import_dropdown.size).to eq 2
    end
  end

  it "is able to selectively import common cartridge submodules" do
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

    NewContentMigrationPage.select_content_button.click
    wait_for_ajaximations
    NewSelectContentPage.module_parent.click
    wait_for_ajaximations
    NewSelectContentPage.module_option_caret_by_name("Your Mom, Research, & You").click
    wait_for_ajaximations
    NewSelectContentPage.module_option_checkbox_by_name("Study Guide").click
    wait_for_ajaximations
    NewSelectContentPage.import_as_standalone_module_switch_by_name("Study Guide").click
    wait_for_ajaximations
    NewSelectContentPage.submit_button.click
    wait_for_ajaximations

    run_jobs

    expect(@course.context_modules.count).to eq 1
    expect(@course.context_modules.first.name).to eq "Study Guide"
  end
end

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/helpers/context_modules_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/public_courses_context')

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon

  context 'adds existing items to modules' do
    before(:once) do
      course_factory(active_course: true)
      @course.context_modules.create! name: 'Module 1'
      @mod = @course.context_modules.first
    end

    before(:each) do
      course_with_teacher_logged_in(:course => @course, :active_enrollment => true)
    end

     it 'should add an unpublished page to a module', priority: "1", test_id: 126709 do
      @unpub_page = @course.wiki_pages.create!(title: 'Unpublished Page')
      @unpub_page.workflow_state = 'unpublished'
      @unpub_page.save!
      @mod.add_item(type: 'wiki_page', id: @unpub_page.id)
      go_to_modules
      verify_module_title('Unpublished Page')
      expect(f('span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish')).to be_displayed
     end

    it 'should add a published page to a module', priority: "1", test_id: 126710 do
      @pub_page = @course.wiki_pages.create!(title: 'Published Page')
      @mod.add_item(type: 'wiki_page', id: @pub_page.id)
      go_to_modules
      verify_module_title('Published Page')
      expect(f('span.publish-icon.published.publish-icon-published')).to be_displayed
    end

    it 'should add an unpublished quiz to a module', priority: "1", test_id: 126720 do
      @unpub_quiz = Quizzes::Quiz.create!(context: @course, title: 'Unpublished Quiz')
      @unpub_quiz.workflow_state = 'unpublished'
      @unpub_quiz.save!
      @mod.add_item(type: 'quiz', id: @unpub_quiz.id)
      go_to_modules
      verify_module_title('Unpublished Quiz')
      expect(f('span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish')).to be_displayed
    end

    it 'should add a published quiz to a module', priority: "1", test_id: 126721 do
      @pub_quiz = Quizzes::Quiz.create!(context: @course, title: 'Published Quiz')
      @mod.add_item(type: 'quiz', id: @pub_quiz.id)
      go_to_modules
      verify_module_title('Published Quiz')
      expect(f('span.publish-icon.published.publish-icon-published')).to be_displayed
    end

    it 'shows due date on a quiz in a module', priority: "2" do
      @pub_quiz = Quizzes::Quiz.create!(context: @course, title: 'Published Quiz', due_at: 2.days.from_now)
      @mod.add_item(type: 'quiz', id: @pub_quiz.id)
      go_to_modules
      expect(f('.due_date_display').text).to eq date_string(@pub_quiz.due_at, :no_words)
    end

    it 'should add an unpublished assignment to a module', priority: "1", test_id: 126724 do
      @unpub_assignment = Assignment.create!(context: @course, title: 'Unpublished Assignment')
      @unpub_assignment.workflow_state = 'unpublished'
      @unpub_assignment.save!
      @mod.add_item(type: 'assignment', id: @unpub_assignment.id)
      go_to_modules
      verify_module_title('Unpublished Assignment')
      expect(f('span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish')).to be_displayed
    end

    it 'should add a published assignment to a module', priority: "1", test_id: 126725 do
      @pub_assignment = Assignment.create!(context: @course, title: 'Published Assignment')
      @mod.add_item(type: 'assignment', id: @pub_assignment.id)
      go_to_modules
      verify_module_title('Published Assignment')
      expect(f('span.publish-icon.published.publish-icon-published')).to be_displayed
    end

    it 'should add an non-graded unpublished discussion to a module', priority: "1", test_id: 126712 do
      @unpub_ungraded_discussion = @course.discussion_topics.create!(title: 'Non-graded Unpublished Discussion')
      @unpub_ungraded_discussion.workflow_state = 'unpublished'
      @unpub_ungraded_discussion.save!
      @mod.add_item(type: 'discussion_topic', id: @unpub_ungraded_discussion.id)
      go_to_modules
      verify_module_title('Non-graded Unpublished Discussion')
      expect(f('span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish')).to be_displayed
    end

    it 'should add a non-graded published discussion to a module', priority: "1", test_id: 126713 do
      @pub_ungraded_discussion = @course.discussion_topics.create!(title: 'Non-graded Published Discussion')
      @mod.add_item(type: 'discussion_topic', id: @pub_ungraded_discussion.id)
      go_to_modules
      verify_module_title('Non-graded Published Discussion')
      expect(f('span.publish-icon.published.publish-icon-published')).to be_displayed
    end

    it 'should add an graded unpublished discussion to a module', priority: "1", test_id: 126714 do
      a = @course.assignments.create!(title: 'some assignment', points_possible: 10)
      @unpub_graded_discussion = @course.discussion_topics.build(assignment: a, title: 'Graded Unpublished Discussion')
      @unpub_graded_discussion.workflow_state = 'unpublished'
      @unpub_graded_discussion.save!
      @mod.add_item(type: 'discussion_topic', id: @unpub_graded_discussion.id)
      go_to_modules
      verify_module_title('Graded Unpublished Discussion')
      expect(f('span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish')).to be_displayed
      expect(f('.points_possible_display')).to include_text "10 pts"
    end

    it 'should add a graded published discussion to a module', priority: "1", test_id: 126715 do
      a = @course.assignments.create!(title: 'some assignment', points_possible: 10)
      @pub_graded_discussion = @course.discussion_topics.build(assignment: a, title: 'Graded Published Discussion')
      @pub_graded_discussion.save!
      @mod.add_item(type: 'discussion_topic', id: @pub_graded_discussion.id)
      go_to_modules
      verify_module_title('Graded Published Discussion')
      expect(f('span.publish-icon.published.publish-icon-published')).to be_displayed
      expect(f('.points_possible_display')).to include_text "10 pts"
    end

    it 'adds a graded published discussion with a due date to a module', priority: "1", test_id: 126716 do
      @due_at = 3.days.from_now
      a = @course.assignments.create!(title: 'some assignment', points_possible: 10, due_at: @due_at)
      @pub_graded_discussion_due = @course.discussion_topics.build(assignment: a, title: 'Graded Published Discussion with Due Date')
      @pub_graded_discussion_due.save!
      @mod.add_item(type: 'discussion_topic', id: @pub_graded_discussion_due.id)
      go_to_modules
      verify_module_title('Graded Published Discussion with Due Date')
      expect(f('span.publish-icon.published.publish-icon-published')).to be_displayed
      expect(f('.due_date_display').text).not_to be_blank
      expect(f('.due_date_display').text).to eq date_string(@due_at, :no_words)
      expect(f('.points_possible_display')).to include_text "10 pts"
    end

    it 'shows the due date on an graded discussion in a module', priority: "2", test_id: 126717 do
      due_at = 3.days.from_now
      @assignment = @course.assignments.create!(name: "assignemnt", due_at: due_at)
      @discussion = @course.discussion_topics.create!(title: 'Graded Discussion', assignment: @assignment)
      @mod.add_item(type: 'discussion_topic', id: @discussion.id)
      go_to_modules
      expect(f('.due_date_display').text).to eq date_string(due_at, :no_words)
    end

    it 'shows the todo date on an ungraded discussion in a module ', priority: "1" do
      todo_date = 1.day.from_now
      @pub_ungraded_discussion = @course.discussion_topics.create!(title: 'Non-graded Published Discussion', todo_date: todo_date)
      @mod.add_item(type: 'discussion_topic', id: @pub_ungraded_discussion.id)
      go_to_modules
      verify_module_title('Non-graded Published Discussion')
      expect(f('.due_date_display').text).to eq date_string(todo_date, :no_words)
    end

    it 'edits available/until dates on a ungraded discussion in a module', priority: "2", test_id: 126718 do
      available_from = 2.days.from_now
      available_until = 4.days.from_now
      @discussion = @course.discussion_topics.create!(title: 'Non-graded Published Discussion')
      @mod.add_item(type: 'discussion_topic', id: @discussion.id)
      go_to_modules
      fln('Non-graded Published Discussion').click
      f('.edit-btn').click
      f('input[type=text][name="delayed_post_at"]').send_keys(format_date_for_view(available_from))
      f('input[type=text][name="lock_at"]').send_keys(format_date_for_view(available_until))
      expect_new_page_load { f('.form-actions button[type=submit]').click }
      go_to_modules
      expect(f('.context_module_item')).not_to include_text(available_from.to_s)
    end

    it 'should publish assignment on publish module', priority: "2", test_id: 126719 do
      @unpub_assignment = Assignment.create!(context: @course, title: 'some assignment in a module')
      @unpub_assignment.workflow_state = 'unpublished'
      @unpub_assignment.save!
      @mod.add_item(type: 'assignment', id: @unpub_assignment.id)
      @mod.workflow_state = 'unpublished'
      @mod.save!
      go_to_modules
      verify_module_title('some assignment in a module')
      expect(ff('span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish').length).to eq(2)
      ff('.icon-unpublish')[0].click
      wait_for_ajax_requests
      expect(ff('span.publish-icon.unpublished.publish-icon-published > i.icon-publish').length).to eq(2)
    end
  end

  context 'edit inline items on module page' do
    before(:once) do
      course_factory(active_course: true)
      @course.context_modules.create! name: 'Module 2'
      @mod = @course.context_modules.first
    end

    before(:each) do
      course_with_teacher_logged_in(:course => @course, :active_enrollment => true)
    end

    it 'edit text header module item inline', priority: "2", test_id: 132487 do
      @mod.add_item(title: 'EditMe text header', type: 'sub_header')
      go_to_modules
      verify_edit_item_form
    end

    it 'edit assignment module item inline', priority: "2", test_id: 132485 do
      @edit_assignment = Assignment.create!(context: @course, title: 'EditMe Assignment')
      @mod.add_item(type: 'assignment', id: @edit_assignment.id)
      go_to_modules
      verify_edit_item_form
    end

    it 'edit quiz module item inline', priority: "2", test_id: 132486 do
      @edit_quiz = Quizzes::Quiz.create!(context: @course, title: 'EditMe Quiz')
      @mod.add_item(type: 'quiz', id: @edit_quiz.id)
      go_to_modules
      verify_edit_item_form
    end

    it 'edit content page module item inline', priority: "2", test_id: 132491 do
      @edit_page = @course.wiki_pages.create!(title: 'EditMe Page')
      @mod.add_item(type: 'wiki_page', id: @edit_page.id)
      go_to_modules
      verify_edit_item_form
    end

    it 'edit discussion module item inline', priority: "2", test_id: 132490 do
      @edit_discussion = @course.discussion_topics.create!(title: 'EditMe Discussion')
      @mod.add_item(type: 'discussion_topic', id: @edit_discussion.id)
      go_to_modules
      verify_edit_item_form
    end

    it 'edit external tool module item inline', priority: "2", test_id: 132488 do
      @edit_tool = @course.context_external_tools.create! name: 'WHAT', consumer_key: 'what', shared_secret: 'what', url: 'http://what.example.org'
      @mod.add_item(title: 'EditMe Tool', type: 'external_tool', id: @edit_tool.id, url: 'http://what.example.org/')
      go_to_modules
      verify_edit_item_form
    end

    it 'edit external URL module item inline', priority: "2", test_id: 132489 do
      go_to_modules
      add_new_external_item('External URL', 'www.google.com', 'Google')
      verify_edit_item_form
    end

    it 'editing external URL module item inline w/ load in new tab should use the right title' do
      go_to_modules

      f('.add_module_item_link').click
      wait_for_ajaximations
      select_module_item('#add_module_item_select', 'External URL')
      wait_for_ajaximations
      url_input = fj('input[name="url"]:visible')
      title_input = fj('input[name="title"]:visible')
      replace_content(url_input, 'http://www.google.com')
      title = 'Goooogle'
      replace_content(title_input, title)
      fj('input[name="new_tab"]:visible').click

      fj('.add_item_button.ui-button').click
      wait_for_ajaximations
      go_to_modules
      f('.context_module_item .al-trigger').click
      wait_for_ajaximations
      f('.edit_item_link').click
      wait_for_ajaximations
      expect(get_value('#content_tag_title')).to eq title
    end
  end

  describe "files" do
    FILE_NAME = 'some test file'

    before(:once) do
      course_factory(active_course: true)
      Account.default.enable_feature!(:usage_rights_required)
      #adding file to course
      @file = @course.attachments.create!(:display_name => FILE_NAME, :uploaded_data => default_uploaded_data)
      @file.context = @course
      @file.save!
    end

    before(:each) do
      course_with_teacher_logged_in(:course => @course, :active_enrollment => true)
    end

    it "should add a file item to a module", priority: "1", test_id: 126728 do
      get "/courses/#{@course.id}/modules"
      add_existing_module_item('#attachments_select', 'File', FILE_NAME)
    end

    it "should not remove the file link in a module when file is overwritten" do
      course_module
      @module.add_item({:id => @file.id, :type => 'attachment'})
      get "/courses/#{@course.id}/modules"

      expect(f('.context_module_item')).to include_text(FILE_NAME)
      file = @course.attachments.create!(:display_name => FILE_NAME, :uploaded_data => default_uploaded_data)
      file.context = @course
      file.save!
      Attachment.last.handle_duplicates(:overwrite)
      refresh_page
      expect(f('.context_module_item')).to include_text(FILE_NAME)
    end

    it "should set usage rights on a file in a module", priority: "1", test_id: 369251 do
      get "/courses/#{@course.id}/modules"
      make_full_screen
      add_existing_module_item('#attachments_select', 'File', FILE_NAME)
      ff('.icon-publish')[0].click
      wait_for_ajaximations
      set_value f('.UsageRightsSelectBox__select'), 'own_copyright'
      set_value f('#copyrightHolder'), 'Test User'
      f(".form-horizontal.form-dialog.permissions-dialog-form > div.form-controls > button.btn.btn-primary").click
      wait_for_ajaximations
      get "/courses/#{@course.id}/files/folder/unfiled"
      icon_class = 'icon-files-copyright'
      expect(f(".UsageRightsIndicator__openModal i.#{icon_class}")).to be_displayed
    end

    it 'edit file module item inline', priority: "2", test_id: 132492 do
      get "/courses/#{@course.id}/modules"
      add_existing_module_item('#attachments_select', 'File', FILE_NAME)
      verify_edit_item_form
    end
  end

  context "logged out", priority: "2" do
    before(:once) do
      @course = course_factory(active_all: true)
      course_module
      @course.is_public = true
      @course.save!
      @course.reload
    end

    before(:each) do
      remove_user_session
    end

    it "loads page with differentiated assignments" do
      assert_page_loads
    end
  end

  context "when a public course is accessed" do
    include_context "public course as a logged out user"

    it "should display modules list", priority: "1", test_id: 269812 do
      @module = public_course.context_modules.create!(:name => "module 1")
      @assignment = public_course.assignments.create!(:name => 'assignment 1', :assignment_group => @assignment_group)
      @module.add_item :type => 'assignment', :id => @assignment.id
      get "/courses/#{public_course.id}/modules"
      validate_selector_displayed('.item-group-container')
    end
  end
end

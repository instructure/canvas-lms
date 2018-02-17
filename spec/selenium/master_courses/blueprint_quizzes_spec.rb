#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../helpers/blueprint_common'

describe "blueprint courses quizzes" do
  include_context "in-process server selenium tests"
  include_context "blueprint courses files context"
  include BlueprintCourseCommon

  def quiz_panel
    f('.quiz')
  end

  def question_data
    {
      id: 1,
      question_type: "true_false_question",
      question_text: 'This sentence is false',
      answers: [{text: "True", weight: 100}, {text: "False", weight: 0}],
      points_possible: 10
    }.with_indifferent_access
  end

  context "in the blueprint course" do
    before :once do
      Account.default.enable_feature!(:master_courses)
      @master = course_factory(active_all: true)
      @master_teacher = @teacher
      @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
      @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course
      @minion.enroll_teacher(@master_teacher).accept!

      # sets up the quiz that gets blueprinted
      @original_quiz = @master.quizzes.create!(title: 'Discussion time!', due_at: 5.days.from_now)
      @original_quiz.description = 'this is the original content for the quiz'
      run_master_course_migration(@master)
      @copy_quiz = @minion.quizzes.last
    end

    context "as a blueprint's teacher" do
      before :each do
        user_session(@master_teacher)
      end

      it "locks down the associated course's quizzes fields", test_id: 3127593, priority: 2 do
        change_blueprint_settings(@master, points: true, due_dates: true, availability_dates: true)
        get "/courses/#{@master.id}/quizzes/#{@original_quiz.id}"
        f('.bpc-lock-toggle button').click
        expect(f('.bpc-lock-toggle__label')).to include_text('Locked')
        run_master_course_migration(@master)
        get "/courses/#{@minion.id}/quizzes/#{@copy_quiz.id}/edit"
        expect(f('#quiz_options_form')).to contain_css('.mce-tinymce.mce-container.mce-panel')
        expect(f('.bpc-lock-toggle__label')).to include_text('Locked')
        expect(f("#due_at")).to have_attribute('readonly', 'true')
        expect(f("#unlock_at")).to have_attribute('readonly', 'true')
        expect(f("#lock_at")).to have_attribute('readonly', 'true')
      end
    end
  end

  context "in the associated course" do
    before :once do
      Account.default.enable_feature!(:master_courses)

      due_date = format_date_for_view(Time.zone.now - 1.month)
      @copy_from = course_factory(:active_all => true)
      @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
      @original_quiz = @copy_from.quizzes.create!(title: "blah", description: "bloo", due_at: due_date)
      @original_quiz.quiz_questions.create! question_data: question_data
      @tag = @template.create_content_tag_for!(@original_quiz)

      course_with_teacher(:active_all => true)
      @copy_to = @course
      @template.add_child_course!(@copy_to)
      @quiz_copy = @copy_to.quizzes.new(title: "blah", description: "bloo", due_at: due_date) # just create a copy directly instead of doing a real migration
      @quiz_copy.migration_id = @tag.migration_id
      @quiz_copy.save!
      @quiz_copy.quiz_questions.create! question_data: question_data
      @quiz_copy.save!
    end

    before :each do
      user_session(@teacher)
    end

    it "should not show the cog-menu options on the index when locked" do
      @tag.update(restrictions: {all: true})

      get "/courses/#{@copy_to.id}/quizzes"

      expect(f("#summary_quiz_#{@quiz_copy.id}")).to contain_css('.icon-blueprint-lock')

      options_button.click
      expect(quiz_panel).not_to contain_css('a.delete-item')
    end

    it "should show the cog-menu options on the index when not locked" do
      get "/courses/#{@copy_to.id}/quizzes"

      expect(f("#summary_quiz_#{@quiz_copy.id}")).to contain_css('.icon-blueprint')

      options_button.click
      expect(quiz_panel).to contain_css('a.delete-item')
      expect(quiz_panel).not_to contain_css('a.delete-item.disabled')
    end

    it "should not show the edit/delete options on the show page when locked" do
      @tag.update(restrictions: {all: true})

      get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}"

      expect(f('#content')).to contain_css('.quiz-edit-button')
      options_button.click
      expect(options_panel).not_to contain_css('.delete_quiz_link')
    end

    it "should show the edit/delete cog-menu options on the show when not locked" do
      get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}"

      options_button.click
      expect(options_panel).to contain_css('.delete_quiz_link')
    end

    it "should not allow editing of restricted items" do
      @tag.update(restrictions: {content: true, points: true, due_dates: true, availability_dates: true})

      get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}/edit"

      expect(f('#quiz_edit_wrapper #quiz_title').tag_name).to eq "h1"
      expect(f('#quiz_edit_wrapper #quiz_description').tag_name).to eq "div"
      expect(f('#quiz_edit_wrapper #due_at').attribute('readonly')).to eq "true"
    end

    it "should prevent editing/deleting questions if content is locked" do
      @tag.update(restrictions: {content: true, points: true, due_dates: true, availability_dates: true})

      get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}/edit"

      # open the questions tab
      hover_and_click('#quiz_tabs_tab_list li[aria-controls="questions_tab"]')
      expect(f('#quiz_edit_wrapper #questions_tab').displayed?).to eq  true

      # hover the question description and the edit/pencil link should not appear
      hover(f('.question_text'))
      expect(f('.question_holder')).not_to contain_css('.edit_question_link')
      expect(f('.question_holder')).not_to contain_css('.delete_question_link')

      # check buttons on the bottom of the page
      tab = f('#questions_tab')
      expect(tab).not_to contain_css('.add_question_link')
      expect(tab).not_to contain_css('.add_question_group_link')
      expect(tab).not_to contain_css('.find_question_link')
    end

    it "should allow editing/deleting questions if content/points are not locked" do
      # this test is here mostly to validate that the previous test is valid,
      # since it's looking "not_to contain_css('.edit_question_link')", I better
      # have a test to prove what's not supposed to be there is there when it's supposed to be
      @tag.update(restrictions: {content: false, points: false, due_dates: true, availability_dates: true})

      get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}/edit"

      # open the questions tab
      hover_and_click('#quiz_tabs_tab_list li[aria-controls="questions_tab"]')
      expect(f('#quiz_edit_wrapper #questions_tab').displayed?).to eq  true

      # hover the question description and the edit/pencil link should not appear
      hover(f('.question_text'))
      expect(f('.question_holder')).to contain_css('.edit_question_link')
      expect(f('.question_holder')).to contain_css('.delete_question_link')

      # check buttons on the bottom of the page
      tab = f('#questions_tab')
      expect(tab).to contain_css('.add_question_link')
      expect(tab).to contain_css('.add_question_group_link')
      expect(tab).to contain_css('.find_question_link')
    end

    it "prevents deleting questions or editing points possible if points are locked but content isn't" do
      @tag.update(restrictions: {content: false, points: true, due_dates: true, availability_dates: true})

      get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}/edit"

      hover_and_click('#quiz_tabs_tab_list li[aria-controls="questions_tab"]')
      expect(f('#quiz_edit_wrapper #questions_tab').displayed?).to eq  true

      # questions can be edited but not deleted
      hover(f('.question_text'))
      expect(f('.question_holder')).to contain_css('.edit_question_link')
      expect(f('.question_holder')).not_to contain_css('.delete_question_link')

      # points field should be readonly
      hover_and_click('.question_holder .edit_question_link')
      expect(f('input[name="question_points"]')).to have_attribute('readonly')
    end

  end

  context "question groups in associated course" do
    before :once do
      Account.default.enable_feature!(:master_courses)

      due_date = format_date_for_view(Time.zone.now - 1.month)
      @copy_from = course_factory(:active_all => true)
      @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
      @original_quiz = @copy_from.quizzes.create!(title: "blah", description: "bloo", due_at: due_date)
      original_group = @original_quiz.quiz_groups.create! :name => "Eh", :pick_count => 1, :question_points => 10
      original_group.quiz_questions.create! quiz: @original_quiz, question_data: question_data
      @tag = @template.create_content_tag_for!(@original_quiz)

      course_with_teacher(:active_all => true)
      @copy_to = @course
      @template.add_child_course!(@copy_to)
      @quiz_copy = @copy_to.quizzes.create!(title: "blah", description: "bloo", due_at: due_date) # just create a copy directly instead of doing a real migration
      @quiz_copy.migration_id = @tag.migration_id
      @quiz_copy.save!
      copy_group = @quiz_copy.quiz_groups.create! :name => "Eh", :pick_count => 1, :question_points => 10
      copy_group.quiz_questions.create! quiz: @quiz_copy, question_data: question_data
    end

    before :each do
      user_session(@teacher)
    end

    it "allows editing/deleting the quiz group when nothing is locked" do
      get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}/edit"
      hover_and_click('#quiz_tabs_tab_list li[aria-controls="questions_tab"]')
      expect(f('#quiz_edit_wrapper #questions_tab').displayed?).to eq  true

      expect(f('.group_top')).to contain_css('.delete_group_link')
      f('.group_top .edit_group_link').click
      expect(f('.quiz_group_form input[name="quiz_group[question_points]"]')).not_to have_attribute('readonly')
      expect(f('.quiz_group_form input[name="quiz_group[pick_count]"]')).not_to have_attribute('readonly')
    end

    it "prevents deleting group or changing pick count/points per question when points are locked" do
      @tag.update(restrictions: {content: false, points: true, due_dates: true, availability_dates: true})

      get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}/edit"
      hover_and_click('#quiz_tabs_tab_list li[aria-controls="questions_tab"]')
      expect(f('#quiz_edit_wrapper #questions_tab').displayed?).to eq  true

      expect(f('.group_top')).not_to contain_css('.delete_group_link')
      f('.group_top .edit_group_link').click
      expect(f('.quiz_group_form input[name="quiz_group[question_points]"]')).to have_attribute('readonly')
      expect(f('.quiz_group_form input[name="quiz_group[pick_count]"]')).to have_attribute('readonly')
    end

    it "disallows editing the quiz group when content is locked" do
      @tag.update(restrictions: {content: true, points: true, due_dates: true, availability_dates: true})

      get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}/edit"
      hover_and_click('#quiz_tabs_tab_list li[aria-controls="questions_tab"]')
      expect(f('#quiz_edit_wrapper #questions_tab').displayed?).to eq  true

      expect(f('.group_top')).not_to contain_css('.edit_group_link')
      expect(f('.group_top')).not_to contain_css('.delete_group_link')
    end

  end
end

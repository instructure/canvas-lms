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

require_relative '../common'

describe "master courses - child courses - quiz locking" do
  include_context "in-process server selenium tests"

  before :once do
    Account.default.enable_feature!(:master_courses)

    qd = { question_type: "text_only_question", id: 1, question_name: 'the hardest question ever'}.with_indifferent_access
    due_date = format_date_for_view(Time.zone.now - 1.month)
    @copy_from = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @original_quiz = @copy_from.quizzes.create!(:title => "blah", :description => "bloo", :due_at => due_date)
    @original_quiz.quiz_questions.create! question_data: qd
    @tag = @template.create_content_tag_for!(@original_quiz)

    course_with_teacher(:active_all => true)
    @copy_to = @course
    @template.add_child_course!(@copy_to)
    @quiz_copy = @copy_to.quizzes.new(:title => "blah", :description => "bloo", :due_at => due_date) # just create a copy directly instead of doing a real migration
    @quiz_copy.migration_id = @tag.migration_id
    @quiz_copy.save!
    @quiz_copy.quiz_questions.create! question_data: qd
    @quiz_copy.save!
  end

  before :each do
    user_session(@teacher)
  end

  it "should not show the cog-menu options on the index when locked" do
    @tag.update_attribute(:restrictions, {:all => true})

    get "/courses/#{@copy_to.id}/quizzes"

    expect(f("#summary_quiz_#{@quiz_copy.id}")).to contain_css('.icon-blueprint-lock')

    f('.quiz .al-trigger').click
    expect(f('.quiz')).not_to contain_css('a.delete-item')
  end

  it "should show the cog-menu options on the index when not locked" do
    get "/courses/#{@copy_to.id}/quizzes"

    expect(f("#summary_quiz_#{@quiz_copy.id}")).to contain_css('.icon-blueprint')

    f('.quiz .al-trigger').click
    expect(f('.quiz')).to contain_css('a.delete-item')
    expect(f('.quiz')).not_to contain_css('a.delete-item.disabled')
  end

  it "should not show the edit/delete options on the show page when locked" do
    @tag.update_attribute(:restrictions, {:all => true})

    get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}"

    expect(f('#content')).to contain_css('.quiz-edit-button')
    f('.al-trigger').click
    expect(f('.al-options')).not_to contain_css('.delete_quiz_link')
  end

  it "should show the edit/delete cog-menu options on the show when not locked" do
    get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}"

    f('.al-trigger').click
    expect(f('.al-options')).to contain_css('.delete_quiz_link')
  end

  it "should not allow editing of restricted items" do
    @tag.update_attribute(:restrictions, {:content => true, :points => true, :due_dates => true, :availability_dates => true})

    get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}/edit"

    expect(f('#quiz_edit_wrapper #quiz_title').tag_name).to eq "h1"
    expect(f('#quiz_edit_wrapper #quiz_description').tag_name).to eq "div"
    expect(f('#quiz_edit_wrapper #due_at').attribute('readonly')).to eq "true"
  end

  it "should prevent editing questions if content is locked" do
    @tag.update_attribute(:restrictions, {:content => true, :points => true, :due_dates => true, :availability_dates => true})

    get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}/edit"

    # open the questions tab
    hover_and_click('#quiz_tabs_tab_list li[aria-controls="questions_tab"]')
    expect(f('#quiz_edit_wrapper #questions_tab').displayed?).to eq  true

    # hover the question description and the edit/pencil link should not appear
    hover(f('.question_text'))
    expect(f('.question_holder')).not_to contain_css('.edit_question_link')
  end

  it "should allow editing questions if content is not locked" do
    # this test is here mostly to validate that the previous test is valid,
    # since it's looking "not_to contain_css('.edit_question_link')", I better
    # have a test to prove what's not supposed to be there is there when it's supposed to be
    @tag.update_attribute(:restrictions, {:content => false, :points => true, :due_dates => true, :availability_dates => true})

    get "/courses/#{@copy_to.id}/quizzes/#{@quiz_copy.id}/edit"

    # open the questions tab
    hover_and_click('#quiz_tabs_tab_list li[aria-controls="questions_tab"]')
    expect(f('#quiz_edit_wrapper #questions_tab').displayed?).to eq  true

    # hover the question description and the edit/pencil link should not appear
    hover(f('.question_text'))
    expect(f('.question_holder')).to contain_css('.edit_question_link')
  end
end

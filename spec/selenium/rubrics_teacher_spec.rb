#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/helpers/rubrics_common')

describe "teacher shared rubric specs" do
  include_context "in-process server selenium tests"
  include RubricsCommon

  let(:rubric_url) { "/courses/#{@course.id}/rubrics" }
  let(:who_to_login) { 'teacher' }

  before(:each) do
    resize_screen_to_normal
    course_with_teacher_logged_in
  end

  it "should delete a rubric" do
    should_delete_a_rubric
  end

  it "should edit a rubric" do
    should_edit_a_rubric
  end

  it "should allow fractional points" do
    should_allow_fractional_points
  end

  it "should round to 2 decimal places" do
    should_round_to_2_decimal_places
  end

  it "should round to an integer when splitting" do
    resize_screen_to_default
    should_round_to_an_integer_when_splitting
  end

  it "should pick the lower value when splitting without room for an integer" do
    skip('fragile - need to refactor split_ratings method')
    should_pick_the_lower_value_when_splitting_without_room_for_an_integer
  end
end

describe "course rubrics" do
  include_context "in-process server selenium tests"
  include RubricsCommon

  context "as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
    end

    it "should ignore outcome rubric lines when calculating total" do
      outcome_with_rubric
      @assignment = @course.assignments.create(:name => 'assignment with rubric')
      @association = @rubric.associate_with(@assignment, @course, :use_for_grading => true, :purpose => 'grading')
      @rubric.data[0][:ignore_for_scoring] = '1'
      @rubric.points_possible = 5
      @rubric.save!

      get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
      expect(f('.rubric_total')).to include_text "5"

      f('#right-side .edit_rubric_link').click
      criterion_points = fj(".criterion_points:visible")
      replace_content(criterion_points, "10")
      criterion_points.send_keys(:return)
      submit_form("#edit_rubric_form")
      wait_for_ajaximations
      expect(fj('.rubric_total')).to include_text "10"

      # check again after reload
      refresh_page
      expect(fj('.rubric_total')).to include_text "10" #avoid selenium caching
    end

    it "should not display the edit form more than once" do
      rubric_association_model(:user => @user, :context => @course, :purpose => "grading")

      get "/courses/#{@course.id}/rubrics/#{@rubric.id}"

      2.times { |n| f('#right-side .edit_rubric_link').click }
      expect(ff('.rubric .ic-Action-header').length).to eq 1
    end

    it "should import a rubric outcome row" do
      rubric_association_model(:user => @user, :context => @course, :purpose => "grading")
      outcome_model(:context => @course)

      get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
      wait_for_ajaximations
      import_outcome

      expect(f('tr.learning_outcome_criterion .criterion_description .description').text).to eq @outcome.title
      expect(ff('tr.learning_outcome_criterion td.rating .description').map(&:text)).to eq @outcome.data[:rubric_criterion][:ratings].map { |c| c[:description] }
      expect(ff('tr.learning_outcome_criterion td.rating .points').map(&:text)).to eq @outcome.data[:rubric_criterion][:ratings].map { |c| round_if_whole(c[:points]).to_s }
      # important to check this both before and after submit, thanks to the super janky
      # way edit_rubric.js and the .erb template work
      expect(f('tr.learning_outcome_criterion .outcome_sr_content')).to have_attribute('aria-hidden', 'false')
      submit_form('#edit_rubric_form')
      wait_for_ajaximations
      rubric = Rubric.order(:id).last
      expect(f('tr.learning_outcome_criterion .outcome_sr_content')).to have_attribute('aria-hidden', 'false')
      expect(rubric.data.first[:ratings].map { |r| r[:description] }).to eq @outcome.data[:rubric_criterion][:ratings].map { |c| c[:description] }
      expect(rubric.data.first[:ratings].map { |r| r[:points] }).to eq @outcome.data[:rubric_criterion][:ratings].map { |c| c[:points] }
    end

    it "should not allow editing a criterion row linked to an outcome" do
      rubric_association_model(:user => @user, :context => @course, :purpose => "grading")
      outcome_model(:context => @course)
      rubric = Rubric.last

      get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
      wait_for_ajaximations
      import_outcome

      f('#right-side .edit_rubric_link').click
      wait_for_ajaximations

      links = ffj("#rubric_#{rubric.id}.editing .ratings:first .edit_rating_link")
      expect(links.any?(&:displayed?)).to be_falsey

      # pts should not be editable
      expect(f('tr.learning_outcome_criterion .points_form .editing').displayed?).to be_falsey
      expect(f('tr.learning_outcome_criterion .points_form .displaying').displayed?).to be_truthy
    end

    it "should not show 'use for grading' as an option" do
      course_with_teacher_logged_in
      get "/courses/#{@course.id}/rubrics"
      f('.add_rubric_link').click
      expect(fj('.rubric_grading:hidden')).not_to be_nil
    end

  end

  it "should display free-form comments to the student" do
    assignment_model
    rubric_model(:context => @course, :free_form_criterion_comments => true)
    course_with_student(:course => @course, :active_all => true)
    @course.offer!
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
    comment = "Hi, please see www.example.com"
    @assessment = @association.assess({
                                          :user => @student,
                                          :assessor => @teacher,
                                          :artifact => @assignment.find_or_create_submission(@student),
                                          :assessment => {
                                              :assessment_type => 'grading',
                                              :criterion_crit1 => {
                                                  :points => nil,
                                                  :comments => comment,
                                              }
                                          }
                                      })
    user_logged_in(:user => @student)

    get "/courses/#{@course.id}/grades"
    f('.toggle_rubric_assessments_link').click
    expect(f('.rubric .criterion .custom_rating_comments')).to include_text comment
    expect(f('.rubric .criterion .custom_rating_comments a')).to have_attribute('href', 'http://www.example.com/')

    get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
    f('.assess_submission_link').click
    expect(f('.rubric .criterion .custom_rating_comments')).to include_text comment
    expect(f('.rubric .criterion .custom_rating_comments a')).to have_attribute('href', 'http://www.example.com/')
  end

  it "should highlight a criterion level if score is 0" do
    assignment_model
    rubric_model(:context => @course)
    course_with_student(:course => @course, :active_all => true)
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
    @assessment = @association.assess({
                                          :user => @student,
                                          :assessor => @teacher,
                                          :artifact => @assignment.find_or_create_submission(@student),
                                          :assessment => {
                                              :assessment_type => 'grading',
                                              :criterion_crit1 => {
                                                  :points => 0
                                              }
                                          }
                                      })
    user_logged_in(:user => @student)

    get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
    f('.assess_submission_link').click
    wait_for_ajaximations
    expect(f('table .ratings tbody td:nth-child(3)')).to have_class('original_selected')
  end

  it "should not highlight a criterion level if score is nil" do
    assignment_model
    rubric_model(:context => @course)
    course_with_student(:course => @course, :active_all => true)
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
    @assessment = @association.assess({
                                          :user => @student,
                                          :assessor => @teacher,
                                          :artifact => @assignment.find_or_create_submission(@student),
                                          :assessment => {
                                              :assessment_type => 'grading',
                                              :criterion_crit1 => {
                                                  :points => nil
                                              }
                                          }
                                      })
    user_logged_in(:user => @student)

    get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
    f('.assess_submission_link').click
    wait_for_ajaximations
    expect(f('table .ratings tbody td:nth-child(3)')).not_to have_class('original_selected')
  end
end

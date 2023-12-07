# frozen_string_literal: true

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

require_relative "../../helpers/rubrics_common"

describe "teacher shared rubric specs" do
  include_context "in-process server selenium tests"
  include RubricsCommon

  let(:rubric_url) { "/courses/#{@course.id}/rubrics" }
  let(:who_to_login) { "teacher" }

  before do
    Account.site_admin.disable_feature!(:enhanced_rubrics)
    course_with_teacher_logged_in
  end

  it "deletes a rubric" do
    should_delete_a_rubric
  end

  it "edits a rubric" do
    should_edit_a_rubric
  end

  it "allows fractional points" do
    should_allow_fractional_points
  end

  it "rounds to 2 decimal places" do
    should_round_to_2_decimal_places
  end

  it "rounds to an integer when splitting" do
    should_round_to_an_integer_when_splitting
  end
end

describe "course rubrics" do
  include_context "in-process server selenium tests"
  include RubricsCommon

  context "as a teacher" do
    before do
      Account.site_admin.disable_feature!(:enhanced_rubrics)
      course_with_teacher_logged_in
    end

    it "ignores outcome rubric lines when calculating total" do
      outcome_with_rubric
      @assignment = @course.assignments.create(name: "assignment with rubric")
      @association = @rubric.associate_with(@assignment, @course, use_for_grading: true, purpose: "grading")
      @rubric.data[0][:ignore_for_scoring] = "1"
      @rubric.points_possible = 5
      @rubric.save!

      get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
      expect(f(".rubric_total")).to include_text "5"

      f("#rubric-action-buttons .edit_rubric_link").click
      criterion_points = fj(".criterion_points:visible")
      replace_content(criterion_points, "10")
      criterion_points.send_keys(:return)
      submit_form("#edit_rubric_form")
      wait_for_ajaximations
      expect(fj(".rubric_total")).to include_text "10"

      # check again after reload
      refresh_page
      expect(fj(".rubric_total")).to include_text "10" # avoid selenium caching
    end

    it "calculates ratings based on initial rating values" do
      assignment_with_editable_rubric(10)
      get "/courses/#{@course.id}/rubrics/#{@rubric.id}"

      f("#rubric-action-buttons .edit_rubric_link").click
      replace_content(fj(".criterion_points:visible"), "50")
      fj(".criterion_points:visible").send_keys(:return)
      expect(ff(".points").map(&:text).reject!(&:empty?)).to eq %w[50 15 0]

      replace_content(fj(".criterion_points:visible"), "25")
      fj(".criterion_points:visible").send_keys(:return)
      expect(ff(".points").map(&:text).reject!(&:empty?)).to eq ["25", "7.5", "0"]

      replace_content(fj(".criterion_points:visible"), "10")
      fj(".criterion_points:visible").send_keys(:return)
      submit_form("#edit_rubric_form")
      expect(ff(".points").map(&:text).reject!(&:empty?)).to eq %w[10 3 0]
    end

    it "does not show an error when adjusting from 0 points" do
      assignment_with_editable_rubric(0)
      get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
      f("#rubric-action-buttons .edit_rubric_link").click
      replace_content(fj(".criterion_points:visible"), "10")
      fj(".criterion_points:visible").send_keys(:return)
      submit_form("#edit_rubric_form")
      expect(ff(".points").map(&:text).reject!(&:empty?)).to eq %w[10 5 0]
    end

    it "does not display the edit form more than once" do
      rubric_association_model(user: @user, context: @course, purpose: "grading")

      get "/courses/#{@course.id}/rubrics/#{@rubric.id}"

      2.times { f("#rubric-action-buttons .edit_rubric_link").click }
      expect(ff(".rubric .ic-Action-header").length).to eq 1
    end

    it "imports a rubric outcome row" do
      rubric_association_model(user: @user, context: @course, purpose: "grading")
      outcome_model(context: @course)

      get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
      wait_for_ajaximations
      import_outcome

      expect(f("tr.learning_outcome_criterion .criterion_description .description").text).to eq @outcome.title
      expect(ff("tr.learning_outcome_criterion td.rating .description").map(&:text)).to eq @outcome.data[:rubric_criterion][:ratings].pluck(:description)
      expect(ff("tr.learning_outcome_criterion td.rating .points").map(&:text)).to eq(@outcome.data[:rubric_criterion][:ratings].map { |c| round_if_whole(c[:points]).to_s })
      # important to check this both before and after submit, thanks to the super janky
      # way edit_rubric.js and the .erb template work
      expect(f("tr.learning_outcome_criterion .outcome_sr_content")).to have_attribute("aria-hidden", "false")
      submit_form("#edit_rubric_form")
      wait_for_ajaximations
      rubric = Rubric.order(:id).last
      expect(f("tr.learning_outcome_criterion .outcome_sr_content")).to have_attribute("aria-hidden", "false")
      expect(rubric.data.first[:ratings].pluck(:description)).to eq @outcome.data[:rubric_criterion][:ratings].pluck(:description)
      expect(rubric.data.first[:ratings].pluck(:points)).to eq @outcome.data[:rubric_criterion][:ratings].pluck(:points)
    end

    it "does not allow editing a criterion row linked to an outcome" do
      rubric_association_model(user: @user, context: @course, purpose: "grading")
      outcome_model(context: @course)
      rubric = Rubric.last

      get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
      wait_for_ajaximations
      import_outcome

      f("#rubric-action-buttons .edit_rubric_link").click
      wait_for_ajaximations

      links = ffj("#rubric_#{rubric.id}.editing .ratings:first .edit_rating_link")
      expect(links.any?(&:displayed?)).to be_falsey

      # pts should not be editable
      expect(f("tr.learning_outcome_criterion .points_form .editing").displayed?).to be_falsey
      expect(f("tr.learning_outcome_criterion .points_form .displaying").displayed?).to be_truthy
    end

    it "does not show 'use for grading' as an option" do
      course_with_teacher_logged_in
      get "/courses/#{@course.id}/rubrics"
      f(".add_rubric_link").click
      expect(fj(".rubric_grading:hidden")).not_to be_nil
    end

    it "displays integer and float ratings" do
      assignment_with_editable_rubric(2)
      get "/courses/#{@course.id}/rubrics/#{@rubric.id}"

      expect(ff(".points").map(&:text).reject!(&:empty?)).to eq ["2", "0.6", "0"]
      expect(ff(".display_criterion_points").map(&:text).reject!(&:empty?)).to eq ["2"]
      expect(f("#rubrics span .rubric_total").text).to eq "2"
    end

    context "with the account_level_mastery_scales FF enabled" do
      before do
        @course.account.enable_feature!(:account_level_mastery_scales)
      end

      it "uses the account outcome proficiency for mastery scales if one exists" do
        proficiency = outcome_proficiency_model(@course.account)
        rubric_association_model(user: @user, context: @course, purpose: "grading")
        outcome_model(context: @course)

        get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
        wait_for_ajaximations
        import_outcome
        points = proficiency.outcome_proficiency_ratings.map { |rating| round_if_whole(rating.points).to_s }
        expect(ff("tr.learning_outcome_criterion td.rating .points").map(&:text)).to eq points
      end

      it "defaults to the the default account proficiency if no outcome proficiecy exists" do
        rubric_association_model(user: @user, context: @course, purpose: "grading")
        outcome_model(context: @course)

        get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
        wait_for_ajaximations
        import_outcome
        points = OutcomeProficiency.find_or_create_default!(@course.account).outcome_proficiency_ratings.map do |rating|
          round_if_whole(rating.points).to_s
        end
        expect(ff("tr.learning_outcome_criterion td.rating .points").map(&:text)).to eq points
      end

      it "rubrics are updated after mastery scales are modified" do
        current_proficiency = OutcomeProficiency.find_or_create_default!(@course.account)
        rubric_association_model(user: @user, context: @course, purpose: "grading")
        outcome_model(context: @course)

        get "/courses/#{@course.id}/rubrics/#{@rubric.id}"
        wait_for_ajaximations
        import_outcome
        current_points = current_proficiency.outcome_proficiency_ratings.map { |rating| rating.points.to_f }
        # checks if they are equal after adding outcome
        expect(ff("tr.learning_outcome_criterion td.rating .points").map { |e| e.text.to_f }).to eq current_points
        submit_form("#edit_rubric_form")
        wait_for_ajaximations
        # check if they are equal after submission
        expect(ff("tr.learning_outcome_criterion td.rating .points").map { |e| e.text.to_f }).to eq current_points

        # Update proficiency's first rating with new point value of 30
        ratings_hash_map = current_proficiency.ratings_hash
        ratings_hash_map[0][:points] = 30.0
        current_proficiency.replace_ratings(ratings_hash_map)
        current_proficiency.save!

        refresh_page
        wait_for_ajaximations
        updated_points = current_proficiency.outcome_proficiency_ratings.map { |rating| rating.points.to_f }
        # checks if they are equal after update
        expect(ff("tr.learning_outcome_criterion td.rating .points").map { |e| e.text.to_f }).to eq updated_points
      end
    end
  end

  it "displays free-form comments to the student" do
    assignment_model
    rubric_model(context: @course, free_form_criterion_comments: true)
    course_with_student(course: @course, active_all: true)
    @course.offer!
    @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
    comment = "Hi, please see www.example.com"
    @assessment = @association.assess({
                                        user: @student,
                                        assessor: @teacher,
                                        artifact: @assignment.find_or_create_submission(@student),
                                        assessment: {
                                          assessment_type: "grading",
                                          criterion_crit1: {
                                            points: nil,
                                            comments: comment,
                                          }
                                        }
                                      })
    user_logged_in(user: @student)

    get "/courses/#{@course.id}/grades"
    f(".toggle_rubric_assessments_link").click
    expect(f(".rubric-freeform")).to include_text comment
    expect(f(".rubric-freeform a")).to have_attribute("href", "http://www.example.com/")

    get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
    f(".assess_submission_link").click
    expect(f(".rubric-freeform")).to include_text comment
    expect(f(".rubric-freeform a")).to have_attribute("href", "http://www.example.com/")
  end

  it "highlights a criterion level if score is 0" do
    assignment_model
    rubric_model(context: @course)
    course_with_student(course: @course, active_all: true)
    @course.offer!
    @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
    @assessment = @association.assess({
                                        user: @student,
                                        assessor: @teacher,
                                        artifact: @assignment.find_or_create_submission(@student),
                                        assessment: {
                                          assessment_type: "grading",
                                          criterion_crit1: {
                                            points: 0
                                          }
                                        }
                                      })
    user_logged_in(user: @student)

    get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
    f(".assess_submission_link").click
    wait_for_ajaximations
    expect(ff('tr[data-testid="rubric-criterion"]:nth-of-type(1) .rating-tier').third).to have_class("selected")
  end

  it "does not highlight a criterion level if score is nil" do
    assignment_model
    rubric_model(context: @course)
    course_with_student(course: @course, active_all: true)
    @course.offer!
    @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
    @assessment = @association.assess({
                                        user: @student,
                                        assessor: @teacher,
                                        artifact: @assignment.find_or_create_submission(@student),
                                        assessment: {
                                          assessment_type: "grading",
                                          criterion_crit1: {
                                            points: nil
                                          }
                                        }
                                      })
    user_logged_in(user: @student)

    get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
    f(".assess_submission_link").click
    wait_for_ajaximations
    ff('tr[data-testid="rubric-criterion"]:nth-of-type(1) .rating-tier').each do |criterion|
      expect(criterion).not_to have_class("selected")
    end
  end
end

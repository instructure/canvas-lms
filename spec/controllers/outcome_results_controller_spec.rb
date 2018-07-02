#
# Copyright (C) 2015 - present Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OutcomeResultsController do
  def context_outcome(context)
    @outcome_group = context.root_outcome_group
    @outcome = context.created_learning_outcomes.create!(:title => 'outcome')
    @outcome_group.add_outcome(@outcome)
  end

  before :once do
    @account = Account.default
    account_admin_user
  end

  let_once(:outcome_course) do
    course_factory(active_all: true)
    @course
  end

  let_once(:outcome_teacher) do
    teacher_in_course(active_all: true, course: outcome_course)
    @teacher
  end

  let_once(:outcome_student) do
    student_in_course(active_all: true, course: outcome_course)
    @student
  end

  let_once(:outcome_rubric) do
    create_outcome_rubric
  end

  let_once(:outcome_assignment) do
    assignment = create_outcome_assignment
    find_or_create_outcome_submission assignment: assignment
    assignment
  end

  let_once(:outcome_rubric_association) do
    create_outcome_rubric_association
  end

  let_once(:outcome_result) do
    rubric_association = outcome_rubric.associate_with(outcome_assignment, outcome_course, purpose: 'grading')

    LearningOutcomeResult.new(
      user_id: @student.id,
      alignment: ContentTag.create!({
        title: 'content',
        context: outcome_course,
        learning_outcome: @outcome,
        content_type: 'Assignment',
        content_id: outcome_assignment.id
      })
    ).tap do |lor|
      lor.association_object = rubric_association
      lor.context = outcome_course
      lor.save!
    end
  end

  let(:outcome_criterion) do
    find_outcome_criterion
  end

  def find_or_create_outcome_submission(opts = {})
    student = opts[:student] || outcome_student
    assignment = opts[:assignment] ||
      (create_outcome_assignment if opts[:new]) ||
      outcome_assignment
    assignment.find_or_create_submission(student)
  end

  def create_outcome_assessment(opts = {})
    association = (create_outcome_rubric_association(opts) if opts[:new]) ||
      outcome_rubric_association
    criterion = find_outcome_criterion(association.rubric)
    submission = opts[:submission] || find_or_create_outcome_submission(opts)
    student = submission.student
    points = opts[:points] ||
      find_first_rating(criterion)[:points]
    association.assess(
      user: student,
      assessor: outcome_teacher,
      artifact: submission,
      assessment: {
        assessment_type: 'grading',
        "criterion_#{criterion[:id]}".to_sym => {
          points: points
        }
      }
    )
  end

  def create_outcome_rubric
    outcome_course
    outcome_with_rubric(mastery_points: 3)
    @outcome.rubric_criterion = find_outcome_criterion(@rubric)
    @outcome.save
    @rubric
  end

  def create_outcome_assignment
    outcome_course.assignments.create!(
      title: "outcome assignment",
      description: "this is an outcome assignment",
      points_possible: outcome_rubric.points_possible,
    )
  end

  def create_outcome_rubric_association(opts = {})
    rubric = (create_outcome_rubric if opts[:new]) ||
      outcome_rubric
    assignment = (create_outcome_assignment if opts[:new]) ||
      outcome_assignment
    rubric.associate_with(assignment, outcome_course, purpose: 'grading', use_for_grading: true)
  end

  def find_outcome_criterion(rubric = outcome_rubric)
    rubric.criteria.find {|c| !c[:learning_outcome_id].nil? }
  end

  def find_first_rating(criterion = outcome_criterion)
    criterion[:ratings].first
  end

  describe "retrieving outcome results" do
    it "should not have a false failure if an outcome exists in two places " +
      "within the same context" do
      user_session(@teacher)
      outcome_group = @course.root_outcome_group.child_outcome_groups.build(
                        :title => "Child outcome group", :context => @course)
      outcome_group.save!
      outcome_group.add_outcome(@outcome)
      get 'rollups', params: {:context_id => @course.id,
                      :course_id => @course.id,
                      :context_type => "Course",
                      :user_ids => [@student.id],
                      :outcome_ids => [@outcome.id]},
                      format: "json"
      expect(response).to be_successful
    end

    it 'should validate aggregate_stat parameter' do
      user_session(@teacher)
      get 'rollups', params: {:context_id => @course.id,
                      :course_id => @course.id,
                      :context_type => "Course",
                      aggregate: 'course',
                      aggregate_stat: 'powerlaw'},
                      format: "json"
      expect(response).not_to be_success
    end

    context 'with muted assignment' do
      before do
        outcome_assignment.mute!
      end

      it 'teacher should see result' do
        user_session(@teacher)
        get 'index', params: {:context_id => @course.id,
                        :course_id => @course.id,
                        :context_type => "Course",
                        :user_ids => [@student.id],
                        :outcome_ids => [@outcome.id]},
                        format: "json"
        json = JSON.parse(response.body.gsub("while(1);", ""))
        expect(json['outcome_results'].length).to eq 1
      end

      it 'student should not see result' do
        user_session(@student)
        get 'index', params: {:context_id => @course.id,
                        :course_id => @course.id,
                        :context_type => "Course",
                        :user_ids => [@student.id],
                        :outcome_ids => [@outcome.id]},
                        format: "json"
        json = JSON.parse(response.body.gsub("while(1);", ""))
        expect(json['outcome_results'].length).to eq 0
      end
    end

    it 'exclude missing user rollups' do
      user_session(@teacher)
      # save a reference to the 1st student
      student1 = @student
      # create a 2nd student that is saved as @student
      student_in_course(active_all: true, course: outcome_course)
      get 'rollups', params: {:context_id => @course.id,
                      :course_id => @course.id,
                      :context_type => "Course",
                      :user_ids => [student1.id, @student.id],
                      :outcome_ids => [@outcome.id],
                      exclude: ['missing_user_rollups']},
                      format: "json"
      json = JSON.parse(response.body.gsub("while(1);", ""))
      # the rollups requests for both students, but excludes the 2nd student
      # since they do not have any results, unlike the 1st student,
      # which has a single result in `outcome_result`
      expect(json['rollups'].length).to be 1
    end
  end
end

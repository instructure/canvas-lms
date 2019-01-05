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
    student_in_course(active_all: true, course: outcome_course, name: 'Zebra Animal')
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
    create_result(@student.id, @outcome, outcome_assignment, 3)
  end

  let(:outcome_criterion) do
    find_outcome_criterion
  end

  def create_result(user_id, outcome, assignment, score)
    rubric_association = outcome_rubric.associate_with(outcome_assignment, outcome_course, purpose: 'grading')

    LearningOutcomeResult.new(
      user_id: user_id,
      score: score,
      alignment: ContentTag.create!({
        title: 'content',
        context: outcome_course,
        learning_outcome: outcome,
        content_type: 'Assignment',
        content_id: assignment.id
      })
    ).tap do |lor|
      lor.association_object = rubric_association
      lor.context = outcome_course
      lor.save!
    end
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

  def parse_response(response)
    JSON.parse(response.body.gsub("while(1);", ""))
  end

  describe "retrieving outcome results" do
    it "should not have a false failure if an outcome exists in two places " \
      "within the same context" do
      user_session(@teacher)
      outcome_group = @course.root_outcome_group.child_outcome_groups.build(
        :title => "Child outcome group", :context => @course
      )
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
        json = parse_response(response)
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
      json = parse_response(response)
      # the rollups requests for both students, but excludes the 2nd student
      # since they do not have any results, unlike the 1st student,
      # which has a single result in `outcome_result`
      expect(json['rollups'].length).to be 1

      # the pagination count should be 1 for the one student with a rollup
      expect(json['meta']['pagination']['count']).to be 1
    end
  end

  describe "retrieving outcome rollups" do
    before do
      @student1 = @student
      @student2 = student_in_course(active_all: true, course: outcome_course, name: 'Amy Mammoth').user
      @student3 = student_in_course(active_all: true, course: outcome_course, name: 'Barney Youth').user

      create_result(@student2.id, @outcome, outcome_assignment, 1)
    end

    before :each do
      user_session(@teacher)
    end

    def get_rollups(params)
      get 'rollups', params: {
          :context_id => @course.id,
          :course_id => @course.id,
          :context_type => "Course",
          **params
        },
        format: "json"
    end

    it 'includes rating percents' do
      json = parse_response(get_rollups(rating_percents: true, include: ['outcomes']))
      expect(json['linked']['outcomes'][0]['ratings'].map { |r| r['percent'] }).to eq [50, 50]
    end

    context 'sorting' do
      it 'should validate sort_by parameter' do
        get_rollups(sort_by: 'garbage')
        expect(response).not_to be_success
      end

      it 'should validate sort_order parameter' do
        get_rollups(sort_by: 'student', sort_order: 'random')
        expect(response).not_to be_success
      end

      context 'by outcome' do
        it 'should validate a missing sort_outcome_id parameter' do
          get_rollups(sort_by: 'outcome')
          expect(response).not_to be_success
        end

        it 'should validate an invalid sort_outcome_id parameter' do
          get_rollups(sort_by: 'outcome', sort_outcome_id: 'NaN')
          expect(response).not_to be_success
        end
      end

      def expect_user_order(rollups, users)
        rollup_user_ids = rollups.map {|r| r['links']['user'].to_i}
        user_ids = users.map(&:id)
        expect(rollup_user_ids).to eq user_ids
      end

      def expect_score_order(rollups, scores)
        rollup_scores = rollups.map do |r|
          r['scores'].length == 0 ? nil : r['scores'][0]['score'].to_i
        end
        expect(rollup_scores).to eq scores
      end

      context 'by student' do
        it 'should sort rollups by ascending student name' do
          get_rollups(sort_by: 'student')
          expect(response).to be_success
          json = parse_response(response)
          expect_user_order(json['rollups'], [@student1, @student2, @student3])
        end

        it 'should sort rollups by descending student name' do
          get_rollups(sort_by: 'student', sort_order: 'desc')
          expect(response).to be_success
          json = parse_response(response)
          expect_user_order(json['rollups'], [@student3, @student2, @student1])
        end

        context 'with pagination' do
          def expect_students_in_pagination(page, students, sort_order = 'asc')
            get_rollups(sort_by: 'student', sort_order: sort_order, per_page: 1, page: page)
            expect(response).to be_success
            json = parse_response(response)
            expect_user_order(json['rollups'], students)
          end

          context 'ascending' do
            it 'return student1 in first page' do
              expect_students_in_pagination(1, [@student1])
            end

            it 'return student2 in second page' do
              expect_students_in_pagination(2, [@student2])
            end

            it 'return student3 in third page' do
              expect_students_in_pagination(3, [@student3])
            end

            it 'return no student in fourth page' do
              expect_students_in_pagination(4, [])
            end
          end

          context 'descending' do
            it 'return student3 in first page' do
              expect_students_in_pagination(1, [@student3], 'desc')
            end

            it 'return student2 in second page' do
              expect_students_in_pagination(2, [@student2], 'desc')
            end

            it 'return student1 in third page' do
              expect_students_in_pagination(3, [@student1], 'desc')
            end

            it 'return no student in fourth page' do
              expect_students_in_pagination(4, [], 'desc')
            end
          end
        end
      end

      context 'by outcome' do
        it 'should sort rollups by ascending rollup score' do
          get_rollups(sort_by: 'outcome', sort_outcome_id: @outcome.id)
          expect(response).to be_success
          json = parse_response(response)
          expect_user_order(json['rollups'], [@student2, @student1, @student3])
          expect_score_order(json['rollups'], [1, 3, nil])
        end

        it 'should sort rollups by descending rollup score' do
          get_rollups(sort_by: 'outcome', sort_outcome_id: @outcome.id, sort_order: 'desc')
          expect(response).to be_success
          json = parse_response(response)
          expect_user_order(json['rollups'], [@student1, @student2, @student3])
          expect_score_order(json['rollups'], [3, 1, nil])
        end

        context 'with pagination' do
          def expect_students_in_pagination(page, students, scores, sort_order = 'asc')
            get_rollups(sort_by: 'outcome', sort_outcome_id: @outcome.id, sort_order: sort_order, per_page: 1, page: page)
            expect(response).to be_success
            json = parse_response(response)
            expect_user_order(json['rollups'], students)
            expect_score_order(json['rollups'], scores)
          end

          context 'ascending' do
            it 'return student2 in first page' do
              expect_students_in_pagination(1, [@student2], [1])
            end

            it 'return student1 in second page' do
              expect_students_in_pagination(2, [@student1], [3])
            end

            it 'return student3 in third page' do
              expect_students_in_pagination(3, [@student3], [nil])
            end

            it 'return no student in fourth page' do
              expect_students_in_pagination(4, [], [])
            end
          end

          context 'descending' do
            it 'return student1 in first page' do
              expect_students_in_pagination(1, [@student1], [3], 'desc')
            end

            it 'return student2 in second page' do
              expect_students_in_pagination(2, [@student2], [1], 'desc')
            end

            it 'return student3 in third page' do
              expect_students_in_pagination(3, [@student3], [nil], 'desc')
            end

            it 'return no student in fourth page' do
              expect_students_in_pagination(4, [], [], 'desc')
            end
          end
        end
      end
    end
  end
end

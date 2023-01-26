# frozen_string_literal: true

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

describe OutcomeResultsController do
  def context_outcome(context)
    @outcome_group = context.root_outcome_group
    @outcome = context.created_learning_outcomes.create!(title: "outcome")
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
    student_in_course(active_all: true, course: outcome_course, name: "Zebra Animal")
    @student
  end

  let_once(:observer) do
    observer_in_course(active_all: true, course: outcome_course, name: "Observer")
    @observer
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

  def create_result(user_id, outcome, assignment, score, opts = {})
    rubric_association = outcome_rubric.associate_with(outcome_assignment, outcome_course, purpose: "grading")

    LearningOutcomeResult.new(
      user_id: user_id,
      score: score,
      alignment: ContentTag.create!({
                                      title: "content",
                                      context: outcome_course,
                                      learning_outcome: outcome,
                                      content_type: "Assignment",
                                      content_id: assignment.id
                                    }),
      **opts
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
        :assessment_type => "grading",
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
      points_possible: outcome_rubric.points_possible
    )
  end

  def create_outcome_rubric_association(opts = {})
    rubric = (create_outcome_rubric if opts[:new]) ||
             outcome_rubric
    assignment = (create_outcome_assignment if opts[:new]) ||
                 outcome_assignment
    rubric.associate_with(assignment, outcome_course, purpose: "grading", use_for_grading: true)
  end

  def find_outcome_criterion(rubric = outcome_rubric)
    rubric.criteria.find { |c| !c[:learning_outcome_id].nil? }
  end

  def find_first_rating(criterion = outcome_criterion)
    criterion[:ratings].first
  end

  def parse_response(response)
    JSON.parse(response.body)
  end

  def mock_os_lor_results(user, outcome, assignment, score, args = {})
    title = "#{user.name}, #{assignment.name}"
    mastery = (score || 0) >= outcome.mastery_points
    submitted_at = args[:submitted_at] || Time.zone.now
    submission = Submission.find_by(user_id: user.id, assignment_id: assignment.id)
    alignment = ContentTag.create!(
      {
        title: "content",
        context: outcome_course,
        learning_outcome: outcome,
        content_type: "Assignment",
        content_id: assignment.id
      }
    )
    lor = LearningOutcomeResult.new(
      learning_outcome: outcome,
      user: user,
      context: outcome_course,
      alignment: alignment,
      artifact: submission,
      associated_asset: assignment,
      title: title,
      score: score,
      possible: outcome.points_possible,
      mastery: mastery,
      created_at: submitted_at,
      updated_at: submitted_at,
      submitted_at: submitted_at,
      assessed_at: submitted_at
    )
    if args[:include_rubric]
      lor.association_type = "RubricAssociation"
      lor.association_id = outcome_rubric.id
    end
    lor
  end

  def get_results(params)
    get "index", params: {
      context_id: @course.id,
      course_id: @course.id,
      context_type: "Course",
      user_ids: [@student.id],
      outcome_ids: [@outcome.id],
      **params
    },
                 format: "json"
  end

  describe "retrieving outcome results" do
    it "does not have a false failure if an outcome exists in two places within the same context" do
      user_session(@teacher)
      outcome_group = @course.root_outcome_group.child_outcome_groups.build(
        title: "Child outcome group", context: @course
      )
      outcome_group.save!
      outcome_group.add_outcome(@outcome)
      get "rollups", params: { context_id: @course.id,
                               course_id: @course.id,
                               context_type: "Course",
                               user_ids: [@student.id],
                               outcome_ids: [@outcome.id] },
                     format: "json"
      expect(response).to be_successful
    end

    it "allows specifying both outcome_ids and include[]=outcome_links" do
      user_session(@teacher)
      context_outcome(@course)
      get "rollups", params: { context_id: @course.id,
                               course_id: @course.id,
                               context_type: "Course",
                               user_ids: [@student.id],
                               outcome_ids: [@outcome.id],
                               include: ["outcome_links"] },
                     format: "json"
      expect(response).to be_successful
      json = parse_response(response)
      links = json["linked"]["outcome_links"]
      expect(links.length).to eq 1
      expect(links[0]["outcome"]["id"]).to eq @outcome.id
    end

    it "validates aggregate_stat parameter" do
      user_session(@teacher)
      get "rollups", params: { context_id: @course.id,
                               course_id: @course.id,
                               context_type: "Course",
                               aggregate: "course",
                               aggregate_stat: "powerlaw" },
                     format: "json"
      expect(response).not_to be_successful
    end

    context "student lmgb usage tracking" do
      def fetch_student_lmgb_data
        get "rollups", params: { context_id: @course.id,
                                 course_id: @course.id,
                                 context_type: "Course",
                                 user_ids: [@student.id],
                                 outcome_ids: [@outcome.id] },
                       format: "json"
      end

      it "increments statsd if a student is viewing their own sLMGB results" do
        allow(InstStatsd::Statsd).to receive(:increment)
        user_session(@student)
        fetch_student_lmgb_data
        expect(response).to be_successful
        expect(InstStatsd::Statsd).to have_received(:increment).with(
          "outcomes_page_views",
          tags: { type: "student_lmgb" }
        ).once
      end

      it "increments statsd if an observer is viewing a linked student\"s sLMGB results" do
        @observer.enrollments.find_by(course_id: @course.id).update!(associated_user_id: @student)
        allow(InstStatsd::Statsd).to receive(:increment)
        user_session(@observer)
        fetch_student_lmgb_data
        expect(response).to be_successful
        expect(InstStatsd::Statsd).to have_received(:increment).with(
          "outcomes_page_views",
          tags: { type: "student_lmgb" }
        ).once
      end

      it "doesnt increment statsd if an observer is viewing a non-linked student\"s sLMGB results" do
        allow(InstStatsd::Statsd).to receive(:increment)
        user_session(@observer)
        fetch_student_lmgb_data
        expect(response).not_to be_successful
        expect(InstStatsd::Statsd).not_to have_received(:increment).with(
          "outcomes_page_views",
          tags: { type: "student_lmgb" }
        )
      end

      it "doesnt increment a statsd if a teacher is viewing a student\"s sLMGB results" do
        allow(InstStatsd::Statsd).to receive(:increment)
        user_session(@teacher)
        fetch_student_lmgb_data
        expect(response).to be_successful
        expect(InstStatsd::Statsd).not_to have_received(:increment).with(
          "outcomes_page_views",
          tags: { type: "student_lmgb" }
        )
      end
    end

    context "with manual post policy assignment" do
      before do
        outcome_assignment.ensure_post_policy(post_manually: true)
      end

      it "teacher should see result" do
        user_session(@teacher)
        get "index", params: { context_id: @course.id,
                               course_id: @course.id,
                               context_type: "Course",
                               user_ids: [@student.id],
                               outcome_ids: [@outcome.id] },
                     format: "json"
        json = JSON.parse(response.body)
        expect(json["outcome_results"].length).to eq 1
      end

      it "student should not see result" do
        user_session(@student)
        get "index", params: { context_id: @course.id,
                               course_id: @course.id,
                               context_type: "Course",
                               user_ids: [@student.id],
                               outcome_ids: [@outcome.id] },
                     format: "json"
        json = parse_response(response)
        expect(json["outcome_results"].length).to eq 0
      end
    end

    context "with auto post policy (default) assignment" do
      before do
        outcome_assignment.ensure_post_policy(post_manually: false)
      end

      it "teacher should see result" do
        user_session(@teacher)
        get "index", params: { context_id: @course.id,
                               course_id: @course.id,
                               context_type: "Course",
                               user_ids: [@student.id],
                               outcome_ids: [@outcome.id] },
                     format: "json"
        json = JSON.parse(response.body)
        expect(json["outcome_results"].length).to eq 1
      end

      it "student should see result" do
        user_session(@student)
        get "index", params: { context_id: @course.id,
                               course_id: @course.id,
                               context_type: "Course",
                               user_ids: [@student.id],
                               outcome_ids: [@outcome.id] },
                     format: "json"
        json = parse_response(response)
        expect(json["outcome_results"].length).to eq 1
      end
    end

    it "exclude missing user rollups" do
      user_session(@teacher)
      # save a reference to the 1st student
      student1 = @student
      # create a 2nd student that is saved as @student
      student_in_course(active_all: true, course: outcome_course)
      get "rollups", params: { context_id: @course.id,
                               course_id: @course.id,
                               context_type: "Course",
                               user_ids: [student1.id, @student.id],
                               outcome_ids: [@outcome.id],
                               exclude: ["missing_user_rollups"] },
                     format: "json"
      json = parse_response(response)
      # the rollups requests for both students, but excludes the 2nd student
      # since they do not have any results, unlike the 1st student,
      # which has a single result in `outcome_result`
      expect(json["rollups"].length).to be 1

      # the pagination count should be 1 for the one student with a rollup
      expect(json["meta"]["pagination"]["count"]).to be 1
    end

    context "with outcome_service_results_to_canvas FF" do
      shared_examples "outcome results" do
        before do
          user_session(user)
          @assignment = create_outcome_assignment
          find_or_create_outcome_submission({ student: student, assignment: @assignment })
          @assignment2 = create_outcome_assignment
          find_or_create_outcome_submission({ student: student, assignment: @assignment2 })
        end

        it "FF disabled - only display results for canvas" do
          user_session(user)
          @course.disable_feature!(:outcome_service_results_to_canvas)
          create_result(student.id, @outcome, @assignment, 2, { possible: 5 })
          expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(nil)
          json = parse_response(get_results({ user_ids: [student], include: ["assignments"] }))
          expect(json["outcome_results"].length).to be 1
          expect(json["linked"]["assignments"].length).to be 1
        end

        context "FF enabled" do
          before do
            @course.enable_feature!(:outcome_service_results_to_canvas)
            user_session(user)
          end

          it "no OS results found - display canvas results only" do
            create_result(student.id, @outcome, @assignment, 2, { possible: 5 })
            expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(nil)
            json = parse_response(get_results({ user_ids: [student], include: ["assignments"] }))
            expect(json["outcome_results"].length).to be 1
            expect(json["linked"]["assignments"].length).to be 1
          end

          it "OS results found - no Canvas results - displays only OS results" do
            mocked_results = mock_os_lor_results(student, @outcome, @assignment2, 2)
            expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(
              [mocked_results]
            )
            json = parse_response(get_results({ user_ids: [student], include: ["assignments"] }))
            expect(json["outcome_results"].length).to be 1
            expect(json["outcome_results"][0]["links"]["alignment"]).to eq("assignment_" + @assignment2.id.to_s)
            expect(json["linked"]["assignments"].length).to be 1
            expect(json["linked"]["assignments"][0]["id"]).to eq("assignment_" + @assignment2.id.to_s)
          end

          it "OS results found - display both Canvas and OS results" do
            create_result(student.id, @outcome, @assignment, 2, { possible: 5 })
            mocked_results = mock_os_lor_results(student, @outcome, @assignment2, 2)
            expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(
              [mocked_results]
            )
            json = parse_response(get_results({ user_ids: [student], include: ["assignments"] }))
            expect(json["outcome_results"].length).to be 2
            expect(json["linked"]["assignments"].length).to be 2
            expect(json["linked"]["assignments"][0]["id"]).to eq("assignment_" + @assignment2.id.to_s)
            expect(json["linked"]["assignments"][1]["id"]).to eq("assignment_" + @assignment.id.to_s)
          end

          it "OS results found - assignments are unique when aligned to two outcomes" do
            outcome2 = @course.created_learning_outcomes.create!(title: "outcome 2")
            create_result(student.id, @outcome, @assignment, 2, { possible: 5 })
            mocked_results_1 = mock_os_lor_results(student, @outcome, @assignment2, 2)
            mocked_results_2 = mock_os_lor_results(student, outcome2, @assignment2, 2)
            expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(
              [mocked_results_1, mocked_results_2]
            )
            json = parse_response(get_results({ user_ids: [student], include: ["assignments"] }))
            expect(json["outcome_results"].length).to be 3
            expect(json["linked"]["assignments"].length).to be 2
          end
        end
      end

      describe "for different users" do
        let(:student) { student_in_course(active_all: true, course: outcome_course, name: "Hello Kitty").user }

        include_examples "outcome results" do
          let(:user) { student }
        end

        include_examples "outcome results" do
          let(:user) { @teacher }
        end
      end
    end
  end

  describe "retrieving outcome rollups" do
    before do
      @student1 = @student
      @student2 = student_in_course(active_all: true, course: outcome_course, name: "Amy Mammoth").user
      @student3 = student_in_course(active_all: true, course: outcome_course, name: "Barney Youth").user

      create_result(@student2.id, @outcome, outcome_assignment, 1)
    end

    before do
      user_session(@teacher)
    end

    def get_rollups(params)
      get "rollups", params: {
        context_id: @course.id,
        course_id: @course.id,
        context_type: "Course",
        **params
      },
                     format: "json"
    end

    it "includes rating percents" do
      json = parse_response(get_rollups(rating_percents: true, include: ["outcomes"]))
      expect(json["linked"]["outcomes"][0]["ratings"].map { |r| r["percent"] }).to eq [50, 50]
    end

    context "with outcome_service_results_to_canvas FF" do
      context "user_rollups" do
        it "disabled - only display rollups for canvas" do
          @course.disable_feature!(:outcome_service_results_to_canvas)
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(nil)
          json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 1, page: 1))
          expect(json["rollups"].length).to be 1
        end

        context "enabled" do
          before do
            @course.enable_feature!(:outcome_service_results_to_canvas)
          end

          it "no OS results found - display canvas rollups only" do
            create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
            expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(nil)
            json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 1, page: 1))
            expect(json["rollups"].length).to be 1
          end

          it "OS results found - no Canvas results - displays only OS rollups" do
            # removing LearningOutcomeResults for those users that have results
            # creating in the first before do after the rollups context
            LearningOutcomeResult.where(user_id: @student.id).update(workflow_state: "deleted")
            LearningOutcomeResult.where(user_id: @student1.id).update(workflow_state: "deleted")
            LearningOutcomeResult.where(user_id: @student2.id).update(workflow_state: "deleted")
            student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
            mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
            expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(
              [mocked_results]
            )
            json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 5, page: 1))
            # will be 4 because the exclude: "missing_user_results" parameter is not included
            # in the rollups call
            expect(json["rollups"].length).to be 4
            # need to loop through each rollup to make sure there is only 1 rollup with scores
            score_count = 0
            json["rollups"].each do |r|
              score_count += 1 unless r["scores"].empty?
            end
            expect(score_count).to be 1
          end

          it "OS results found - display both Canvas and OS rollups" do
            # already existing results for @student1 & @student2
            # creating result for @student
            create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
            # results are already created for @student2 in Canvas
            student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
            mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
            expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(
              [mocked_results]
            )
            json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 5, page: 1))
            expect(json["rollups"].length).to be 4
          end
        end

        context "aggregate_user_rollups" do
          it "disabled - only display rollups for canvas" do
            @course.disable_feature!(:outcome_service_results_to_canvas)
            # already existing results for @student1 & @student2
            # creating result for @student
            create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
            expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(nil)
            json = parse_response(get_rollups(aggregate: "course", aggregate_stat: "mean", per_page: 5, page: 1))
            expect(json["rollups"].length).to be 1
            expect(json["rollups"][0]["scores"][0]["count"]).to be 3
          end

          context "enabled" do
            before do
              @course.enable_feature!(:outcome_service_results_to_canvas)
            end

            it "no OS results found - display canvas rollups only" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(nil)
              json = parse_response(get_rollups(aggregate: "course", aggregate_stat: "mean", per_page: 5, page: 1))
              expect(json["rollups"].length).to be 1
              expect(json["rollups"][0]["scores"][0]["count"]).to be 3
            end

            it "OS results found - no Canvas results - displays only OS rollups" do
              # removing LearningOutcomeResults for users that have results (@student1, @student, @student2)
              # creating in the first before do after the rollups context
              LearningOutcomeResult.where(user_id: @student.id).update(workflow_state: "deleted")
              LearningOutcomeResult.where(user_id: @student1.id).update(workflow_state: "deleted")
              LearningOutcomeResult.where(user_id: @student2.id).update(workflow_state: "deleted")
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(
                [mocked_results]
              )
              json = parse_response(get_rollups(aggregate: "course", aggregate_stat: "mean", per_page: 5, page: 1))
              expect(json["rollups"].length).to be 1
              expect(json["rollups"][0]["scores"][0]["count"]).to be 1
            end

            it "OS results found - display both Canvas and OS rollups" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              # results are already created for @student2 in Canvas
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(
                [mocked_results]
              )
              json = parse_response(get_rollups(aggregate: "course", aggregate_stat: "mean", per_page: 5, page: 1))
              expect(json["rollups"].length).to be 1
              expect(json["rollups"][0]["scores"][0]["count"]).to be 4
            end
          end
        end

        context "remove_users_with_no_results" do
          it "disabled - only display rollups for canvas" do
            @course.disable_feature!(:outcome_service_results_to_canvas)
            # already existing results for @student1 & @student2
            # creating result for @student
            create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
            expect(controller).to receive(:find_outcomes_service_results).with(any_args).twice.and_return(nil)
            json = parse_response(get_rollups(sort_by: "student", sort_order: "desc",
                                              exclude: ["missing_user_rollups"],
                                              per_page: 5, page: 1))
            expect(json["rollups"].length).to be 3
          end

          context "enabled" do
            before do
              @course.enable_feature!(:outcome_service_results_to_canvas)
            end

            it "no OS results found - display canvas rollups only" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              expect(controller).to receive(:find_outcomes_service_results).with(any_args).twice.and_return(nil)
              json = parse_response(get_rollups(sort_by: "student", sort_order: "desc",
                                                exclude: ["missing_user_rollups"],
                                                per_page: 5, page: 1))
              expect(json["rollups"].length).to be 3
            end

            it "OS results found - no Canvas results - display only OS results" do
              # removing LearningOutcomeResults for those users that have results
              # creating in the first before do after the rollups context
              LearningOutcomeResult.where(user_id: @student.id).update(workflow_state: "deleted")
              LearningOutcomeResult.where(user_id: @student1.id).update(workflow_state: "deleted")
              LearningOutcomeResult.where(user_id: @student2.id).update(workflow_state: "deleted")
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:find_outcomes_service_results).with(any_args).twice.and_return(
                [mocked_results]
              )
              # per_page is the number of students to display on 1 page of results
              json = parse_response(get_rollups(sort_by: "student", sort_order: "desc",
                                                exclude: ["missing_user_rollups"],
                                                per_page: 5, page: 1))
              expect(json["rollups"].length).to be 1
            end

            it "OS results found - display both Canvas and OS rollups" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              # results are already created for @student2 in Canvas
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:find_outcomes_service_results).with(any_args).twice.and_return(
                [mocked_results]
              )
              # per_page is the number of students to display on 1 page of results
              json = parse_response(get_rollups(sort_by: "student", sort_order: "desc",
                                                exclude: ["missing_user_rollups"],
                                                per_page: 5, page: 1))
              expect(json["rollups"].length).to be 4
            end

            it "removes student with no results" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              # results are already created for @student2 in Canvas
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              # Creating another student in the course which will make 5 students enrolled
              # and will not create results for this student
              student_in_course(active_all: true, course: outcome_course)
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:find_outcomes_service_results).with(any_args).twice.and_return(
                [mocked_results]
              )
              # per_page is the number of students to display on 1 page of results
              json = parse_response(get_rollups(sort_by: "student", sort_order: "desc",
                                                exclude: ["missing_user_rollups"],
                                                per_page: 5, page: 1))
              # the rollups should be for only the 4 that have results
              expect(json["rollups"].length).to be 4
            end

            it "removes concluded student" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              # creating and enrolling student 4 in the course
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(
                [mocked_results]
              )
              # concluding student 3 in the course which will remove the student from the results
              StudentEnrollment.find_by(user_id: @student3.id).conclude
              json = parse_response(get_rollups(sort_by: "student", sort_order: "desc",
                                                exclude: ["concluded_enrollments"],
                                                per_page: 5, page: 1))
              expect(json["rollups"].length).to be 3
            end

            it "removes inactive student" do
              # already existing results for @student1 & @student2
              # creating result for @student
              create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
              # creating and enrolling student 4 in the course
              student4 = student_in_course(active_all: true, course: outcome_course, name: "OS user").user
              mocked_results = mock_os_lor_results(student4, @outcome, outcome_assignment, 2)
              expect(controller).to receive(:find_outcomes_service_results).with(any_args).and_return(
                [mocked_results]
              )
              # deactivating student 3 in the course which will remove the student from the results
              StudentEnrollment.find_by(user_id: @student3.id).deactivate
              json = parse_response(get_rollups(sort_by: "student", sort_order: "desc",
                                                exclude: ["inactive_enrollments"],
                                                per_page: 5, page: 1))
              expect(json["rollups"].length).to be 3
            end
          end
        end
      end
    end

    context "with the account_mastery_scales FF" do
      context "enabled" do
        before do
          @course.account.enable_feature!(:account_level_mastery_scales)
        end

        it "uses the default outcome proficiency for points scaling if no outcome proficiency exists" do
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 1, page: 1))
          points_possible = OutcomeProficiency.find_or_create_default!(@course.account).points_possible
          score = (2.to_f / 5.to_f) * points_possible
          expect(json["rollups"][0]["scores"][0]["score"]).to eq score
        end

        it "uses resolved_outcome_proficiency for points scaling if one exists" do
          proficiency = outcome_proficiency_model(@course)
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 1, page: 1))
          score = (2.to_f / 5.to_f) * proficiency.points_possible
          expect(json["rollups"][0]["scores"][0]["score"]).to eq score
        end

        it "returns outcomes with outcome_proficiency.ratings and their percents" do
          outcome_proficiency_model(@course)
          json = parse_response(get_rollups(rating_percents: true, include: ["outcomes"]))
          ratings = json["linked"]["outcomes"][0]["ratings"]
          expect(ratings.map { |r| r["percent"] }).to eq [50, 50]
          expect(ratings.map { |r| r["points"] }).to eq [10, 0]
        end
      end

      context "disabled" do
        before do
          @course.account.disable_feature!(:account_level_mastery_scales)
        end

        it "ignores the outcome proficiency for points scaling" do
          outcome_proficiency_model(@course)
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 1, page: 1))
          expect(json["rollups"][0]["scores"][0]["score"]).to eq 1.2 # ( score of 2 / possible 5) * outcome.points_possible
        end

        it "contains mastery and color information for ratings" do
          outcome_proficiency_model(@course)
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", add_defaults: true, per_page: 1, page: 1, include: ["outcomes"]))
          ratings = json["linked"]["outcomes"][0]["ratings"]
          expect(ratings.map { |r| r["mastery"] }).to eq [true, false]
          expect(ratings.map { |r| r["color"] }).to eq ["0B874B", "555555"]
        end

        it "does not contain mastery and color information if \"add_defaults\" parameter is not provided" do
          outcome_proficiency_model(@course)
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(sort_by: "student", sort_order: "desc", per_page: 1, page: 1, include: ["outcomes"]))
          ratings = json["linked"]["outcomes"][0]["ratings"]
          expect(ratings.map { |r| r["mastery"] }).to eq [nil, nil]
          expect(ratings.map { |r| r["color"] }).to eq [nil, nil]
        end
      end
    end

    context "with outcomes_friendly_description and improved_outcomes_management FFs" do
      before do
        OutcomeFriendlyDescription.create!(learning_outcome: @outcome, context: @course, description: "A friendly description")
      end

      context "enabled" do
        before do
          Account.site_admin.enable_feature!(:outcomes_friendly_description)
          @course.root_account.enable_feature!(:improved_outcomes_management)
        end

        it "returns outcomes with friendly_description" do
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(include: ["outcomes"]))
          expect(json["linked"]["outcomes"][0]["friendly_description"]).to eq "A friendly description"
        end
      end

      context "outcomes_friendly_description disabled" do
        before do
          Account.site_admin.disable_feature!(:outcomes_friendly_description)
        end

        it "returns outcomes without friendlly_description" do
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(include: ["outcomes"]))
          expect(json["linked"]["outcomes"][0]["friendly_description"]).to be_nil
        end
      end

      context "outcomes_friendly_description enabled, but improved_outcomes_management disabled" do
        before do
          Account.site_admin.enable_feature!(:outcomes_friendly_description)
          @course.root_account.disable_feature!(:improved_outcomes_management)
        end

        it "returns outcomes without friendlly_description" do
          create_result(@student.id, @outcome, outcome_assignment, 2, { possible: 5 })
          json = parse_response(get_rollups(include: ["outcomes"]))
          expect(json["linked"]["outcomes"][0]["friendly_description"]).to be_nil
        end
      end
    end

    context "inactive/concluded LMGB filters" do
      it "displays rollups for concluded enrollments when they are included" do
        StudentEnrollment.find_by(user_id: @student2.id).conclude
        json = parse_response(get_rollups({}))
        rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
        expect(rollups.count).to eq(1)
        expect(rollups.first["scores"][0]["score"]).to eq 1.0
      end

      it "does not display rollups for concluded enrollments when they are not included" do
        StudentEnrollment.find_by(user_id: @student2.id).conclude
        json = parse_response(get_rollups(exclude: "concluded_enrollments"))
        expect(json["rollups"].count { |r| r["links"]["user"] == @student2.id.to_s }).to eq(0)
      end

      it "displays rollups for a student who has an active and a concluded enrolllment regardless of filter" do
        section1 = add_section "s1", course: outcome_course
        student_in_section section1, user: @student2, allow_multiple_enrollments: true
        StudentEnrollment.find_by(course_section_id: section1.id).conclude
        json = parse_response(get_rollups(exclude: "concluded_enrollments"))
        rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
        expect(rollups.count).to eq(2)
        expect(rollups.first["scores"][0]["score"]).to eq 1.0
        expect(rollups.second["scores"][0]["score"]).to eq 1.0
      end

      it "displays rollups for inactive enrollments when they are included" do
        StudentEnrollment.find_by(user_id: @student2.id).deactivate
        json = parse_response(get_rollups({}))
        rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
        expect(rollups.count).to eq(1)
        expect(rollups.first["scores"][0]["score"]).to eq 1.0
      end

      it "does not display rollups for inactive enrollments when they are not included" do
        StudentEnrollment.find_by(user_id: @student2.id).deactivate
        json = parse_response(get_rollups(exclude: "inactive_enrollments"))
        expect(json["rollups"].count { |r| r["links"]["user"] == @student2.id.to_s }).to eq(0)
      end

      it "does not display rollups for deleted enrollments" do
        StudentEnrollment.find_by(user_id: @student2.id).update(workflow_state: "deleted")
        json = parse_response(get_rollups({}))
        expect(json["rollups"].count { |r| r["links"]["user"] == @student2.id.to_s }).to eq(0)
      end

      context "users with enrollments of different enrollment states" do
        before do
          StudentEnrollment.find_by(user_id: @student2.id).deactivate
          @section1 = add_section "s1", course: outcome_course
          student_in_section @section1, user: @student2, allow_multiple_enrollments: true
          StudentEnrollment.find_by(course_section_id: @section1.id).conclude
        end

        it "users whose enrollments are all excluded are not included" do
          json = parse_response(get_rollups(exclude: ["concluded_enrollments", "inactive_enrollments"]))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          expect(rollups.count).to eq(0)
        end

        it "users whose enrollments are all excluded are not included in a specified section" do
          json = parse_response(get_rollups(exclude: ["concluded_enrollments", "inactive_enrollments"],
                                            section_id: @section1.id))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          expect(rollups.count).to eq(0)
        end

        it "users who contain an active enrollment are always included" do
          section3 = add_section "s3", course: outcome_course
          student_in_section section3, user: @student2, allow_multiple_enrollments: true
          json = parse_response(get_rollups(exclude: ["concluded_enrollments", "inactive_enrollments"]))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          expect(rollups.count).to eq(3)
          expect(rollups.first["scores"][0]["score"]).to eq 1.0
          expect(rollups.second["scores"][0]["score"]).to eq 1.0
          expect(rollups.third["scores"][0]["score"]).to eq 1.0
        end
      end

      context "students enrolled in multiple sections" do
        before do
          @section1 = add_section "s1", course: outcome_course
          @section2 = add_section "s2", course: outcome_course

          student_in_section @section1, user: @student1, allow_multiple_enrollments: true
          student_in_section @section2, user: @student2, allow_multiple_enrollments: true
          student_in_section @section1, user: @student2, allow_multiple_enrollments: true
          student_in_section @section2, user: @student3, allow_multiple_enrollments: true
        end

        it "returns active students who are in section 1" do
          json = parse_response(get_rollups({ exclude: ["concluded_enrollments", "inactive_enrollments"], section_id: @section1.id }))
          # student 3 is only enrolled in section 2
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student3.id.to_s }
          expect(rollups.count).to eq(0)
          # student 1 & student 2 are enrolled in section 1
          expect(json["rollups"].first["links"]["user"]).to eq @student1.id.to_s
          expect(json["rollups"].second["links"]["user"]).to eq @student2.id.to_s
        end

        it "returns only active students by default when inactive students are enrolled" do
          StudentEnrollment.find_by(user_id: @student2.id, course_section_id: @section1.id).deactivate
          json = parse_response(get_rollups({ exclude: ["concluded_enrollments", "inactive_enrollments"], section_id: @section1.id }))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          expect(rollups.count).to eq(0)
          expect(json["rollups"].count).to eq(1)
          expect(json["rollups"].first["links"]["user"]).to eq @student1.id.to_s
        end

        it "returns only active students by default when concluded and inactive students are enrolled" do
          student_in_section @section1, user: @student3, allow_multiple_enrollments: true
          StudentEnrollment.find_by(user_id: @student2.id, course_section_id: @section1.id).deactivate
          StudentEnrollment.find_by(user_id: @student3.id, course_section_id: @section1.id).conclude
          json = parse_response(get_rollups({ exclude: ["concluded_enrollments", "inactive_enrollments"], section_id: @section1.id }))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          expect(rollups.count).to eq(0)
          expect(json["rollups"].count).to eq(1)
          expect(json["rollups"].first["links"]["user"]).to eq @student1.id.to_s
        end

        it "returns active and concluded students but not inactive" do
          student_in_section @section1, user: @student3, allow_multiple_enrollments: true
          StudentEnrollment.find_by(user_id: @student2.id, course_section_id: @section1.id).deactivate
          StudentEnrollment.find_by(user_id: @student3.id, course_section_id: @section1.id).conclude
          json = parse_response(get_rollups({ exclude: ["inactive_enrollments"], section_id: @section1.id }))
          rollups = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          expect(rollups.count).to eq(0)
          expect(json["rollups"].count).to eq(2)
          expect(json["rollups"].first["links"]["user"]).to eq @student1.id.to_s
          expect(json["rollups"].second["links"]["user"]).to eq @student3.id.to_s
        end

        it "returns active, concluded and inactive students" do
          student_in_section @section1, user: @student3, allow_multiple_enrollments: true
          StudentEnrollment.find_by(user_id: @student2.id, course_section_id: @section1.id).deactivate
          StudentEnrollment.find_by(user_id: @student3.id, course_section_id: @section1.id).conclude
          json = parse_response(get_rollups({ section_id: @section1.id }))
          expect(json["rollups"].count).to eq(3)
          expect(json["rollups"].first["links"]["user"]).to eq @student1.id.to_s
          expect(json["rollups"].second["links"]["user"]).to eq @student2.id.to_s
          expect(json["rollups"].third["links"]["user"]).to eq @student3.id.to_s
        end

        it "returns active by default for all sections in a course" do
          json = parse_response(get_rollups({ exclude: ["concluded_enrollments", "inactive_enrollments"] }))
          rollups_student1 = json["rollups"].select { |r| r["links"]["user"] == @student1.id.to_s }
          rollups_student2 = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          rollups_student3 = json["rollups"].select { |r| r["links"]["user"] == @student3.id.to_s }
          expect(rollups_student1.count).to eq(2) # enrolled in 2 sections
          expect(rollups_student2.count).to eq(3) # enrolled in 3 sections
          expect(rollups_student3.count).to eq(2) # enrolled in 2 sections
        end

        it "returns students that are active in 1 section in the course but inactive in another by default" do
          StudentEnrollment.find_by(user_id: @student2.id, course_section_id: @section1.id).deactivate
          json = parse_response(get_rollups({ exclude: ["concluded_enrollments", "inactive_enrollments"] }))
          rollups_student1 = json["rollups"].select { |r| r["links"]["user"] == @student1.id.to_s }
          rollups_student2 = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          rollups_student3 = json["rollups"].select { |r| r["links"]["user"] == @student3.id.to_s }
          expect(rollups_student1.count).to eq(2) # enrolled in 2 sections
          expect(rollups_student2.count).to eq(3) # enrolled in 3 sections
          expect(rollups_student3.count).to eq(2) # enrolled in 2 sections
        end

        it "returns students that are active in 1 section in the course but concluded in another by default" do
          StudentEnrollment.find_by(user_id: @student2.id, course_section_id: @section1.id).conclude
          json = parse_response(get_rollups({ exclude: ["concluded_enrollments", "inactive_enrollments"] }))
          rollups_student1 = json["rollups"].select { |r| r["links"]["user"] == @student1.id.to_s }
          rollups_student2 = json["rollups"].select { |r| r["links"]["user"] == @student2.id.to_s }
          rollups_student3 = json["rollups"].select { |r| r["links"]["user"] == @student3.id.to_s }
          expect(rollups_student1.count).to eq(2) # enrolled in 2 sections
          expect(rollups_student2.count).to eq(3) # enrolled in 3 sections
          expect(rollups_student3.count).to eq(2) # enrolled in 2 sections
        end
      end
    end

    context "sorting" do
      it "validates sort_by parameter" do
        get_rollups(sort_by: "garbage")
        expect(response).not_to be_successful
      end

      it "validates sort_order parameter" do
        get_rollups(sort_by: "student", sort_order: "random")
        expect(response).not_to be_successful
      end

      context "by outcome" do
        it "validates a missing sort_outcome_id parameter" do
          get_rollups(sort_by: "outcome")
          expect(response).not_to be_successful
        end

        it "validates an invalid sort_outcome_id parameter" do
          get_rollups(sort_by: "outcome", sort_outcome_id: "NaN")
          expect(response).not_to be_successful
        end

        it "sorts rollups by ascending rollup score" do
          get_rollups(sort_by: "outcome", sort_outcome_id: @outcome.id)
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student2, @student1, @student3])
          expect_score_order(json["rollups"], [1, 3, nil])
        end

        it "sorts rollups by descending rollup score" do
          get_rollups(sort_by: "outcome", sort_outcome_id: @outcome.id, sort_order: "desc")
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student1, @student2, @student3])
          expect_score_order(json["rollups"], [3, 1, nil])
        end

        context "with pagination" do
          def expect_students_in_pagination(page, students, scores, sort_order = "asc")
            get_rollups(sort_by: "outcome", sort_outcome_id: @outcome.id, sort_order: sort_order, per_page: 1, page: page)
            expect(response).to be_successful
            json = parse_response(response)
            expect_user_order(json["rollups"], students)
            expect_score_order(json["rollups"], scores)
          end

          context "ascending" do
            it "return student2 in first page" do
              expect_students_in_pagination(1, [@student2], [1])
            end

            it "return student1 in second page" do
              expect_students_in_pagination(2, [@student1], [3])
            end

            it "return student3 in third page" do
              expect_students_in_pagination(3, [@student3], [nil])
            end

            it "return no student in fourth page" do
              expect_students_in_pagination(4, [], [])
            end
          end

          context "descending" do
            it "return student1 in first page" do
              expect_students_in_pagination(1, [@student1], [3], "desc")
            end

            it "return student2 in second page" do
              expect_students_in_pagination(2, [@student2], [1], "desc")
            end

            it "return student3 in third page" do
              expect_students_in_pagination(3, [@student3], [nil], "desc")
            end

            it "return no student in fourth page" do
              expect_students_in_pagination(4, [], [], "desc")
            end
          end
        end
      end

      def expect_user_order(rollups, users)
        rollup_user_ids = rollups.map { |r| r["links"]["user"].to_i }
        user_ids = users.map(&:id)
        expect(rollup_user_ids).to eq user_ids
      end

      def expect_score_order(rollups, scores)
        rollup_scores = rollups.map do |r|
          r["scores"].empty? ? nil : r["scores"][0]["score"].to_i
        end
        expect(rollup_scores).to eq scores
      end

      context "by student" do
        it "sorts rollups by ascending student name" do
          get_rollups(sort_by: "student")
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student1, @student2, @student3])
        end

        it "sorts rollups by descending student name" do
          get_rollups(sort_by: "student", sort_order: "desc")
          expect(response).to be_successful
          json = parse_response(response)
          expect_user_order(json["rollups"], [@student3, @student2, @student1])
        end

        context "with teachers who have limited privilege" do
          before do
            @section1 = add_section "s1", course: outcome_course
            @section2 = add_section "s2", course: outcome_course
            @section3 = add_section "s3", course: outcome_course

            student_in_section @section1, user: @student1, allow_multiple_enrollments: false
            student_in_section @section2, user: @student2, allow_multiple_enrollments: false
            student_in_section @section3, user: @student3, allow_multiple_enrollments: false
            @teacher = teacher_in_section(@section2, limit_privileges_to_course_section: true)
            user_session(@teacher)
          end

          context "with the .limit_section_visibility_in_lmgb FF enabled" do
            before do
              @course.root_account.enable_feature!(:limit_section_visibility_in_lmgb)
            end

            it "only returns students in the teachers section" do
              get_rollups(sort_by: "student", sort_order: "desc")
              json = parse_response(response)
              expect_user_order(json["rollups"], [@student2])
            end
          end

          context "with the .limit_section_visibility_in_lmgb FF disabled" do
            it "returns students in all sections" do
              get_rollups(sort_by: "student", sort_order: "desc")
              json = parse_response(response)
              expect_user_order(json["rollups"], [@student3, @student2, @student1])
            end
          end
        end

        context "with pagination" do
          let(:json) { parse_response(response) }

          def expect_students_in_pagination(page, students, sort_order = "asc", include: nil)
            get_rollups(sort_by: "student", sort_order: sort_order, per_page: 1, page: page, include: include)
            expect(response).to be_successful
            expect_user_order(json["rollups"], students)
          end

          context "ascending" do
            it "return student1 in first page" do
              expect_students_in_pagination(1, [@student1])
            end

            it "return student2 in second page" do
              expect_students_in_pagination(2, [@student2])
            end

            it "return student3 in third page" do
              expect_students_in_pagination(3, [@student3])
            end

            it "return no student in fourth page" do
              expect_students_in_pagination(4, [])
            end
          end

          context "descending" do
            it "return student3 in first page" do
              expect_students_in_pagination(1, [@student3], "desc")
            end

            it "return student2 in second page" do
              expect_students_in_pagination(2, [@student2], "desc")
            end

            it "return student1 in third page" do
              expect_students_in_pagination(3, [@student1], "desc")
            end

            it "return no student in fourth page" do
              expect_students_in_pagination(4, [], "desc")
            end
          end

          context "with multiple enrollments" do
            before do
              @section1 = add_section "s1", course: outcome_course
              @section2 = add_section "s2", course: outcome_course
              student_in_section @section1, user: @student2, allow_multiple_enrollments: true
              student_in_section @section2, user: @student2, allow_multiple_enrollments: true
              student_in_section @section2, user: @student3, allow_multiple_enrollments: true
            end

            context "should paginate by user, rather than by enrollment" do
              it "returns student1 on first page" do
                expect_students_in_pagination(1, [@student1], include: ["users"])
                expect(json["linked"]["users"].map { |u| u["id"] }).to eq [@student1.id.to_s]
              end

              it "returns student2 on second page" do
                expect_students_in_pagination(2, [@student2, @student2, @student2], include: ["users"])
                expect(json["linked"]["users"].map { |u| u["id"] }).to eq [@student2.id.to_s]
              end

              it "returns student3 on third page" do
                expect_students_in_pagination(3, [@student3, @student3], include: ["users"])
                expect(json["linked"]["users"].map { |u| u["id"] }).to eq [@student3.id.to_s]
              end

              it "return no student in fourth page" do
                expect_students_in_pagination(4, [], include: ["users"])
                expect(json["linked"]["users"].length).to be 0
              end
            end
          end
        end
      end
    end
  end
end

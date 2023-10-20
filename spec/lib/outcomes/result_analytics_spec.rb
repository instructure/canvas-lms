# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe Outcomes::ResultAnalytics do
  # import some stuff so we don't have to spell it out all the time
  let(:ra) { Outcomes::ResultAnalytics }
  let(:time) { Time.zone.now }

  def outcome_from_score(score, args)
    title = args[:title] || "name, o1"
    outcome = args[:outcome] || create_outcome(args)
    user = args[:user] || User.new(id: 10, name: "a")
    LearningOutcomeResult.new(user:,
                              learning_outcome: outcome,
                              score:,
                              title:,
                              submitted_at:
    args[:submitted_time],
                              assessed_at: args[:assessed_time],
                              hide_points: args[:hide_points])
  end

  def create_outcome(args)
    # score defaulting to highest is to ensure we don't alter behavior on
    # outcomes that predate the newer calculation methods
    id = args[:id] || 80
    method = args[:method] || "highest"
    criterion = args[:criterion] || LearningOutcome.default_rubric_criterion
    LearningOutcome.new(id:, calculation_method: method, calculation_int: args[:calc_int], rubric_criterion: criterion)
  end

  def create_quiz_outcome_results(outcome, title, *results)
    defaults = {
      user: User.new(id: 10, name: "a"),
      learning_outcome: outcome,
      title:,
      assessed_at: time,
      artifact_type: "Quizzes::QuizSubmission",
      association_type: "Quizzes::Quiz",
      score: 1.0
    }
    results.map do |result|
      result_params = defaults.merge(result)
      LearningOutcomeResult.new(result_params)
    end
  end

  describe "#find_outcome_service_outcome_results" do
    before(:once) do
      course_with_student

      names = %w[Gamma Alpha Beta]
      @students = create_users(Array.new(3) { |i| { name: "User #{i + 1}", sortable_name: "#{names[i]}, User" } }, return_type: :record)

      course_with_user("StudentEnrollment", course: @course, user: @students[0])
      course_with_user("StudentEnrollment", course: @course, user: @students[1])
      course_with_user("StudentEnrollment", course: @course, user: @students[2])

      course_with_teacher(course: @course)
      @outcomes = [outcome_model(context: @course, short_description: "Course outcome 1"), outcome_model(context: @course, short_description: "Course outcome 2")]
      @assignment = assignment_model
      @alignment = @outcome.align(@assignment, @course)
    end

    it "calls get_lmgb_results" do
      quiz = new_quizzes_assignment(course: @course, title: "new quiz")
      outcome_ids = @outcomes.pluck(:id).join(",")
      uuids = "#{@students[0].uuid},#{@students[1].uuid},#{@students[2].uuid}"
      expect(ra).to receive(:get_lmgb_results).with(@course, quiz.id.to_s, "canvas.assignment.quizzes", outcome_ids, uuids).and_return(nil)
      opts = { context: @course, users: @students, outcomes: @outcomes, assignments: [@assignment] }
      ra.send(:find_outcomes_service_outcome_results, opts)
    end

    it "returns nil if session user is a student and there are more than 1 users sent in the opts" do
      opts = { context: @course, users: @students, outcomes: @outcomes, assignments: [@assignment] }
      results = ra.find_outcomes_service_outcome_results(opts)
      expect(results).to be_nil
    end

    describe "#handle_outcomes_service_results" do
      it "logs warning and returns nil if results are nil" do
        allow(Rails.logger).to receive(:warn)
        expect(Rails.logger).to receive(:warn).with(
          "No Outcome Service outcome results found for context: #{@course.uuid}"
        ).once
        results = ra.handle_outcomes_service_results(nil, @course, @students, @outcomes, [@assignment])
        expect(results).to be_nil
      end

      it "logs warning and returns nil if results are empty" do
        allow(Rails.logger).to receive(:warn)
        expect(Rails.logger).to receive(:warn).with(
          "No Outcome Service outcome results found for context: #{@course.uuid}"
        ).once
        results = ra.handle_outcomes_service_results({}, @course, @students, @outcomes, [@assignment])
        expect(results).to be_nil
      end

      it "calls resolve_outcome_results" do
        os_results = [
          {
            user_uuid: "someguid",
            percent_score: 1.0,
            points: 3.0,
            points_possible: 3.0,
            external_outcome_id: 123,
            submitted_at: Time.now.utc,
            attempts: {}
          }
        ]
        expect(ra).to receive(:resolve_outcome_results).with(os_results, @course, @students, @outcomes, [@assignment])
        ra.send(:handle_outcomes_service_results, os_results, @course, @students, @outcomes, [@assignment])
      end
    end
  end

  describe "#find_outcome_results" do
    let_once :assignment_2 do
      assignment_model
    end

    before(:once) do
      course_with_student

      names = %w[Gamma Alpha Beta]
      @students = create_users(Array.new(3) { |i| { name: "User #{i + 1}", sortable_name: "#{names[i]}, User" } }, return_type: :record)

      course_with_user("StudentEnrollment", course: @course, user: @students[0])
      course_with_user("StudentEnrollment", course: @course, user: @students[1])
      course_with_user("StudentEnrollment", course: @course, user: @students[2])

      course_with_teacher(course: @course)
      rubric = outcome_with_rubric context: @course
      @assignment = assignment_model
      @alignment = @outcome.align(@assignment, @course)
      @alignment_2 = @outcome.align(assignment_2, @course)
      @rubric_association = rubric.associate_with(@assignment, @course, purpose: "grading")
      @rubric_association_2 = rubric.associate_with(assignment_2, @course, purpose: "grading")
      lor
      lor({ hidden: true, alignment: @alignment_2, association_id: @rubric_association_2.id })
      lor({ hidden: true }, @students[0])
      lor({ hidden: true }, @students[1])
      lor({ hidden: true }, @students[2])
    end

    def lor(opts = {}, user = nil)
      user ||= @student

      LearningOutcomeResult.create!(
        context: @course,
        learning_outcome: @outcome,
        user:,
        alignment: @alignment,
        association_type: "RubricAssociation",
        association_id: @rubric_association.id,
        **opts
      )
    end

    it "does not return hidden outcome results" do
      results = ra.find_outcome_results(@teacher, users: [@student], context: @course, outcomes: [@outcome])
      expect(results.length).to eq 1
    end

    it "returns hidden outcome results when include_hidden is true" do
      results = ra.find_outcome_results(@teacher, users: [@student], context: @course, outcomes: [@outcome], include_hidden: true)
      expect(results.length).to eq 2
    end

    it "does return deleted results" do
      LearningOutcomeResult.last.destroy
      results = ra.find_outcome_results(@student, users: [@student], context: @course, outcomes: [@outcome])
      expect(results.length).to eq 1
    end

    it "does return muted assignment results with auto post policy" do
      @assignment.mute!
      @assignment.ensure_post_policy(post_manually: false)
      results = ra.find_outcome_results(@student, users: [@student], context: @course, outcomes: [@outcome])
      expect(results.length).to eq 1
    end

    it "does not return muted assignment results with manual post policy" do
      @assignment.mute!
      @assignment.ensure_post_policy(post_manually: true)
      results = ra.find_outcome_results(@student, users: [@student], context: @course, outcomes: [@outcome])
      expect(results.length).to eq 0
    end

    it "order results by id on matching learning outcome id and user id" do
      results = ra.find_outcome_results(@teacher, users: [@student], context: @course, outcomes: [@outcome], include_hidden: true)
      expect(results.first.id).to be < results.second.id
    end

    it "orders results by user sortable name" do
      results = ra.find_outcome_results(@teacher,
                                        users: @students << @student,
                                        context: @course,
                                        outcomes: [@outcome],
                                        include_hidden: true)

      sortable_names = results.collect { |r| r.user.sortable_name }
      expect(sortable_names).to eq ["Alpha, User", "Beta, User", "Gamma, User", "User", "User"]
    end
  end

  describe "#rollup_user_results" do
    it "returns a rollup score for each distinct outcome_id" do
      results = [
        outcome_from_score(2.0, {}),
        outcome_from_score(3.0, { id: 81 })
      ]
      rollup = ra.rollup_user_results(results)
      expect(rollup.size).to eq 2
      rollup.each.with_index do |ru, i|
        expect(ru.outcome_results.first).to eq results[i]
      end
    end

    it "does not return rollup scores when all results are nil" do
      o = (1..3).map do |i|
        outcome_from_score(nil, { method: "decaying_average", calc_int: 75, submitted_time: time - i.days })
        outcome_from_score(nil, { method: "standard_decaying_average", calc_int: 65, submitted_time: time - i.days })
        outcome_from_score(nil, { id: 81, method: "n_mastery", calc_int: 3, submitted_time: time - i.days })
        outcome_from_score(nil, { id: 82, method: "latest", calc_int: 3, submitted_time: time - i.days })
        outcome_from_score(nil, { id: 83, method: "highest", calc_int: 3, submitted_time: time - i.days })
      end
      results = o.flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 0
    end
  end

  describe "#mastery calculation" do
    it "returns maximum score when no method is set" do
      results = [3.0, 1.0].map { |result| outcome_from_score(result, {}) }
      rollup = ra.rollup_user_results(results)
      expect(rollup.size).to eq 1
      expect(rollup[0].count).to eq 2
      expect(rollup[0].score).to eq 3.0
    end

    it "returns maximum score when highest score method is selected" do
      results = [3.0, 1.0].map { |result| outcome_from_score(result, { method: "highest" }) }
      rollup = ra.rollup_user_results(results)
      expect(rollup[0].score).to eq 3.0
      expect(rollup[0].outcome.calculation_method).to eq "highest"
    end

    it "returns correct score when latest score method is selected" do
      submission_time = [nil, time, time - 1.day]
      results = [4.0, 3.0, 1.0].map.with_index do |result, i|
        outcome_from_score(result, { method: "latest", submitted_time: submission_time[i] })
      end
      rollups = ra.rollup_user_results(results)
      expect(rollups[0].score).to eq 3.0
    end

    it "properly calculates results when method is n# of scores for mastery" do
      o1 = [3.0, 1.0].map { |result| outcome_from_score(result, { method: "n_mastery", calc_int: 3 }) }
      o2 = [3.0, 1.0, 2.0].map { |result| outcome_from_score(result, { id: 81, method: "n_mastery", calc_int: 3 }) }
      o3 = [4.0, 5.0, 1.0, 3.0, 2.0, 3.0].map { |result| outcome_from_score(result, { id: 82, method: "n_mastery", calc_int: 3 }) }
      o4 = [1.0, 2.0].map { |result| outcome_from_score(result, { id: 83, method: "n_mastery", calc_int: 1 }) }
      o5 = [1.0, 2.0, 3.0].map { |result| outcome_from_score(result, { id: 84, method: "n_mastery", calc_int: 1 }) }
      o6 = [1.0, 2.0, 3.0, 4.0].map { |result| outcome_from_score(result, { id: 85, method: "n_mastery", calc_int: 1 }) }

      results = [o1, o2, o3, o4, o5, o6].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 6
      expect(rollups.map(&:score)).to eq [nil, nil, 3.75, nil, 3.0, 3.5]
    end

    it "does not error out and correctly averages when a result has a score of nil" do
      results = [4.0, 5.0, 1.0, 3.0, nil, 3.0].map do |result|
        outcome_from_score(result, { method: "n_mastery", calc_int: 3 })
      end
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [3.75]
    end

    it "properly calculates results when method is decaying average" do
      o1 = outcome_from_score(3.0, { method: "decaying_average", calc_int: 75, submitted_time: time })
      o2 = [4.0, 5.0, 1.0, 3.0].map.with_index do |result, i|
        outcome_from_score(result, { id: 81, method: "decaying_average", calc_int: 75, name: "name, o2", submitted_time: time - i.days })
      end
      results = [o1, o2].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 2
      expect(rollups.map(&:score)).to eq [3.0, 3.75]
    end

    it "properly sorts results when there is no submitted_at time on one or many results" do
      o1 = [3.0, 2.0].map.with_index do |result, i|
        outcome_from_score(result, { method: "decaying_average", calc_int: 65, assessed_time: time - i.days })
      end
      o2 = [4.0, 5.0, 1.0].map.with_index do |result, i|
        outcome_from_score(result, { id: 81, method: "decaying_average", calc_int: 75, name: "name, o2", assessed_time: time - i.days })
      end
      o2 << outcome_from_score(3.0, { id: 81, method: "decaying_average", calc_int: 75, name: "name, o2", submitted_time: time - 3.days })
      results = [o1, o2].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 2
      expect(rollups.map(&:score)).to eq [2.65, 3.75]
    end

    it "rounds results for decaying average and n_mastery methods" do
      o1 = [3.0, 2.0].map.with_index do |result, i|
        outcome_from_score(result, { method: "decaying_average", calc_int: 65, assessed_time: time - i.days })
      end
      o2 = outcome_from_score(2.123, { id: 81, method: "decaying_average", calc_int: 65 })
      o3 = [3.0, 4.0, 3.0].map { |result| outcome_from_score(result, { id: 82, method: "n_mastery", calc_int: 3 }) }
      results = [o1, o2, o3].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 3
      expect(rollups.map(&:score)).to eq [2.65, 2.12, 3.33]
    end

    it "properly calculates results for New standard_decaying_average method when feature_flag is ON" do
      LoadAccount.default_domain_root_account.enable_feature!(:outcomes_new_decaying_average_calculation)
      o1 = outcome_from_score(3.0, { method: "standard_decaying_average", calc_int: 65, submitted_time: time })
      o2 = [2.0, 3.0, 4.0].map.with_index do |result, i|
        outcome_from_score(result, { id: 81, method: "standard_decaying_average", calc_int: 65, name: "name, o2", submitted_time: time + i.days })
      end
      results = [o1, o2].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 2
      expect(rollups.map(&:score)).to eq [3.0, 3.53]
    end

    it "properly calculates results for OLD decaying_average method when feature_flag is OFF" do
      LoadAccount.default_domain_root_account.disable_feature!(:outcomes_new_decaying_average_calculation)
      o1 = outcome_from_score(3.0, { method: "decaying_average", calc_int: 65, submitted_time: time })
      o2 = [2.0, 3.0, 4.0].map.with_index do |result, i|
        outcome_from_score(result, { id: 81, method: "decaying_average", calc_int: 65, name: "name, o2", submitted_time: time + i.days })
      end
      results = [o1, o2].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 2
      expect(rollups.map(&:score)).to eq [3.0, 3.48]
    end

    it "does not error out and correctly averages when a result has a score of nil when method is standard_decaying_average and feature_flag is ON" do
      LoadAccount.default_domain_root_account.enable_feature!(:outcomes_new_decaying_average_calculation)
      results = [2.0, 3.0, nil, 4.0].map do |result|
        outcome_from_score(result, { method: "standard_decaying_average", calc_int: 65 })
      end
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [3.53]
    end
  end

  describe "#outcome_results_rollups" do
    before do
      allow(ActiveRecord::Associations).to receive(:preload)
    end

    it "returns a rollup for each distinct user_id" do
      results = [
        outcome_from_score(4.0, {}),
        outcome_from_score(5.0, { user: User.new(id: 20, name: "b") }),
        outcome_from_score(3.0, { user: User.new(id: 20, name: "b") })
      ]
      users = [User.new(id: 10, name: "a"), User.new(id: 30, name: "c")]
      rollups = ra.outcome_results_rollups(results:, users:)
      rollup_scores = ra.rollup_user_results(results).map(&:outcome_results).flatten
      rollups.each.with_index do |rollup, _|
        expect(rollup.scores.map(&:outcome_results).flatten).to eq(rollup_scores.find_all { |score| score.user.id == rollup.context.id })
      end
    end

    it "correctly handles users with the same name" do
      results = [
        outcome_from_score(5.0, { method: "decaying_average", user: User.new(id: 20, name: "b") }),
        outcome_from_score(3.0, { method: "decaying_average", user: User.new(id: 30, name: "b") }),
        outcome_from_score(2.0, { method: "decaying_average", user: User.new(id: 30, name: "b") }),
        outcome_from_score(4.0, { method: "decaying_average", user: User.new(id: 20, name: "b") })
      ]
      users = [User.new(id: 20, name: "b"), User.new(id: 30, name: "b")]
      rollups = ra.outcome_results_rollups(results:, users:)
      scores_by_user = [4.35, 2.35]
      expect(rollups.flat_map(&:scores).map(&:score)).to eq scores_by_user
    end

    it "excludes missing user rollups" do
      results = [
        outcome_from_score(5.0, { user: User.new(id: 20, name: "b") })
      ]
      users = [User.new(id: 10, name: "a"), User.new(id: 30, name: "c")]
      rollups = ra.outcome_results_rollups(results:, users:, excludes: ["missing_user_rollups"])
      expect(rollups.length).to eq 1
    end

    it "returns hide_points value of true if all results have hide_points set to true" do
      results = [
        outcome_from_score(4.0, { hide_points: true }),
        outcome_from_score(5.0, { hide_points: true }),
      ]
      rollups = ra.rollup_user_results(results)
      expect(rollups[0].hide_points).to be true
    end

    it "returns hide_points value of false if any results have hide_points set to false" do
      results = [
        outcome_from_score(4.0, { hide_points: true }),
        outcome_from_score(5.0, { hide_points: false }),
      ]
      rollups = ra.rollup_user_results(results)
      expect(rollups[0].hide_points).to be false
    end
  end

  describe "#aggregate_outcome_results_rollup" do
    before do
      allow(ActiveRecord::Associations).to receive(:preload)
    end

    context "with n_mastery outcome and results below mastery" do
      let(:n_mastery) { create_outcome(method: "n_mastery", calc_int: 5) }
      let(:results) do
        [
          outcome_from_score(0.0, { outcome: n_mastery }),
          outcome_from_score(0.0, { outcome: n_mastery, user: User.new(id: 20, name: "b") })
        ]
      end

      it "returns average aggregate score of nil" do
        fake_context = User.new(id: 42, name: "fake")
        aggregate_result = ra.aggregate_outcome_results_rollup(results, fake_context)
        expect(aggregate_result.scores.map(&:score)).to eq [nil]
      end

      it "returns median aggregate score of nil" do
        fake_context = User.new(id: 42, name: "fake")
        aggregate_result = ra.aggregate_outcome_results_rollup(results, fake_context, "median")
        expect(aggregate_result.scores.map(&:score)).to eq [nil]
      end
    end

    context "with results" do
      let(:results) do
        [
          # the next two scores for the same user and outcome get combined into an
          # overall score of 1.0 using the "highest" calculation method
          outcome_from_score(0.0, {}),
          outcome_from_score(1.0, {}),
          outcome_from_score(5.0, { id: 81 }),
          outcome_from_score(2.0, { user: User.new(id: 20, name: "b") }),
          outcome_from_score(6.0, { id: 81, user: User.new(id: 20, name: "b") }),
          outcome_from_score(3.0, { user: User.new(id: 30, name: "c") }),
          outcome_from_score(40.0, { user: User.new(id: 40, name: "d") }),
          outcome_from_score(70.0, { id: 81, user: User.new(id: 40, name: "d") })
        ]
      end

      let(:lower_results) do
        [
          # the next two scores for the same user and outcome get combined into an
          # overall score of 0.0 using the "highest" calculation method
          outcome_from_score(1.0, {}),
          outcome_from_score(0.0, {}),
          outcome_from_score(5.0, { id: 81 }),
          outcome_from_score(6.0, { id: 81, user: User.new(id: 20, name: "b") }),
          outcome_from_score(2.0, { user: User.new(id: 20, name: "b") }),
          outcome_from_score(3.0, { user: User.new(id: 30, name: "c") }),
          outcome_from_score(70.0, { id: 81, user: User.new(id: 40, name: "d") }),
          outcome_from_score(40.0, { user: User.new(id: 40, name: "d") })
        ]
      end

      it "overrides the aggregate score calculation when feature flag enabled and Account method set" do
        account = Account.create!(outcome_calculation_method: OutcomeCalculationMethod.new(calculation_method: "latest"))
        account.root_account.set_feature_flag!(:account_level_mastery_scales, "on")
        course = Course.create(account:)
        aggregate_result = ra.aggregate_outcome_results_rollup(lower_results, course)
        expect(aggregate_result.size).to eq 2
        expect(aggregate_result.scores.map(&:score)).to eq [11.25, 27.0]
        expect(aggregate_result.scores[0].outcome_results.size).to eq 4
        expect(aggregate_result.scores[1].outcome_results.size).to eq 3
      end

      it "overrides the aggregate score calculation when feature flag enabled and Course method set" do
        Account.default.set_feature_flag!(:account_level_mastery_scales, "on")
        course = Course.create(account: Account.default,
                               outcome_calculation_method: OutcomeCalculationMethod.create(calculation_method: "latest"))
        aggregate_result = ra.aggregate_outcome_results_rollup(lower_results, course)

        expect(aggregate_result.size).to eq 2
        expect(aggregate_result.scores.map(&:score)).to eq [11.25, 27.0]
        expect(aggregate_result.scores[0].outcome_results.size).to eq 4
        expect(aggregate_result.scores[1].outcome_results.size).to eq 3
      end

      it "reverts to the original score calculation when feature flag enabled, but no Course/Account method set" do
        Account.default.set_feature_flag!(:account_level_mastery_scales, "on")
        course = Course.create(account: Account.default)
        aggregate_result = ra.aggregate_outcome_results_rollup(lower_results, course)
        # Defaults to using "highest" calculation
        expect(aggregate_result.size).to eq 2
        expect(aggregate_result.scores.map(&:score)).to eq [11.5, 27.0]
        expect(aggregate_result.scores[0].outcome_results.size).to eq 4
        expect(aggregate_result.scores[1].outcome_results.size).to eq 3
      end

      it "returns one rollup with the rollup averages and no feature flag enabled" do
        fake_context = User.new(id: 42, name: "fake")
        aggregate_result = ra.aggregate_outcome_results_rollup(results, fake_context)
        expect(aggregate_result.size).to eq 2
        expect(aggregate_result.scores.map(&:score)).to eq [11.5, 27.0]
        expect(aggregate_result.scores[0].outcome_results.size).to eq 4
        expect(aggregate_result.scores[1].outcome_results.size).to eq 3
      end

      it "returns one rollup with the rollup medians" do
        fake_context = User.new(id: 42, name: "fake")
        aggregate_result = ra.aggregate_outcome_results_rollup(results, fake_context, "median")
        expect(aggregate_result.size).to eq 2
        expect(aggregate_result.scores.map(&:score)).to eq [2.5, 6]
        expect(aggregate_result.scores[0].outcome_results.size).to eq 4
        expect(aggregate_result.scores[1].outcome_results.size).to eq 3
      end
    end

    it "properly calculates a mix of assignment and quiz results" do
      fake_context = User.new(id: 42, name: "fake")
      o1 = LearningOutcome.new(id: 80, calculation_method: "decaying_average", calculation_int: 65)
      o2 = LearningOutcome.new(id: 81, calculation_method: "n_mastery", calculation_int: 3)
      q_results1 = create_quiz_outcome_results(
        o1,
        "name, o1",
        { score: 7.0, percent: 0.4, possible: 1.0, association_id: 1 },
        { score: 12.0, assessed_at: time - 1.day, percent: 0.9, possible: 1.0, association_id: 2 }
      )
      q_results2 = create_quiz_outcome_results(
        o2,
        "name, o2",
        { score: 30.0, percent: 0.2, possible: 1.0, association_id: 1 },
        { score: 75.0, percent: 0.5, possible: 1.0, association_id: 2 },
        { score: 120.0, percent: 0.8, possible: 1.0, association_id: 3 }
      )
      a_results1 = [
        outcome_from_score(3.0, { submitted_time: time - 2.days, outcome: o1 }),
        outcome_from_score(2.0, { submitted_time: time - 3.days, outcome: o1 })
      ]
      a_results2 = [
        outcome_from_score(3.0, { outcome: o2 }),
        outcome_from_score(3.5, { outcome: o2 })
      ]
      results = [q_results1, q_results2, a_results1, a_results2].flatten
      aggregate_result = ra.aggregate_outcome_results_rollup(results, fake_context)
      expect(aggregate_result.size).to eq 2
      expect(aggregate_result.scores.map(&:score)).to eq [2.41, 3.5]
    end

    it "falls back to using mastery score if points possible is 0 or nil" do
      fake_context = User.new(id: 42, name: "fake")
      o = LearningOutcome.new(id: 81,
                              calculation_method: "latest",
                              calculation_int: nil,
                              rubric_criterion: { mastery_points: 3.0, points_possible: 0.0 })
      q_results = create_quiz_outcome_results(o,
                                              "name, o",
                                              { score: 10.0, percent: 0.7, possible: 1.0, association_id: 1 })
      aggregate_result = ra.aggregate_outcome_results_rollup([q_results].flatten, fake_context)
      expect(aggregate_result.scores.map(&:score)).to eq [2.1]
    end
  end

  describe "#rating_percents" do
    before do
      allow(ActiveRecord::Associations).to receive(:preload)
    end

    it "computes percents" do
      results = [
        outcome_from_score(4.0, {}),
        outcome_from_score(5.0, { user: User.new(id: 20, name: "b") }),
        outcome_from_score(3.0, { user: User.new(id: 20, name: "b") })
      ]
      users = [User.new(id: 10, name: "a"), User.new(id: 30, name: "c")]
      rollups = ra.outcome_results_rollups(results:, users:)
      percents = ra.rating_percents(rollups)
      expect(percents).to eq({ 80 => [50, 50, 0] })
    end

    describe "with the account_level_mastery_scales FF" do
      before do
        @course = course_factory
      end

      describe "enabled" do
        before do
          @course.account.enable_feature!(:account_level_mastery_scales)
        end

        it "uses the context resolved_outcome_proficiency if a context is provided" do
          results = [
            outcome_from_score(4.0, {}),
            outcome_from_score(5.0, { user: User.new(id: 20, name: "b") }),
            outcome_from_score(2.0, { user: User.new(id: 21, name: "c") })
          ]
          users = [User.new(id: 10, name: "a"), User.new(id: 30, name: "c")]
          rollups = ra.outcome_results_rollups(results:, users:)
          percents = ra.rating_percents(rollups, context: @course)
          expect(percents).to eq({ 80 => [67, 0, 33, 0, 0] })
        end
      end

      describe "disabled" do
        before do
          @course.account.disable_feature!(:account_level_mastery_scales)
        end

        it "does not use the context resolved_outcome_proficiency if a context is provided" do
          results = [
            outcome_from_score(4.0, {}),
            outcome_from_score(5.0, { user: User.new(id: 20, name: "b") }),
            outcome_from_score(2.0, { user: User.new(id: 21, name: "c") })
          ]
          users = [User.new(id: 10, name: "a"), User.new(id: 30, name: "c")]
          rollups = ra.outcome_results_rollups(results:, users:)
          percents = ra.rating_percents(rollups, context: @course)
          expect(percents).to eq({ 80 => [33, 33, 33] })
        end
      end
    end
  end

  describe "handling quiz outcome results objects" do
    it "scales quiz scores to rubric score" do
      o1 = LearningOutcome.new(id: 80, calculation_method: "decaying_average", calculation_int: 65)
      o2 = LearningOutcome.new(id: 81, calculation_method: "n_mastery", calculation_int: 3)
      o3 = LearningOutcome.new(id: 82, calculation_method: "n_mastery", calculation_int: 3)
      res1 = create_quiz_outcome_results(o1,
                                         "name, o1",
                                         { score: 7.0, percent: 0.4, possible: 1.0, association_id: 1 },
                                         { score: 12.0, assessed_at: time - 1.day, percent: 0.9, possible: 1.0, association_id: 2 })
      res2 = create_quiz_outcome_results(o2,
                                         "name, o2",
                                         { score: 30.0, percent: 0.2, possible: 1.0, association_id: 1 },
                                         { score: 75.0, percent: 0.5, possible: 1.0, association_id: 2 },
                                         { score: 120.0, percent: 0.8, possible: 1.0, association_id: 3 })
      res3 = create_quiz_outcome_results(o3,
                                         "name, o3",
                                         { score: 90.0, percent: 0.2, possible: 1.0, association_id: 1 },
                                         { score: 75.0, percent: 0.7, possible: 1.0, association_id: 2 },
                                         { score: 120.0, percent: 0.8, possible: 1.0, association_id: 3 },
                                         { score: 100.0, percent: 0.9, possible: 1.0, association_id: 4 })
      results = [res1, res2, res3].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 3
      expect(rollups.map(&:score)).to eq [2.88, nil, 4.0]
    end
  end

  describe "handling scores for matching outcomes in results" do
    it "does not create false matches" do
      o1 = LearningOutcome.new(id: 80, calculation_method: "decaying_average", calculation_int: 65, rubric_criterion: { mastery_points: 5.0, points_possible: 5 })
      o2 = LearningOutcome.new(id: 81, calculation_method: "decaying_average", calculation_int: 65, rubric_criterion: { mastery_points: 5.0, points_possible: 5 })
      o3 = LearningOutcome.new(id: 82, calculation_method: "decaying_average", calculation_int: 65, rubric_criterion: { mastery_points: 5.0, points_possible: 5 })
      o4 = LearningOutcome.new(id: 83, calculation_method: "decaying_average", calculation_int: 65, rubric_criterion: { mastery_points: 5.0, points_possible: 5 })
      assignment_params = {
        artifact_type: "RubricAssessment",
        association_type: "Assignment"
      }
      res1 = create_quiz_outcome_results(o1,
                                         "name, o1",
                                         { percent: 0.6, possible: 1.0, association_id: 1 },
                                         { assessed_at: time - 1.day, percent: 0.7, possible: 1.0, association_id: 2 },
                                         { assessed_at: time - 2.days, percent: 0.4, possible: 1.0, association_id: 3 })
      res2 = create_quiz_outcome_results(o2,
                                         "name, o2",
                                         { percent: 0.6, possible: 2.0, association_id: 1 },
                                         { assessed_at: time - 1.day, percent: 0.7, possible: 3.0, association_id: 2 })
      res3 = create_quiz_outcome_results(o3,
                                         "name, o3",
                                         { percent: 0.6, possible: 1.0, association_id: 1 },
                                         { assessed_at: time - 1.day, percent: 0.6, possible: 1.0, association_id: 1 }.merge(assignment_params))
      res4 = create_quiz_outcome_results(o4,
                                         "name, o4",
                                         { percent: 0.6, possible: 2.0, association_id: 1 },
                                         { assessed_at: time - 1.day, percent: 0.7, possible: 3.0, association_id: 1 }.merge(assignment_params))
      results = [res1, res2, res3, res4].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [2.91, 3.18, 3.0, 3.18]
    end

    it "properly aligns and weights decaying average results for matches" do
      o1 = LearningOutcome.new(id: 80, calculation_method: "decaying_average", calculation_int: 65, rubric_criterion: { mastery_points: 5.0, points_possible: 5 })
      o2 = LearningOutcome.new(id: 81, calculation_method: "decaying_average", calculation_int: 65, rubric_criterion: { mastery_points: 5.0, points_possible: 5 })
      o3 = LearningOutcome.new(id: 82, calculation_method: "decaying_average", calculation_int: 65, rubric_criterion: { mastery_points: 5.0, points_possible: 5 })

      # res1 reflects two quizzes. each quiz contain matching outcome alignments
      # each question is equally weighted at 1/3 of total possible (3.0)
      # quiz 1 results should be 2.83 (0.6 * 0.333 * 5) + (0.7 * 0.333 * 5) + (0.4 * 0.333 * 5)
      # quiz 2 result should be 3.17 (0.5 * 0.333 * 5) + (0.8 * 0.333 * 5) + (0.6 * 0.333 * 5)
      # should evaluate as (3.17 + 3.17 + 3.17 + 2.83 + 2.83) / 5 * 0.35 + (2.83 * 0.65)
      res1 = create_quiz_outcome_results(o1,
                                         "name, o1",
                                         { percent: 0.6, possible: 1.0, association_id: 1 },
                                         { percent: 0.7, possible: 1.0, association_id: 1 },
                                         { percent: 0.4, possible: 1.0, association_id: 1 },
                                         { assessed_at: time - 1.day, percent: 0.5, possible: 1.0, association_id: 2 },
                                         { assessed_at: time - 1.day, percent: 0.8, possible: 1.0, association_id: 2 },
                                         { assessed_at: time - 1.day, percent: 0.6, possible: 1.0, association_id: 2 })

      # res2 reflects same setup as res1, but with variable question weights
      # quiz 1 results should be 1.55 (0.6 * 0.3 * 5) + (0.1 * 0.5 * 5) + (0.4 * 0.2 * 5)
      # quiz 2 results should be 2.95 (0.5 * 0.5 * 5) + (0.8 * 0.2 * 5) + (0.6 * 0.3 * 5)
      # should evaluate as (2.95 + 2.95 + 2.95 + 1.55 + 1.55) / 5 * 0.35 + (1.55 * 0.65)
      res2 = create_quiz_outcome_results(o2,
                                         "name, o2",
                                         { percent: 0.6, possible: 3.0, association_id: 1 },
                                         { percent: 0.1, possible: 5.0, association_id: 1 },
                                         { percent: 0.4, possible: 2.0, association_id: 1 },
                                         { assessed_at: time - 1.day, percent: 0.5, possible: 5.0, association_id: 2 },
                                         { assessed_at: time - 1.day, percent: 0.8, possible: 2.0, association_id: 2 },
                                         { assessed_at: time - 1.day, percent: 0.6, possible: 3.0, association_id: 2 })

      # res 3 reflects a situation where only one quiz has been evaluated
      # quiz 1 results should be 3.3 (0.6 * 0.4 * 5) + (0.7 * 0.6 * 5)
      # should evaluate as 3.3 / 1 * 0.35 + (3.3 * 0.65)
      res3 = create_quiz_outcome_results(o3,
                                         "name, o3",
                                         { percent: 0.6, possible: 2.0, association_id: 1 },
                                         { percent: 0.7, possible: 3.0, association_id: 1 })
      results = [res1, res2, res3].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [2.9, 1.84, 3.3]
    end

    it "properly aligns and weights latest score results for matches" do
      o1 = LearningOutcome.new(id: 80, calculation_method: "latest", calculation_int: nil, rubric_criterion: { points_possible: 5, mastery_points: 5.0 })
      o2 = LearningOutcome.new(id: 81, calculation_method: "latest", calculation_int: nil, rubric_criterion: { points_possible: 5, mastery_points: 5.0 })

      # quiz 1 results should be 2.83 (0.6 * 0.333 * 5) + (0.7 * 0.333 * 5) + (0.4 * 0.333 * 5)
      # quiz 2 result should be 3.17 (0.5 * 0.333 * 5) + (0.8 * 0.333 * 5) + (0.6 * 0.333 * 5)
      res1 = create_quiz_outcome_results(o1,
                                         "name, o1",
                                         { percent: 0.6, possible: 1.0, association_id: 1 },
                                         { percent: 0.7, possible: 1.0, association_id: 1 },
                                         { percent: 0.4, possible: 1.0, association_id: 1 },
                                         { assessed_at: time - 1.day, percent: 0.5, possible: 1.0, association_id: 2 },
                                         { assessed_at: time - 1.day, percent: 0.6, possible: 1.0, association_id: 2 },
                                         { assessed_at: time - 1.day, percent: 0.8, possible: 1.0, association_id: 2 })

      # quiz 1 results should be 1.55 (0.6 * 0.3 * 5) + (0.1 * 0.5 * 5) + (0.4 * 0.2 * 5)
      # quiz 2 results should be 2.95 (0.5 * 0.5 * 5) + (0.8 * 0.2 * 5) + (0.6 * 0.3 * 5)
      res2 = create_quiz_outcome_results(o2,
                                         "name, o2",
                                         { percent: 0.6, possible: 3.0, association_id: 1 },
                                         { percent: 0.1, possible: 5.0, association_id: 1 },
                                         { percent: 0.4, possible: 2.0, association_id: 1 },
                                         { assessed_at: time - 1.day, percent: 0.5, possible: 5.0, association_id: 2 },
                                         { assessed_at: time - 1.day, percent: 0.8, possible: 2.0, association_id: 2 },
                                         { assessed_at: time - 1.day, percent: 0.6, possible: 3.0, association_id: 2 })
      results = [res1, res2].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [2.83, 1.55]
    end

    it "does not use aggregate score when calculation method is 'highest'" do
      o = LearningOutcome.new(id: 80, calculation_method: "highest", calculation_int: nil, rubric_criterion: { points_possible: 5, mastery_points: 5 })

      res = create_quiz_outcome_results(o,
                                        "name, o1",
                                        { percent: 0.6, possible: 1.0, association_id: 1 },
                                        { percent: 0.7, possible: 1.0, association_id: 1 },
                                        { percent: 0.4, possible: 1.0, association_id: 1 },
                                        { assessed_at: time - 1.day, percent: 0.5, possible: 1.0, association_id: 2 },
                                        { assessed_at: time - 1.day, percent: 0.6, possible: 1.0, association_id: 2 },
                                        { assessed_at: time - 1.day, percent: 0.8, possible: 1.0, association_id: 2 })

      results = [res].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [4.0]
    end

    it "does not use aggregate score when calculation method is 'n_mastery'" do
      o = LearningOutcome.new(id: 80, calculation_method: "n_mastery", calculation_int: 3)

      res = create_quiz_outcome_results(o,
                                        "name, o1",
                                        { percent: 0.6, possible: 1.0, association_id: 1 },
                                        { percent: 0.7, possible: 1.0, association_id: 1 },
                                        { percent: 0.4, possible: 1.0, association_id: 1 },
                                        { assessed_at: time - 1.day, percent: 0.5, possible: 1.0, association_id: 2 },
                                        { assessed_at: time - 1.day, percent: 0.6, possible: 1.0, association_id: 2 },
                                        { assessed_at: time - 1.day, percent: 0.8, possible: 1.0, association_id: 2 })

      results = [res].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [3.38]
    end
  end
end

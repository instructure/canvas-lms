# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

# These specs assert that a JSON AuthoritativeResult after transformation results the same rollup
# as if it was native.
#
# Some carefully chosen scenarios from result_analytics_spec.rb are replicated here, for which each:
#
#  - a LearningOutcomeResult collection is built
#  - this collection is transformed into a JSON object, mocking a request to the OS
#  - both collections are fed to rollup computation
#  - the resuting rollups are then compared
#  - and, also,
#    - we assert that the native LearningOutcomeResult collection built for the scenario
#      is adequate to the test
#
# The last item is important because the code that builds the native test case is not verbatim of
# result_analytics_spec.rb, hence we must make sure that they represent the scenario being tested.
#
# All the specs:
#
#      - builds a native LearningOutcomeResult collection using code copied and adjusted from result_analytics_spec.rb
#        - stored as `lor` (Learning Outcome Result)
#      - transforms `lor` into an equivalent JSON AR collection
#      - feds both to ResultAnalytics::rollup_user_results
#        - results stored as `from_lor` and `from_ar`
#
#      - ** asserts that `from_lor` passes the tests as coded in result_analytics_spec.rb **
#
#      - compare both results

describe OutcomesServiceAuthoritativeResultsHelper do
  # helper matcher to assert that, after:
  #   - transforming a JSON AuthoritativeResult collection into LearningOutcomeResults, and,
  #   - calculating the resulting RollupScores
  # the resulting collection will not differ as if they came from native Canvas' data
  RSpec::Matchers.define :be_eq_rollup do |expected_rollup|
    match do |actual_rollup|
      actual_rollup.each do |o|
        o.outcome_results.each do |lor|
          # the properties below are removed from the native Canvas' collection
          # since they cannot be computed from a AuthoritativeResult collection
          lor.association_id = nil
          lor.association_type = nil
          lor.id = nil
          lor.content_tag_id = nil
          lor.context_code = nil
        end
      end

      JSON.parse(actual_rollup.to_json).eql? JSON.parse(expected_rollup.to_json)
    end
  end

  # import some stuff so we don't have to spell it out all the time
  let(:ra) { Outcomes::ResultAnalytics }
  let(:time) { Time.zone.now }

  before(:once) do
    names = %w[Gamma Alpha Beta]

    course_factory
    course_with_teacher(course: @course)

    @students = create_users(names.map { |name| { name: "User #{name}", sortable_name: "#{name}, User" } }, return_type: :record)

    @students.each do |s|
      course_with_user("StudentEnrollment", course: @course, user: s)
    end
  end

  def create_outcome(args = {})
    args[:short_description] ||= Time.zone.now.to_s
    args[:context] ||= @course
    @outcome = LearningOutcome.create!(**args)
    @outcome
  end

  def create_alignment
    rubric = outcome_with_rubric context: @course, outcome: @outcome
    @assignment = assignment_model context: @course
    @alignment = @outcome.align(@assignment, @course)
    @rubric_association = rubric.associate_with(@assignment, @course, purpose: "grading")
    @assignment
  end

  def create_learning_outcome_result(user, score, args = {})
    title = "#{user.name}, #{@assignment.name}"
    mastery = (score || 0) >= @outcome.mastery_points
    submitted_at = args[:submitted_at] || time

    LearningOutcomeResult.create!(
      learning_outcome: @outcome,
      user: user,
      context: @course,
      alignment: @alignment,
      associated_asset: @assignment,
      association_type: "RubricAssociation",
      association_id: @rubric_association.id,
      title: title,
      score: score,
      possible: @outcome.points_possible,
      mastery: mastery,
      created_at: submitted_at,
      updated_at: submitted_at,
      submitted_at: submitted_at,
      assessed_at: submitted_at
    )
  end

  # Mocks calls to the OS endpoints:
  #
  #   - retrieving data from the Canvas' LearningOutcomeResult table
  #   - transforming this data into a collection of JSON AuthoritativeResult objects
  def authoritative_results_from_db
    {
      results:
        LearningOutcomeResult.all.map do |lor|
          {
            user_uuid: lor.user.uuid,
            points: lor.score,
            points_possible: lor.possible,
            external_outcome_id: lor.learning_outcome.id,
            attempts: nil,
            associated_asset_type: nil,
            associated_asset_id: lor.alignment.content_id,
            artifact_type: nil,
            artifact_id: nil,
            submitted_at: lor.submitted_at
          }
        end
    }.to_json
  end

  describe "#rollup_user_results" do
    it "returns a rollup score for each distinct outcome_id" do
      create_outcome
      create_alignment
      create_learning_outcome_result @students[0], 1.0

      create_outcome
      create_alignment
      create_learning_outcome_result @students[0], 3.0

      from_lor = rollup_user_results LearningOutcomeResult.all.to_a
      from_ar = json_to_rollup_scores(authoritative_results_from_db)

      expect(from_lor.size).to eq 2
      from_lor.each_with_index do |ru, i|
        expect(ru.outcome_results.first).to eq LearningOutcomeResult.all[i]
      end

      expect(from_lor).to be_eq_rollup from_ar
    end

    it "does not return rollup scores when all results are nil" do
      outcomes = [
        create_outcome({ calculation_method: "decaying_average", calculation_int: 75 }),
        create_outcome({ calculation_method: "n_mastery", calculation_int: 3 }),
        create_outcome({ calculation_method: "latest" }),
        create_outcome({ calculation_method: "highest" })
      ]

      (1..3).each do |i|
        (0..3).each do |j|
          @outcome = outcomes[j]
          create_alignment
          create_learning_outcome_result @students[0], nil, { submitted_at: time - i.days }
        end
      end

      from_lor = rollup_user_results LearningOutcomeResult.all.to_a
      from_ar = json_to_rollup_scores(authoritative_results_from_db)

      expect(from_lor.size).to eq 0

      expect(from_lor).to be_eq_rollup from_ar
    end
  end

  describe "#mastery calculation" do
    it "returns maximum score when highest score method is selected" do
      create_outcome({ calculation_method: "highest" })

      [1.0, 3.0].each do |r|
        create_alignment
        create_learning_outcome_result @students[0], r
      end

      from_lor = rollup_user_results LearningOutcomeResult.all.to_a
      from_ar = json_to_rollup_scores(authoritative_results_from_db)

      expect(from_lor.size).to eq 1
      expect(from_lor[0].count).to eq 2
      expect(from_lor[0].score).to eq 3.0

      expect(from_lor).to be_eq_rollup from_ar
    end

    it "returns correct score when latest score method is selected" do
      create_outcome({ calculation_method: "latest" })

      submission_time = [nil, time, time - 1.day]
      [4.0, 3.0, 1.0].each_with_index do |r, i|
        create_alignment
        create_learning_outcome_result @students[0], r, { submitted_at: submission_time[i] }
      end

      from_lor = rollup_user_results LearningOutcomeResult.all.to_a
      from_ar = json_to_rollup_scores(authoritative_results_from_db)

      expect(from_lor[0].score).to eq 3.0

      expect(from_lor).to be_eq_rollup from_ar
    end

    it "properly calculates results when method is n# of scores for mastery" do
      def create_from_scores(scores, calculation_int)
        create_outcome({ calculation_method: "n_mastery", calculation_int: calculation_int })

        scores.each do |r|
          create_alignment
          create_learning_outcome_result @students[0], r
        end
      end

      create_from_scores [3.0, 1.0], 3
      create_from_scores [3.0, 1.0, 2.0], 3
      create_from_scores [4.0, 5.0, 1.0, 3.0, 2.0, 3.0], 3
      create_from_scores [1.0, 2.0], 1
      create_from_scores [1.0, 2.0, 3.0], 1
      create_from_scores [1.0, 2.0, 3.0, 4.0], 1

      from_lor = rollup_user_results LearningOutcomeResult.all.to_a
      from_ar = json_to_rollup_scores(authoritative_results_from_db)

      expect(from_lor.size).to eq 6
      # without sorting the arrays this spec may fail at Flakey Spec Catcher
      expect(from_lor.map(&:score).sort_by(&:to_f)).to eq [nil, nil, 3.75, nil, 3.0, 3.5].sort_by(&:to_f)

      expect(from_lor).to be_eq_rollup from_ar
    end

    it "does not error out and correctly averages when a result has a score of nil" do
      create_outcome({ calculation_method: "n_mastery", calculation_int: 3 })

      [4.0, 5.0, 1.0, 3.0, nil, 3.0].each do |r|
        create_alignment
        create_learning_outcome_result @students[0], r
      end

      from_lor = rollup_user_results LearningOutcomeResult.all.to_a
      from_ar = json_to_rollup_scores(authoritative_results_from_db)

      expect(from_lor.map(&:score)).to eq [3.75]

      expect(from_lor).to be_eq_rollup from_ar
    end

    it "properly calculates results when method is decaying average" do
      create_outcome({ calculation_method: "decaying_average", calculation_int: 75 })
      create_alignment
      create_learning_outcome_result @students[0], 3.0, { submitted_at: time }

      create_outcome({ calculation_method: "decaying_average", calculation_int: 75 })
      [4.0, 5.0, 1.0, 3.0].each_with_index do |r, i|
        create_alignment
        create_learning_outcome_result @students[0], r, { submitted_at: time - i.days }
      end

      from_lor = rollup_user_results LearningOutcomeResult.all.to_a
      from_ar = json_to_rollup_scores(authoritative_results_from_db)

      expect(from_lor.size).to eq 2
      # without sorting the arrays this spec may fail at Flakey Spec Catcher
      expect(from_lor.map(&:score).sort_by(&:to_f)).to eq [3.0, 3.75].sort_by(&:to_f)

      expect(from_lor).to be_eq_rollup from_ar
    end
  end
end

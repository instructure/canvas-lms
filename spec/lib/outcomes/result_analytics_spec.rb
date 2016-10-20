#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Outcomes::ResultAnalytics do

  # import some stuff so we don't have to spell it out all the time
  let(:ra) { Outcomes::ResultAnalytics }
  let(:time) { Time.now }
  Rollup = Outcomes::ResultAnalytics::Rollup

  # ResultAnalytics only uses a few fields, so use some mock stuff to avoid all
  # the surrounding database logic
  MockUser = Struct.new(:id, :name)
  MockOutcome = Struct.new(:id, :calculation_method, :calculation_int, :rubric_criterion)
  class MockOutcomeResult < Struct.new(:user, :learning_outcome, :score, :title, :submitted_at, :assessed_at, :artifact_type, :percent, :possible, :association_id, :association_type)
    def initialize *args
      return super unless (args.first.is_a?(Hash) && args.length == 1)
      args.first.each_pair do |k, v|
        self[k] = v
      end
    end

    def learning_outcome_id
      learning_outcome.id
    end

    def user_id
      user.id
    end
  end

  def outcome_from_score(score, args)
    title = args[:title] || "name, o1"
    outcome = args[:outcome] || create_outcome(args)
    user = args[:user] || MockUser[10, 'a']
    MockOutcomeResult[user, outcome, score, title, args[:submitted_time], args[:assessed_time]]
  end

  def create_outcome(args)
    # score defaulting to highest is to ensure we don't alter behavior on
    # outcomes that predate the newer calculation methods
    id = args[:id] || 80
    method = args[:method] || "highest"
    criterion = args[:criterion] || {mastery_points: 3.0}
    MockOutcome[id, method, args[:calc_int], criterion]
  end

  def create_quiz_outcome_results(outcome, title, *results)
    defaults = {
      user: MockUser[10, 'a'],
      learning_outcome: outcome,
      title: title,
      assessed_at: time,
      artifact_type: "Quizzes::QuizSubmission",
      association_type: "Quizzes::Quiz",
      score: 1.0
    }
    results.map do |result|
      result_params = defaults.merge(result)
      MockOutcomeResult.new(result_params)
    end
  end

  describe '#rollup_user_results' do
    it 'returns a rollup score for each distinct outcome_id' do
      results = [
        outcome_from_score(2.0, {}),
        outcome_from_score(3.0, {id: 81})
      ]
      rollup = ra.rollup_user_results(results)
      expect(rollup.size).to eq 2
      rollup.each.with_index do |ru, i|
        expect(ru.outcome_results.first).to eq results[i]
      end
    end

    it 'does not return rollup scores when all results are nil' do
      o = (1..3).map do |i|
        outcome_from_score(nil, { method: 'decaying_average', calc_int: 75, submitted_time: time - i.days})
        outcome_from_score(nil, { id: 81, method: 'n_mastery', calc_int: 3, submitted_time: time- i.days})
        outcome_from_score(nil, { id: 82, method: 'latest', calc_int: 3, submitted_time: time- i.days})
        outcome_from_score(nil, { id: 83, method: 'highest', calc_int: 3, submitted_time: time- i.days})
      end
      results = o.flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 0
    end
  end

  describe '#mastery calculation' do
    it 'returns maximum score when no method is set' do
      results = [3.0, 1.0].map{|result| outcome_from_score(result, {})}
      rollup = ra.rollup_user_results(results)
      expect(rollup.size).to eq 1
      expect(rollup[0].count).to eq 2
      expect(rollup[0].score).to eq 3.0
    end

    it 'returns maximum score when highest score method is selected' do
      results = [3.0, 1.0].map{ |result| outcome_from_score(result, {method: 'highest'}) }
      rollup = ra.rollup_user_results(results)
      expect(rollup[0].score).to eq 3.0
      expect(rollup[0].outcome.calculation_method).to eq "highest"
    end

    it 'returns correct score when latest score method is selected' do
      submission_time = [nil, time, time-1.day]
      results = [4.0, 3.0, 1.0].map.with_index do |result, i|
        outcome_from_score(result, {method: 'latest', submitted_time: submission_time[i]})
      end
      rollups = ra.rollup_user_results(results)
      expect(rollups[0].score).to eq 3.0
    end

    it 'properly calculates results when method is n# of scores for mastery' do
      o1 = [3.0, 1.0].map{ |result| outcome_from_score(result, {method: 'n_mastery', calc_int: 3}) }
      o2 = [3.0, 1.0, 2.0].map{ |result| outcome_from_score(result, {id: 81, method: 'n_mastery', calc_int: 3}) }
      o3 = [4.0, 5.0, 1.0, 3.0, 2.0, 3.0].map{ |result| outcome_from_score(result, {id: 82, method: 'n_mastery', calc_int: 3}) }
      o4 = [1.0, 2.0].map{ |result| outcome_from_score(result, {id: 83, method: 'n_mastery', calc_int: 1}) }
      o5 = [1.0, 2.0, 3.0].map{ |result| outcome_from_score(result, {id: 84, method: 'n_mastery', calc_int: 1}) }
      o6 = [1.0, 2.0, 3.0, 4.0].map{ |result| outcome_from_score(result, {id: 85, method: 'n_mastery', calc_int: 1}) }

      results = [o1, o2, o3, o4, o5, o6].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 6
      expect(rollups.map(&:score)).to eq [nil, nil, 3.75, nil, 3.0, 3.5]
    end

    it 'does not error out and correctly averages when a result has a score of nil' do
      results = [4.0, 5.0, 1.0, 3.0, nil, 3.0].map do |result|
        outcome_from_score(result, {method: 'n_mastery', calc_int: 3})
      end
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [3.75]
    end

    it 'properly calculates results when method is decaying average' do
      o1 = outcome_from_score(3.0, {method: 'decaying_average', calc_int: 75, submitted_time: time})
      o2 = [4.0, 5.0, 1.0, 3.0].map.with_index do |result, i|
        outcome_from_score(result, {id: 81, method: 'decaying_average', calc_int: 75, name: 'name, o2', submitted_time: time-i.days})
      end
      results = [o1, o2].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 2
      expect(rollups.map(&:score)).to eq [3.0, 3.75]
    end

    it 'properly sorts results when there is no submitted_at time on one or many results' do
      o1 = [3.0, 2.0].map.with_index do |result, i|
        outcome_from_score(result, {method: 'decaying_average', calc_int: 65, assessed_time: time - i.days})
      end
      o2 = [4.0, 5.0, 1.0].map.with_index do |result, i|
        outcome_from_score(result, {id: 81, method: 'decaying_average', calc_int: 75, name: "name, o2", assessed_time: time-i.days})
      end
      o2 << outcome_from_score(3.0, {id: 81, method: 'decaying_average', calc_int: 75, name: "name, o2", submitted_time: time-3.days})
      results = [o1, o2].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 2
      expect(rollups.map(&:score)).to eq [2.65, 3.75]
    end

    it 'rounds results for decaying average and n_mastery methods' do
      o1 = [3.0, 2.0].map.with_index do |result, i|
        outcome_from_score(result, {method: 'decaying_average', calc_int: 65, assessed_time: time-i.days})
      end
      o2 = outcome_from_score(2.123, {id: 81, method: 'decaying_average', calc_int: 65})
      o3 = [3.0, 4.0, 3.0].map{ |result| outcome_from_score(result, {id: 82, method: 'n_mastery', calc_int: 3}) }
      results = [o1, o2, o3].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 3
      expect(rollups.map(&:score)).to eq [2.65, 2.12, 3.33]
    end
  end

  describe '#outcome_results_rollups' do
    before do
      ActiveRecord::Associations::Preloader.any_instance.stubs(:preload)
    end
    it 'returns a rollup for each distinct user_id' do
      results = [
        outcome_from_score(4.0,{}),
        outcome_from_score(5.0, {user: MockUser[20, 'b']}),
        outcome_from_score(3.0, {user: MockUser[20, 'b']})
      ]
      users = [MockUser[10, 'a'], MockUser[30, 'c']]
      rollups = ra.outcome_results_rollups(results, users)
      rollup_scores = ra.rollup_user_results(results).map(&:outcome_results).flatten
      rollups.each.with_index do |rollup, i|
        expect(rollup.scores.map(&:outcome_results).flatten).to eq rollup_scores.find_all{|score| score.user.id == rollup.context.id}
      end
    end
  end

  describe '#aggregate_outcome_results_rollup' do
    before do
      ActiveRecord::Associations::Preloader.any_instance.stubs(:preload)
    end
    it 'returns one rollup with the rollup averages' do
      fake_context = MockUser.new(42, 'fake')
      results = [
        outcome_from_score(0.0, {}),
        outcome_from_score(1.0, {}),
        outcome_from_score(5.0, {id: 81}),
        outcome_from_score(2.0, {user: MockUser[20, 'b']}),
        outcome_from_score(6.0, {id: 81, user: MockUser[20, 'b']}),
        outcome_from_score(3.0, {user: MockUser[30, 'c']}),
        outcome_from_score(4.0, {user: MockUser[40, 'd']}),
        outcome_from_score(7.0, {id: 81, user: MockUser[40, 'd']})
      ]
      aggregate_result = ra.aggregate_outcome_results_rollup(results, fake_context)
      expect(aggregate_result.size).to eq 2
      expect(aggregate_result.scores.map(&:score)).to eq [2.5, 6.0]
      expect(aggregate_result.scores[0].outcome_results.size).to eq 4
      expect(aggregate_result.scores[1].outcome_results.size).to eq 3
    end

    it "properly calculates a mix of assignment and quiz results" do
      fake_context = MockUser.new(42, 'fake')
      o1 = MockOutcome[80, 'decaying_average', 65, {points_possible: 5}]
      o2 = MockOutcome[81, 'n_mastery', 3, {:mastery_points => 3.0, points_possible: 5}]
      q_results1 = create_quiz_outcome_results(o1, "name, o1",
        {score: 7.0, percent: 0.4, possible: 1.0, association_id: 1},
        {score: 12.0, assessed_at: time - 1.day, percent: 0.9, possible: 1.0, association_id: 2}
      )
      q_results2 = create_quiz_outcome_results(o2, "name, o2",
        {score: 30.0, percent: 0.2, possible: 1.0, association_id: 1},
        {score: 75.0, percent: 0.5, possible: 1.0, association_id: 2},
        {score: 120.0, percent: 0.8, possible: 1.0, association_id: 3}
      )
      a_results1 = [
        outcome_from_score(3.0, {submitted_time: time - 2.days, outcome: o1}),
        outcome_from_score(2.0, {submitted_time: time - 3.days, outcome: o1})
      ]
      a_results2 = [
        outcome_from_score(3.0, {outcome: o2}),
        outcome_from_score(3.5, {outcome: o2})
      ]
      results = [q_results1, q_results2, a_results1, a_results2].flatten
      aggregate_result = ra.aggregate_outcome_results_rollup(results, fake_context)
      expect(aggregate_result.size).to eq 2
      expect(aggregate_result.scores.map(&:score)).to eq [2.41, 3.5]
    end
  end

  describe "handling quiz outcome results objects" do
    it "scales quiz scores to rubric score" do
      o1 = MockOutcome[80, 'decaying_average', 65, {points_possible: 5}]
      o2 = MockOutcome[81, 'n_mastery', 3, {:mastery_points => 3.0, points_possible: 5}]
      o3 = MockOutcome[82, 'n_mastery', 3, {:mastery_points => 3.0, points_possible: 5}]
      res1 = create_quiz_outcome_results(o1, "name, o1",
        {score: 7.0, percent: 0.4, possible: 1.0, association_id: 1},
        {score: 12.0, assessed_at: time - 1.day, percent: 0.9, possible: 1.0, association_id: 2}
      )
      res2 = create_quiz_outcome_results(o2, "name, o2",
        {score: 30.0, percent: 0.2, possible: 1.0, association_id: 1},
        {score: 75.0, percent: 0.5, possible: 1.0, association_id: 2},
        {score: 120.0, percent: 0.8, possible: 1.0, association_id: 3}
      )
      res3 = create_quiz_outcome_results(o3, "name, o3",
        {score: 90.0, percent: 0.2, possible: 1.0, association_id: 1},
        {score: 75.0, percent: 0.7, possible: 1.0, association_id: 2},
        {score: 120.0, percent: 0.8, possible: 1.0, association_id: 3},
        {score: 100.0, percent: 0.9, possible: 1.0, association_id: 4}
      )
      results = [res1, res2, res3].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 3
      expect(rollups.map(&:score)).to eq [2.88, nil, 4.0]
    end
  end

  describe "handling scores for matching outcomes in results" do

    it "does not create false matches" do
      o1 = MockOutcome[80, 'decaying_average', 65, {points_possible: 5}]
      o2 = MockOutcome[81, 'decaying_average', 65, {points_possible: 5}]
      o3 = MockOutcome[82, 'decaying_average', 65, {points_possible: 5}]
      o4 = MockOutcome[83, 'decaying_average', 65, {points_possible: 5}]
      assignment_params = {
        artifact_type: "RubricAssessment",
        association_type: "Assignment"
      }
      res1 = create_quiz_outcome_results(o1, "name, o1",
        {percent: 0.6, possible: 1.0, association_id: 1},
        {assessed_at: time - 1.day, percent: 0.7, possible: 1.0, association_id: 2},
        {assessed_at: time - 2.days, percent: 0.4, possible: 1.0, association_id: 3},
      )
      res2 = create_quiz_outcome_results(o2, "name, o2",
        {percent: 0.6, possible: 2.0, association_id: 1},
        {assessed_at: time - 1.day, percent: 0.7, possible: 3.0, association_id: 2},
      )
      res3 = create_quiz_outcome_results(o3, "name, o3",
        {percent: 0.6, possible: 1.0, association_id: 1},
        {assessed_at: time - 1.day, percent: 0.6, possible: 1.0, association_id: 1}.merge(assignment_params),
      )
      res4 = create_quiz_outcome_results(o4, "name, o4",
        {percent: 0.6, possible: 2.0, association_id: 1},
        {assessed_at: time - 1.day, percent: 0.7, possible: 3.0, association_id: 1}.merge(assignment_params),
      )
      results = [res1, res2, res3, res4].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [2.91, 3.18, 3.0, 3.18]
    end

    it "properly aligns and weights decaying average results for matches" do
      o1 = MockOutcome[80, 'decaying_average', 65, {points_possible: 5}]
      o2 = MockOutcome[81, 'decaying_average', 65, {points_possible: 5}]
      o3 = MockOutcome[82, 'decaying_average', 65, {points_possible: 5}]

      #res1 reflects two quizzes. each quiz contain matching outcome alignments
      #each question is equally weighted at 1/3 of total possible (3.0)
      #quiz 1 results should be 2.83 (0.6 * 0.333 * 5) + (0.7 * 0.333 * 5) + (0.4 * 0.333 * 5)
      #quiz 2 result should be 3.17 (0.5 * 0.333 * 5) + (0.8 * 0.333 * 5) + (0.6 * 0.333 * 5)
      #should evaluate as (3.17 + 3.17 + 3.17 + 2.83 + 2.83) / 5 * 0.35 + (2.83 * 0.65)
      res1 = create_quiz_outcome_results(o1, "name, o1",
        {percent: 0.6, possible: 1.0, association_id: 1},
        {percent: 0.7, possible: 1.0, association_id: 1},
        {percent: 0.4, possible: 1.0, association_id: 1},
        {assessed_at: time - 1.day, percent: 0.5, possible: 1.0, association_id: 2},
        {assessed_at: time - 1.day, percent: 0.8, possible: 1.0, association_id: 2},
        {assessed_at: time - 1.day, percent: 0.6, possible: 1.0, association_id: 2}
      )

      #res2 reflects same setup as res1, but with variable question weights
      #quiz 1 results should be 1.55 (0.6 * 0.3 * 5) + (0.1 * 0.5 * 5) + (0.4 * 0.2 * 5)
      #quiz 2 results should be 2.95 (0.5 * 0.5 * 5) + (0.8 * 0.2 * 5) + (0.6 * 0.3 * 5)
      #should evaluate as (2.95 + 2.95 + 2.95 + 1.55 + 1.55) / 5 * 0.35 + (1.55 * 0.65)
      res2 = create_quiz_outcome_results(o2, "name, o2",
        {percent: 0.6, possible: 3.0, association_id: 1},
        {percent: 0.1, possible: 5.0, association_id: 1},
        {percent: 0.4, possible: 2.0, association_id: 1},
        {assessed_at: time - 1.day, percent: 0.5, possible: 5.0, association_id: 2},
        {assessed_at: time - 1.day, percent: 0.8, possible: 2.0, association_id: 2},
        {assessed_at: time - 1.day, percent: 0.6, possible: 3.0, association_id: 2}
      )

      #res 3 reflects a situation where only one quiz has been evaluated
      #quiz 1 results should be 3.3 (0.6 * 0.4 * 5) + (0.7 * 0.6 * 5)
      #should evaluate as 3.3 / 1 * 0.35 + (3.3 * 0.65)
      res3 = create_quiz_outcome_results(o3, "name, o3",
        {percent: 0.6, possible: 2.0, association_id: 1},
        {percent: 0.7, possible: 3.0, association_id: 1}
      )
      results = [res1, res2, res3].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [2.9, 1.84, 3.3]
    end

    it "properly aligns and weights latest score results for matches" do
      o1 = MockOutcome[80, 'latest', nil, {points_possible: 5}]
      o2 = MockOutcome[81, 'latest', nil, {points_possible: 5}]

      #quiz 1 results should be 2.83 (0.6 * 0.333 * 5) + (0.7 * 0.333 * 5) + (0.4 * 0.333 * 5)
      #quiz 2 result should be 3.17 (0.5 * 0.333 * 5) + (0.8 * 0.333 * 5) + (0.6 * 0.333 * 5)
      res1 = create_quiz_outcome_results(o1, "name, o1",
        {percent: 0.6, possible: 1.0, association_id: 1},
        {percent: 0.7, possible: 1.0, association_id: 1},
        {percent: 0.4, possible: 1.0, association_id: 1},
        {assessed_at: time - 1.day, percent: 0.5, possible: 1.0, association_id: 2},
        {assessed_at: time - 1.day, percent: 0.6, possible: 1.0, association_id: 2},
        {assessed_at: time - 1.day, percent: 0.8, possible: 1.0, association_id: 2},
      )

      #quiz 1 results should be 1.55 (0.6 * 0.3 * 5) + (0.1 * 0.5 * 5) + (0.4 * 0.2 * 5)
      #quiz 2 results should be 2.95 (0.5 * 0.5 * 5) + (0.8 * 0.2 * 5) + (0.6 * 0.3 * 5)
      res2 = create_quiz_outcome_results(o2, "name, o2",
        {percent: 0.6, possible: 3.0, association_id: 1},
        {percent: 0.1, possible: 5.0, association_id: 1},
        {percent: 0.4, possible: 2.0, association_id: 1},
        {assessed_at: time - 1.day, percent: 0.5, possible: 5.0, association_id: 2},
        {assessed_at: time - 1.day, percent: 0.8, possible: 2.0, association_id: 2},
        {assessed_at: time - 1.day, percent: 0.6, possible: 3.0, association_id: 2},
      )
      results = [res1, res2].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [2.83, 1.55]
    end

    it "does not use aggregate score when calculation method is 'highest'" do
      o = MockOutcome[80, 'highest', nil, {points_possible: 5}]

      res = create_quiz_outcome_results(o, "name, o1",
        {percent: 0.6, possible: 1.0, association_id: 1},
        {percent: 0.7, possible: 1.0, association_id: 1},
        {percent: 0.4, possible: 1.0, association_id: 1},
        {assessed_at: time - 1.day, percent: 0.5, possible: 1.0, association_id: 2},
        {assessed_at: time - 1.day, percent: 0.6, possible: 1.0, association_id: 2},
        {assessed_at: time - 1.day, percent: 0.8, possible: 1.0, association_id: 2},
      )

      results = [res].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [4.0]
    end

    it "does not use aggregate score when calculation method is 'n_mastery'" do
      o = MockOutcome[80, 'n_mastery', 3, {points_possible: 5, mastery_points: 3}]

      res = create_quiz_outcome_results(o, "name, o1",
        {percent: 0.6, possible: 1.0, association_id: 1},
        {percent: 0.7, possible: 1.0, association_id: 1},
        {percent: 0.4, possible: 1.0, association_id: 1},
        {assessed_at: time - 1.day, percent: 0.5, possible: 1.0, association_id: 2},
        {assessed_at: time - 1.day, percent: 0.6, possible: 1.0, association_id: 2},
        {assessed_at: time - 1.day, percent: 0.8, possible: 1.0, association_id: 2},
      )

      results = [res].flatten
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [3.38]
    end
  end
end

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
  class MockOutcomeResult < Struct.new(:user, :learning_outcome, :score, :title, :submitted_at, :assessed_at, :artifact_type, :percent)
    def learning_outcome_id
      learning_outcome.id
    end

    def user_id
      user.id
    end
  end

  def outcome_from_score(score, args)
    title = args[:title] || "name, o1"
    outcome = create_outcome(args)
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
  end

  describe "handling quiz outcome results objects" do
    it "scales quiz scores to rubric score" do
      o1 = MockOutcome[80, 'decaying_average', 65, {points_possible: 5}]
      o2 = MockOutcome[81, 'n_mastery', 3, {:mastery_points => 3.0, points_possible: 5}]
      o3 = MockOutcome[82, 'n_mastery', 3, {:mastery_points => 3.0, points_possible: 5}]
      user = MockUser[10, 'a']
      results = [
        #first outcome
        MockOutcomeResult[user, o1, 7.0, "name, o1", nil, time, "Quizzes::QuizSubmission", 0.4],
        MockOutcomeResult[user, o1, 12.0, "name, o1", nil, time - 1.day, "Quizzes::QuizSubmission", 0.9],
        #second outcome
        MockOutcomeResult[user, o2, 30.0, "name, o2", nil, nil, "Quizzes::QuizSubmission", 0.2],
        MockOutcomeResult[user, o2, 75.0, "name, o2", nil, nil, "Quizzes::QuizSubmission", 0.5],
        MockOutcomeResult[user, o2, 120.0, "name, o2", nil, nil, "Quizzes::QuizSubmission", 0.8],
        #third outcome
        MockOutcomeResult[user, o3, 90.0, "name, o2", nil, nil, "Quizzes::QuizSubmission", 0.2],
        MockOutcomeResult[user, o3, 75.0, "name, o2", nil, nil, "Quizzes::QuizSubmission", 0.7],
        MockOutcomeResult[user, o3, 120.0, "name, o2", nil, nil, "Quizzes::QuizSubmission", 0.8],
        MockOutcomeResult[user, o3, 100.0, "name, o2", nil, nil, "Quizzes::QuizSubmission", 0.9]
      ]
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 3
      expect(rollups.map(&:score)).to eq [2.88, nil, 4.0]
    end
  end

end

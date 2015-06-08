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
  MockOutcome = Struct.new(:id, :calculation_method, :calculation_int)
  class MockOutcomeResult < Struct.new(:user, :learning_outcome, :score, :title, :submitted_at, :assessed_at)
    def learning_outcome_id
      learning_outcome.id
    end

    def user_id
      user.id
    end
  end

  describe '#rollup_user_results' do
    it 'returns a rollup score for each distinct outcome_id' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 2.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81], 3.0],
      ]
      rollup = ra.rollup_user_results(results)
      expect(rollup.size).to eq 2
      rollup.each.with_index do |ru, i|
        expect(ru.outcome_results.first).to eq results[i]
      end
    end
  end

  describe '#mastery calculation' do
    it 'returns maximum score when no method is set' do
      # this is to ensure we don't change behavior on outcomes that predate
      # the calculations feature. decaying avg will be default for new outcomes
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 3.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 1.0],
      ]
      rollup = ra.rollup_user_results(results)
      expect(rollup.size).to eq 1
      expect(rollup[0].count).to eq 2
      expect(rollup[0].score).to eq 3.0
    end

    it 'returns maximum score when highest score method is selected' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'highest'], 3.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'highest'], 1.0],
      ]
      rollup = ra.rollup_user_results(results)
      expect(rollup[0].score).to eq 3.0
      expect(rollup[0].outcome.calculation_method).to eq "highest"
    end

    it 'returns correct score when latest score method is selected' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'latest'], 4.0, "name, o1", nil],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'latest'], 3.0, "name, o1", time],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'latest'], 1.0, "name, o1", time - 1.day]
      ]
      rollups = ra.rollup_user_results(results)
      expect(rollups[0].score).to eq 3.0
    end

    it 'properly calculates results when method is n# of scores for mastery' do
      results = [
        #first outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'n_mastery', 3], 3.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'n_mastery', 3], 1.0],
        #second outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'n_mastery', 5], 3.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'n_mastery', 5], 1.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'n_mastery', 5], 3.0],
        #third outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], 4.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], 5.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], 1.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], 3.0],
      ]
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 3
      expect(rollups.map(&:score)).to eq [nil, nil, 3.25]
    end

    it 'does not error out and correctly averages when a result has a score of nil' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], 4.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], 5.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], 1.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], 3.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], nil],
      ]
      rollups = ra.rollup_user_results(results)
      expect(rollups.map(&:score)).to eq [3.25]
    end

    it 'properly calculates results when method is decaying average' do
      results = [
        #first outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'decaying_average', 75], 3.0, "name, o1", time],
        #second outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'decaying_average', 75], 4.0, "name, o2", time],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'decaying_average', 75], 5.0, "name, o2", time - 1.day],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'decaying_average', 75], 1.0, "name, o2", time - 2.days],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'decaying_average', 75], 3.0, "name, o2", time - 3.days],
      ]
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 2
      expect(rollups.map(&:score)).to eq [nil, 3.75]
    end

    it 'properly sorts results when there is no submitted_at time on one or many results' do
      results = [
        #first outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'decaying_average', 65], 3.0, "name, o1", nil, time],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'decaying_average', 65], 2.0, "name, o1", nil, time - 1.day],
        #second outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'decaying_average', 75], 4.0, "name, o2", nil, time],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'decaying_average', 75], 5.0, "name, o2", nil, time - 1.day],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'decaying_average', 75], 1.0, "name, o2", nil, time - 2.days],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'decaying_average', 75], 3.0, "name, o2", time - 3.days, nil],
      ]
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 2
      expect(rollups.map(&:score)).to eq [2.65, 3.75]
    end

    it 'rounds results for decaying average and n_mastery methods' do
      results = [
        #first outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'decaying_average', 65], 3.0, "name, o1", nil, time],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'decaying_average', 65], 2.0, "name, o1", nil, time - 1.day],
        #second outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'n_mastery', 3], 3.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'n_mastery', 3], 4.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'n_mastery', 3], 3.0],
      ]
      rollups = ra.rollup_user_results(results)
      expect(rollups.size).to eq 2
      expect(rollups.map(&:score)).to eq [2.65, 3.33]
    end
  end

  describe '#outcome_results_rollups' do
    before do
      ActiveRecord::Associations::Preloader.any_instance.stubs(:run)
    end
    it 'returns a rollup for each distinct user_id' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 4.0],
        MockOutcomeResult[MockUser[20, 'b'], MockOutcome[80], 5.0],
        MockOutcomeResult[MockUser[20, 'b'], MockOutcome[80], 3.0],
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
      ActiveRecord::Associations::Preloader.any_instance.stubs(:run)
    end
    it 'returns one rollup with the rollup averages' do
      fake_context = MockUser.new(42, 'fake')
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 0.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 1.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81], 5.0],
        MockOutcomeResult[MockUser[20, 'b'], MockOutcome[80], 2.0],
        MockOutcomeResult[MockUser[20, 'b'], MockOutcome[81], 6.0],
        MockOutcomeResult[MockUser[30, 'c'], MockOutcome[80], 3.0],
        MockOutcomeResult[MockUser[40, 'd'], MockOutcome[80], 4.0],
        MockOutcomeResult[MockUser[40, 'd'], MockOutcome[81], 7.0],
      ]
      aggregate_result = ra.aggregate_outcome_results_rollup(results, fake_context)
      expect(aggregate_result.size).to eq 2
      expect(aggregate_result.scores.map(&:score)).to eq [2.5, 6.0]
      expect(aggregate_result.scores[0].outcome_results.size).to eq 4
      expect(aggregate_result.scores[1].outcome_results.size).to eq 3
    end
  end

end

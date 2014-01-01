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

  let(:ra) { Outcomes::ResultAnalytics }

  # ResultAnalytics only uses a few fields, so use some mock stuff to avoid all
  # the surrounding database logic
  MockUser = Struct.new(:id, :name)
  MockOutcome = Struct.new(:id)
  class MockOutcomeResult < Struct.new(:user, :learning_outcome, :score)
    def learning_outcome_id
      learning_outcome.id
    end

    def user_id
      user.id
    end
  end

  describe '#rollup_user_results' do
    it 'returns a hash for each distinct outcome_id' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 20],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81], 30],
      ]
      ra.rollup_user_results(results).should == [
        { outcome: MockOutcome[80], score: 20 },
        { outcome: MockOutcome[81], score: 30 },
      ]
    end

    it 'returns the maximum score for each outcome_id' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 20],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 30],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81], 40],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81], 50],
      ]
      ra.rollup_user_results(results).should == [
        { outcome: MockOutcome[80], score: 30 },
        { outcome: MockOutcome[81], score: 50 },
      ]
    end
  end

  describe '#rollup_results' do
    it 'returns a hash for each distinct user_id' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 40],
        MockOutcomeResult[MockUser[20, 'b'], MockOutcome[80], 50],
      ]
      users = [MockUser[10, 'a'], MockUser[30, 'c']]
      ra.rollup_results(results, users).should == [
        { user: MockUser[10, 'a'], scores: [{outcome: MockOutcome[80], score: 40}] },
        { user: MockUser[20, 'b'], scores: [{outcome: MockOutcome[80], score: 50}] },
        { user: MockUser[30, 'c'], scores: [] },
      ]
    end
  end

end

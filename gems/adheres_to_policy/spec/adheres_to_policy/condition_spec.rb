#
# Copyright (C) 2015 Instructure, Inc.
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

require 'spec_helper'

describe AdheresToPolicy::Condition do
  describe '#applies?' do
    it 'returns true if it applies' do
      condition = AdheresToPolicy::Condition.new(proc { true })
      expect(condition.applies?(nil, nil, nil)).to be(true)
    end

    it 'returns false if it does not apply' do
      condition = AdheresToPolicy::Condition.new(proc { false })
      expect(condition.applies?(nil, nil, nil)).to be(false)
    end

    it 'returns false if its parent does not apply' do
      parent = AdheresToPolicy::Condition.new(proc { false })
      condition = AdheresToPolicy::Condition.new(proc { true }, parent)
      expect(condition.applies?(nil, nil, nil)).to be(false)
    end

    it 'evaluates the condition in the context of the object' do
      object = double
      thing = double
      expect(thing).to receive(:happened).with(object)

      condition = AdheresToPolicy::Condition.new(proc {
        thing.happened(self)
      })
      condition.applies?(object, nil, nil)
    end

    it 'passes in the user and session' do
      user = double
      session = double
      thing = double
      expect(thing).to receive(:happened).with(user, session)

      condition = AdheresToPolicy::Condition.new(proc { |user, session|
        thing.happened(user, session)
      })
      condition.applies?(nil, user, session)
    end

    it 'works with lambdas with only one argument' do
      user = double
      thing = double
      expect(thing).to receive(:happened).with(user)

      condition = AdheresToPolicy::Condition.new((lambda { |user|
        thing.happened(user)
      }))

      condition.applies?(nil, user, double)
    end
  end
end

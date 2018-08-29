#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe AnonymousOrModerationEvent do
  describe 'relationships' do
    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:submission) }
    it { is_expected.to belong_to(:canvadoc) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:assignment_id) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_inclusion_of(:event_type).in_array(AnonymousOrModerationEvent::EVENT_TYPES) }
    it { is_expected.to validate_presence_of(:payload) }
  end
end

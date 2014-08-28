#
# Copyright (C) 2014 Instructure, Inc.
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

describe LtiOutbound::LTIRole do
  describe 'constants' do
    it 'provides role constants' do
      expect(LtiOutbound::LTIRole::INSTRUCTOR).to eq 'Instructor'
      expect(LtiOutbound::LTIRole::LEARNER).to eq 'Learner'
      expect(LtiOutbound::LTIRole::ADMIN).to eq 'urn:lti:instrole:ims/lis/Administrator'
      expect(LtiOutbound::LTIRole::CONTENT_DEVELOPER).to eq 'ContentDeveloper'
      expect(LtiOutbound::LTIRole::OBSERVER).to eq 'urn:lti:instrole:ims/lis/Observer'
      expect(LtiOutbound::LTIRole::TEACHING_ASSISTANT).to eq 'urn:lti:role:ims/lis/TeachingAssistant'
      expect(LtiOutbound::LTIRole::NONE).to eq 'urn:lti:sysrole:ims/lis/None'
    end
  end
end
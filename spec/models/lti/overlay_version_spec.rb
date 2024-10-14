# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

RSpec.describe Lti::OverlayVersion do
  describe "validations" do
    it { is_expected.to belong_to(:account).optional(false) }
    it { is_expected.to belong_to(:lti_overlay).class_name("Lti::Overlay").optional(false) }
    it { is_expected.to belong_to(:created_by).class_name("User").optional(false) }

    it { is_expected.to validate_presence_of(:diff) }
  end
end

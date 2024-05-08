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

RSpec.describe Lti::Registration do
  describe "validations" do
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:admin_nickname).is_at_most(255) }
    it { is_expected.to validate_length_of(:vendor).is_at_most(255) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to have_one(:ims_registration).class_name("Lti::IMS::Registration").with_foreign_key(:lti_registration_id) }
    it { is_expected.to have_one(:developer_key).class_name("DeveloperKey").inverse_of(:lti_registration).with_foreign_key(:lti_registration_id) }
    it { is_expected.to belong_to(:created_by).class_name("User").optional(false) }
    it { is_expected.to belong_to(:updated_by).class_name("User").optional(false) }
    it { is_expected.to have_many(:lti_registration_account_bindings).class_name("Lti::RegistrationAccountBinding").dependent(:destroy) }
  end
end

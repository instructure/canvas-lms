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

class Lti::RegistrationAccountBinding < ActiveRecord::Base
  extend RootAccountResolver

  include Workflow
  workflow do
    state :off
    state :on
    state :allow
  end

  belongs_to :account, inverse_of: :lti_registration_account_bindings, optional: false
  belongs_to :registration, class_name: "Lti::Registration", inverse_of: :lti_registration_account_bindings, optional: false
  belongs_to :root_account, class_name: "Account"
  belongs_to :created_by, class_name: "User", inverse_of: :created_lti_registration_account_bindings
  belongs_to :updated_by, class_name: "User", inverse_of: :updated_lti_registration_account_bindings
  belongs_to :developer_key_account_binding, inverse_of: :lti_registration_account_binding

  resolves_root_account through: :account
end

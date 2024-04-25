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

class Lti::Registration < ActiveRecord::Base
  extend RootAccountResolver
  include Canvas::SoftDeletable

  belongs_to :account, inverse_of: :lti_registrations, optional: false
  belongs_to :created_by, class_name: "User", inverse_of: :created_lti_registrations, optional: false
  belongs_to :updated_by, class_name: "User", inverse_of: :updated_lti_registrations, optional: false
  has_one :ims_registration, class_name: "Lti::IMS::Registration", inverse_of: :lti_registration, foreign_key: :lti_registration_id
  has_one :developer_key, inverse_of: :lti_registration, foreign_key: :lti_registration_id
  has_many :lti_registration_account_bindings, class_name: "Lti::RegistrationAccountBinding", dependent: :destroy, inverse_of: :registration

  validates :name, :admin_nickname, :vendor, length: { maximum: 255 }
  validates :name, presence: true

  scope :active, -> { where(workflow_state: "active") }

  resolves_root_account through: :account
end

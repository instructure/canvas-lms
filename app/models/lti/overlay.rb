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

class Lti::Overlay < ActiveRecord::Base
  extend RootAccountResolver
  include Canvas::SoftDeletable

  # Overlay always lives on the shard of the Account
  belongs_to :account, inverse_of: :lti_overlays, optional: false
  # Registration can be cross-shard
  belongs_to :registration, class_name: "Lti::Registration", inverse_of: :lti_overlays, optional: false
  belongs_to :updated_by, class_name: "User", inverse_of: :lti_overlays, optional: false

  has_many :lti_overlay_versions, class_name: "Lti::OverlayVersion", inverse_of: :lti_overlay, dependent: :destroy
  resolves_root_account through: :account

  validate :validate_data

  def validate_data
    schema_errors = Schemas::Lti::Overlay.validation_errors(data)
    return if schema_errors.blank?

    errors.add(:data, schema_errors.to_json)
    false
  end
end

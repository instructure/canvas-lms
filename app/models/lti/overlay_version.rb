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

class Lti::OverlayVersion < ActiveRecord::Base
  extend RootAccountResolver
  belongs_to :account, inverse_of: :lti_overlay_versions, optional: false
  belongs_to :lti_overlay, class_name: "Lti::Overlay", inverse_of: :lti_overlay_versions, optional: false
  belongs_to :created_by, class_name: "User", inverse_of: :lti_overlay_versions, optional: false

  # @see Hashdiff.diff for the format of the diff
  validates :diff, presence: true

  resolves_root_account through: :account
end

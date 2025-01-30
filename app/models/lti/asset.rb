# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# An Lti::Asset is something an AssetProcessor can create a report for. It is a
# generalization of an attachment. Examples include:
# - an attachment used in a submission
# - (future) RCE content submitted by a student as part of a submission
# - (future) possibly RCE content or attachments used other places, e.g. discussions
class Lti::Asset < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

  resolves_root_account through: :submission

  # For now, there is no dependent: destroy from attachment to report,
  # so we should check the assignment is not (soft-)deleted when using
  # the report, if we care in the scenario.

  has_many :asset_reports, class_name: "Lti::AssetReport", inverse_of: :asset, foreign_key: :lti_asset_id

  # In the future, we'll support other types of assets,
  # for instance RCE content stored in a Submission version,
  # and attachment can be made optional
  belongs_to :attachment,
             inverse_of: :lti_assets,
             class_name: "Attachment",
             optional: false
  belongs_to :submission,
             inverse_of: :lti_assets,
             class_name: "Submission",
             optional: false

  validates :attachment_id, uniqueness: { scope: :submission_id }

  before_validation :generate_uuid, on: :create

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def compatible_with_processor?(processor)
    !!submission&.assignment && submission.assignment == processor&.assignment
  end
end

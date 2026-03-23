# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class InstitutionalTagAssociation < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

  belongs_to :institutional_tag, optional: false, inverse_of: :institutional_tag_associations
  belongs_to :context, polymorphic: %i[user course], separate_columns: true, optional: false
  belongs_to :sis_batch, optional: true

  resolves_root_account through: :institutional_tag

  validates :sis_source_id, length: { maximum: 255, allow_blank: true }
  validates :stuck_sis_fields, length: { maximum: 255, allow_blank: true }
  validates :sis_source_id, uniqueness: { scope: :root_account_id, case_sensitive: false }, allow_nil: true
end

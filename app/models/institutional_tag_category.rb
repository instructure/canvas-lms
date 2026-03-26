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

class InstitutionalTagCategory < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

  belongs_to :account, optional: false
  belongs_to :sis_batch, optional: true
  has_many :institutional_tags, foreign_key: :category_id, inverse_of: :category

  resolves_root_account through: :account

  before_validation :sanitize_name, if: :name_changed?
  before_destroy :cascade_archive_tags

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: maximum_text_length, allow_blank: true }
  validates :sis_source_id, length: { maximum: 255, allow_blank: true }
  validates :stuck_sis_fields, length: { maximum: 255, allow_blank: true }
  validates :sis_source_id, uniqueness: { scope: :root_account_id, case_sensitive: false }, allow_nil: true
  sanitize_field :description, CanvasSanitize::SANITIZE
  validates :name, uniqueness: { scope: :root_account_id, conditions: -> { active }, case_sensitive: false }

  private

  def sanitize_name
    self.name = Sanitize.clean((name || "").to_s, CanvasSanitize::SANITIZE)
  end

  def cascade_archive_tags
    InstitutionalTagCategory.transaction do
      now = Time.now.utc
      InstitutionalTagAssociation
        .active
        .joins(:institutional_tag)
        .where(institutional_tags: { category_id: id })
        .update_all(workflow_state: "deleted", updated_at: now)
      institutional_tags.active.update_all(workflow_state: "deleted", updated_at: now)
    end
  end
end

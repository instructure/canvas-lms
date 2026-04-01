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

class InstitutionalTag < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

  belongs_to :category, class_name: "InstitutionalTagCategory", optional: false, inverse_of: :institutional_tags
  belongs_to :sis_batch, optional: true
  has_many :institutional_tag_associations, inverse_of: :institutional_tag

  resolves_root_account through: :category

  scope :search_by_name, ->(term) { where("LOWER(name) LIKE ?", "#{term.downcase}%") }

  before_validation :sanitize_name, if: :name_changed?
  after_save :cascade_archive_associations_later, if: -> { saved_change_to_workflow_state?(to: "deleted") }

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 500 }
  sanitize_field :description, CanvasSanitize::SANITIZE

  validates :sis_source_id, length: { maximum: 255, allow_blank: true }
  validates :stuck_sis_fields, length: { maximum: 255, allow_blank: true }
  validates :sis_source_id, uniqueness: { scope: :root_account_id, case_sensitive: false }, allow_nil: true
  validates :name, uniqueness: { scope: :root_account_id, conditions: -> { active }, case_sensitive: false }

  validate :validate_tag_limit_per_category

  def self.cascade_archive_associations_for(tag_ids)
    return if tag_ids.empty?

    now = Time.now.utc
    InstitutionalTagAssociation
      .active
      .where(institutional_tag_id: tag_ids)
      .in_batches(of: 10_000)
      .update_all(workflow_state: "deleted", updated_at: now)
  end

  private

  def sanitize_name
    self.name = Sanitize.clean((name || "").to_s, CanvasSanitize::SANITIZE)
  end

  def cascade_archive_associations_later
    delay_if_production(
      singleton: "InstitutionalTag#cascade_archive_associations_#{global_id}",
      priority: Delayed::LOW_PRIORITY
    ).cascade_archive_associations
  end

  def cascade_archive_associations
    self.class.cascade_archive_associations_for([id])
  end

  def validate_tag_limit_per_category
    return unless category_id
    return unless new_record? || (workflow_state_changed? && workflow_state == "active")

    limit = (DynamicSettings.find(tree: :private)["institutional_tags_per_category_limit", failsafe: nil] || 50).to_i

    if InstitutionalTag.active.where(category_id:).count >= limit
      errors.add(:category, t("A category cannot have more than %{limit} tags", limit:))
    end
  end
end

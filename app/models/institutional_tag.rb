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

class InstitutionalTag < ActiveRecord::Base
  extend RootAccountResolver
  include Canvas::SoftDeletable

  belongs_to :category, class_name: "InstitutionalTagCategory", optional: false, inverse_of: :institutional_tags
  belongs_to :sis_batch, optional: true
  has_many :institutional_tag_associations, dependent: :restrict_with_exception, inverse_of: :institutional_tag

  resolves_root_account through: :category

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 500 }
  sanitize_field :name, CanvasSanitize::SANITIZE
  sanitize_field :description, CanvasSanitize::SANITIZE

  validates :sis_source_id, length: { maximum: 255, allow_blank: true }
  validates :stuck_sis_fields, length: { maximum: 255, allow_blank: true }
  validates :sis_source_id, uniqueness: { scope: :root_account_id, case_sensitive: false }, allow_nil: true
  validates :name, uniqueness: { scope: :root_account_id, conditions: -> { active }, case_sensitive: false }
end

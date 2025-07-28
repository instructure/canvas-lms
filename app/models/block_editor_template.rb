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
#

class BlockEditorTemplate < ActiveRecord::Base
  include Workflow

  belongs_to :context, polymorphic: %i[account course user]
  before_create :set_root_account_id

  def set_root_account_id
    self.root_account_id = context&.root_account_id unless root_account_id
  end

  def active?
    workflow_state == "active"
  end

  def self.name_order_by_clause
    best_unicode_collation_key("block_editor_templates.name")
  end

  workflow do
    state :unpublished do
      event :publish, transitions_to: :active
    end
    state :active do
      event :unpublish, transitions_to: :unpublished
    end
    state :deleted
  end
  include Canvas::SoftDeletable

  alias_method :published?, :active?
end

# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class UserNote < ActiveRecord::Base
  include Workflow

  belongs_to :user
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id

  validates :user_id, :created_by_id, :workflow_state, presence: true
  validates :note, length: { maximum: maximum_text_length, allow_blank: true }
  validates :title, length: { maximum: maximum_string_length, allow_blank: true }
  after_save :update_last_user_note

  sanitize_field :note, CanvasSanitize::SANITIZE

  workflow do
    state :active
    state :deleted
  end

  scope :active, -> { where("workflow_state<>'deleted'") }
  scope :desc_by_date, -> { order("created_at DESC") }

  set_policy do
    given { |user| creator == user }
    can :delete and can :read

    given { |user| self.user.grants_right?(user, :delete_user_notes) }
    can :delete and can :read

    given { |user| self.user.grants_right?(user, :read_user_notes) }
    can :read
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    self.deleted_at = Time.now.utc
    save!
  end

  def formatted_note(truncate = nil)
    extend TextHelper
    res = note
    res = truncate_html(note, max_length: truncate, words: true) if truncate
    res
  end

  def creator_name
    creator&.name
  end

  def update_last_user_note
    user.update_last_user_note
    user.save
  end
end

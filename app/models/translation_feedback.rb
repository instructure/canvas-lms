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

class TranslationFeedback < ApplicationRecord
  extend RootAccountResolver

  resolves_root_account through: :context

  belongs_to :root_account, class_name: "Account"
  belongs_to :user
  belongs_to :context, polymorphic: [:course], separate_columns: true
  belongs_to :content, polymorphic: [:discussion_topic, :discussion_entry], separate_columns: true

  validates :target_language, presence: true

  def like
    update!(liked: true, disliked: false)
  end

  def dislike(notes: nil)
    update!(liked: false, disliked: true, feedback_notes: notes)
  end

  def reset_like
    update!(liked: false, disliked: false, feedback_notes: nil)
  end
end

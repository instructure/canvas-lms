#
# Copyright (C) 2012 Instructure, Inc.
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

class ContentParticipation < ActiveRecord::Base
  include Workflow

  ACCESSIBLE_ATTRIBUTES = [:content, :user, :workflow_state].freeze

  belongs_to :content, polymorphic: [:submission]
  belongs_to :user

  after_save :update_participation_count

  validates_presence_of :content_type, :content_id, :user_id, :workflow_state

  workflow do
    state :unread
    state :read
  end

  def self.create_or_update(opts={})
    opts = opts.with_indifferent_access
    content = opts.delete(:content)
    user = opts.delete(:user)
    return nil unless user && content

    participant = nil
    unique_constraint_retry do
      participant = content.content_participations.where(:user_id => user).first
      participant ||= content.content_participations.build(:user => user, :workflow_state => "unread")
      participant.attributes = opts.slice(*ACCESSIBLE_ATTRIBUTES)
      participant.save if participant.new_record? || participant.changed?
    end
    participant
  end

  def update_participation_count
    return unless workflow_state_changed?
    ContentParticipationCount.create_or_update({
      :context => content.context,
      :user => user,
      :content_type => content_type,
      :offset => (workflow_state == "unread" ? 1 : -1),
    })
  end
end

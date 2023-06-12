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

class DelayedNotification < ActiveRecord::Base
  include Workflow

  belongs_to :asset,
             polymorphic:
                 [:assessment_request,
                  :attachment,
                  :content_migration,
                  :content_export,
                  :collaborator,
                  :submission,
                  :assignment,
                  :communication_channel,
                  :calendar_event,
                  :conversation_message,
                  :discussion_entry,
                  :submission_comment,
                  { quiz_submission: "Quizzes::QuizSubmission" },
                  :discussion_topic,
                  :course,
                  :enrollment,
                  :wiki_page,
                  :group_membership,
                  :web_conference],
             polymorphic_prefix: true,
             exhaustive: false
  include NotificationPreloader

  attr_accessor :data

  validates :notification_id, :asset_id, :asset_type, :workflow_state, presence: true

  serialize :recipient_keys

  workflow do
    state :to_be_processed do
      event :do_process, transitions_to: :processed
    end
    state :processed
    state :errored
  end

  def self.process(asset, notification, recipient_keys, data = {}, **kwargs)
    # RUBY 2.7 this can go away (**{} will work at the caller)
    raise ArgumentError, "Only send one hash" if !data&.empty? && !kwargs.empty?

    data = kwargs if data&.empty? && !kwargs.empty?

    DelayedNotification.new(
      asset:,
      notification:,
      recipient_keys:,
      data:
    ).process
  end

  def process
    res = []
    if asset
      iterate_to_list do |to_list_slice|
        slice_res = notification.create_message(asset, to_list_slice, data:)
        res.concat(slice_res) if Rails.env.test?
      end
    end
    do_process unless new_record?
    res
  rescue => e
    Canvas::Errors.capture(e, message: "Delayed Notification processing failed")
    logger.error "delayed notification processing failed: #{e.message}\n#{e.backtrace.join "\n"}"
    self.workflow_state = "errored"
    save
    []
  end

  def iterate_to_list
    lookups = {}
    (recipient_keys || []).each do |key|
      pieces = key.split("_")
      id = pieces.pop
      klass = pieces.join("_").classify.constantize
      lookups[klass] ||= []
      lookups[klass] << id
    end

    lookups.each do |klass, ids|
      # notification_policies, and notification_policy_overrides are included in
      # each of the preloads twice intentionally.
      # rails de-dups them and only does one query, but if not included twice,
      # they will not show as loaded against both objects.
      includes = if klass == CommunicationChannel
                   [:notification_policies, :notification_policy_overrides, { user: %i[pseudonyms notification_policies notification_policy_overrides] }]
                 elsif klass == User
                   [:pseudonyms, { communication_channels: [:notification_policies, :notification_policy_overrides] }, :notification_policies, :notification_policy_overrides]
                 else
                   []
                 end

      ids.each_slice(100) do |slice|
        yield klass.where(id: slice).preload(includes).to_a
      end
    end
  end

  scope :to_be_processed, lambda { |limit|
    where(workflow_state: "to_be_processed").limit(limit).order("delayed_notifications.created_at")
  }
end

# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module ScheduledPublication
  def self.included(klass)
    klass.send(:before_save, :process_publish_at)
    klass.send(:after_save, :schedule_delayed_publication)
  end

  def process_publish_at
    if will_save_change_to_workflow_state? && workflow_state_in_database.present?
      # explicitly publishing / unpublishing the page clears publish_at
      self.publish_at = nil unless @implicitly_published
    elsif will_save_change_to_publish_at? && context.root_account.feature_enabled?(:scheduled_page_publication)
      if publish_at&.>(Time.now.utc)
        # setting a publish_at date in the future unpublishes the page
        self.workflow_state = "unpublished"
        @schedule_publication = true
      elsif publish_at.nil?
        self.workflow_state = "unpublished"
        @schedule_publication = false
      else
        # setting a publish_at date in the past publishes the page
        self.workflow_state = "active"
      end
    end
  end

  def schedule_delayed_publication
    delay(run_at: publish_at).publish_if_scheduled if @schedule_publication
    @schedule_publication = false
  end

  def publish_if_scheduled
    # include a fudge factor in case clock skew between db/job servers
    # causes the job to wake up a little early
    return if published? || publish_at.nil? || publish_at > Time.now.utc + 15.seconds
    return unless context.root_account.feature_enabled?(:scheduled_page_publication)

    @implicitly_published = true # leave publish_at alone so future course copies can shift it
    skip_downstream_changes! # ensure scheduled publication doesn't count as a downstream edit for blueprints
    publish!
  end
end

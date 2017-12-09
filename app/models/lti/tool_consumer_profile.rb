#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Lti
  class ToolConsumerProfile < ActiveRecord::Base

    belongs_to :developer_key

    before_validation {self.uuid ||= SecureRandom.uuid}
    after_update :clear_cache

    serialize :services
    serialize :capabilities

    DEFAULT_TCP_UUID = "339b6700-e4cb-47c5-a54f-3ee0064921a9".freeze

    WEBHOOK_GRANT_ALL_CAPABILITY = 'vnd.instructure.webhooks.root_account.all'.freeze
    WEBHOOK_SUBSCRIPTION_CAPABILITIES = {
      all: [WEBHOOK_GRANT_ALL_CAPABILITY].freeze,
      quiz_submitted: %w(vnd.instructure.webhooks.root_account.quiz_submitted
                         vnd.instructure.webhooks.assignment.quiz_submitted).freeze,
      grade_change: %w(vnd.instructure.webhooks.root_account.grade_change).freeze,
      attachment_created: %w(vnd.instructure.webhooks.root_account.attachment_created
                             vnd.instructure.webhooks.assignment.attachment_created).freeze,
      submission_created: %w(vnd.instructure.webhooks.root_account.submission_created
                             vnd.instructure.webhooks.assignment.submission_created).freeze,
      plagiarism_resubmit: %w(vnd.instructure.webhooks.root_account.plagiarism_resubmit
                              vnd.instructure.webhooks.assignment.plagiarism_resubmit).freeze,
      submission_updated: %w(vnd.instructure.webhooks.root_account.submission_updated
                             vnd.instructure.webhooks.assignment.submission_updated).freeze,
    }.freeze

    DEFAULT_CAPABILITIES = %w(
      basic-lti-launch-request
      ToolProxyRegistrationRequest
      Canvas.placements.accountNavigation
      Canvas.placements.courseNavigation
      Canvas.placements.assignmentSelection
      Canvas.placements.linkSelection
      Canvas.placements.postGrades
      Security.splitSecret
      Context.sourcedId
    ).concat(
      Lti::VariableExpander.expansion_keys
    ).freeze

    RESTRICTED_CAPABILITIES = [
      'Canvas.placements.similarityDetection',
      "#{Lti::OriginalityReportsApiController::ORIGINALITY_REPORT_SERVICE}.url",
      *WEBHOOK_SUBSCRIPTION_CAPABILITIES.values.flatten
    ].freeze


    DEFAULT_SERVICES = [
      *Lti::Ims::ToolProxyController::SERVICE_DEFINITIONS,
      *Lti::Ims::AuthorizationController::SERVICE_DEFINITIONS,
      *Lti::Ims::ToolSettingController::SERVICE_DEFINITIONS
    ].freeze

    RESTRICTED_SERVICES = [
      *Lti::OriginalityReportsApiController::SERVICE_DEFINITIONS,
      *Lti::SubscriptionsApiController::SERVICE_DEFINITIONS,
      *Lti::SubmissionsApiController::SERVICE_DEFINITIONS,
      *Lti::UsersApiController::SERVICE_DEFINITIONS,
      *Lti::AssignmentsApiController::SERVICE_DEFINITIONS
    ].freeze

    class << self
      def cached_find_by_developer_key(dev_key_id)
        MultiCache.fetch(cache_key(dev_key_id)) do
          Shackles.activate(:slave) do
            dev_key = DeveloperKey.find_cached(dev_key_id)
            dev_key.present? && dev_key.tool_consumer_profile
          end
        end
      end

      def cache_key(dev_key_id)
        global_dev_key_id = Shard.global_id_for(dev_key_id)
        "tool_consumer_profile/dev_key/#{global_dev_key_id}"
      end
    end

    def self.webhook_subscription_capabilities
      WEBHOOK_SUBSCRIPTION_CAPABILITIES
    end

    def self.webhook_grant_all_capability
      WEBHOOK_GRANT_ALL_CAPABILITY
    end


    private

    def clear_cache
      MultiCache.delete(self.class.cache_key(developer_key_id))
    end


  end
end

module Lti
  class ToolConsumerProfile < ActiveRecord::Base

    belongs_to :developer_key

    before_validation { self.uuid ||= SecureRandom.uuid }
    after_update :clear_cache

    serialize :services
    serialize :capabilities

    DEFAULT_TCP_UUID = "339b6700-e4cb-47c5-a54f-3ee0064921a9".freeze

    WEBHOOK_GRANT_ALL_CAPABILITY = 'vnd.Canvas.webhooks.root_account.all'.freeze
    WEBHOOK_SUBSCRIPTION_CAPABILITIES = {
      all: [WEBHOOK_GRANT_ALL_CAPABILITY].freeze,
      quiz_submitted: %w(vnd.instructure.webhooks.root_account.quiz_submitted
                         vnd.instructure.webhooks.course.quiz_submitted
                         vnd.instructure.webhooks.assignment.quiz_submitted).freeze,
      assignment_submitted: %w(vnd.instructure.webhooks.root_account.assignment_submitted
                               vnd.instructure.webhooks.course.assignment_submitted
                               vnd.instructure.webhooks.assignment.assignment_submitted).freeze,
      grade_changed: %w(vnd.instructure.webhooks.root_account.grade_changed
                        vnd.instructure.webhooks.course.grade_changed).freeze,
      attachment_created: %w(vnd.instructure.webhooks.root_account.attachment_created
                             vnd.instructure.webhooks.assignment.attachment_created).freeze,
      submission_created: %w(vnd.instructure.webhooks.root_account.submission_created
                             vnd.instructure.webhooks.assignment.submission_created).freeze
    }.freeze

    DEFAULT_CAPABILITIES = %w(
      basic-lti-launch-request
      User.id
      Canvas.api.domain
      LtiLink.custom.url
      ToolProxyBinding.custom.url
      ToolProxy.custom.url
      Canvas.placements.accountNavigation
      Canvas.placements.courseNavigation
      Canvas.placements.assignmentSelection
      Canvas.placements.linkSelection
      Canvas.placements.postGrades
      User.username
      Person.email.primary
      vnd.Canvas.Person.email.sis
      Person.name.given
      Person.name.family
      Person.name.full
      CourseSection.sourcedId
      Person.sourcedId
      Membership.role
      ToolConsumerProfile.url
      Security.splitSecret
      Context.id
    ).concat(CapabilitiesHelper::SUPPORTED_CAPABILITIES).freeze

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
      *Lti::SubscriptionsApiController::SERVICE_DEFINITIONS
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

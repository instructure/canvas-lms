module Lti
  class ToolConsumerProfile < ActiveRecord::Base

    belongs_to :developer_key

    before_validation { self.uuid ||= SecureRandom.uuid }
    after_update :clear_cache

    serialize :services
    serialize :capabilities

    DEFAULT_TCP_UUID = "339b6700-e4cb-47c5-a54f-3ee0064921a9".freeze

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
      Canvas.placements.similarityDetection
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

    RESTRICTED_CAPABILITIES = %W(
      #{Lti::OriginalityReportsApiController::ORIGINALITY_REPORT_SERVICE}.url
    ).freeze


    DEFAULT_SERVICES = [
      *Lti::Ims::ToolProxyController::SERVICE_DEFINITIONS,
      *Lti::Ims::AuthorizationController::SERVICE_DEFINITIONS,
      *Lti::Ims::ToolSettingController::SERVICE_DEFINITIONS
    ].freeze

    RESTRICTED_SERVICES = [
      *Lti::OriginalityReportsApiController::SERVICE_DEFINITIONS
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




    private

    def clear_cache
      MultiCache.delete(self.class.cache_key(developer_key_id))
    end


  end
end

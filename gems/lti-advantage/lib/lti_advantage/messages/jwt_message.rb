# frozen_string_literal: true

require "json/jwt"

module LtiAdvantage::Messages
  # Abstract base class for all LTI 1.3 JWT message types
  class JwtMessage
    include ActiveModel::Model

    REQUIRED_CLAIMS = %i[
      aud
      azp
      deployment_id
      exp
      iat
      iss
      message_type
      nonce
      version
      target_link_uri
    ].freeze

    OPTIONAL_CLAIMS = %i[
      lti11_legacy_user_id
      sub
    ].freeze

    TYPED_ATTRIBUTES = {
      aud: [Array, String],
      context: LtiAdvantage::Claims::Context,
      custom: Hash,
      extensions: Hash,
      launch_presentation: LtiAdvantage::Claims::LaunchPresentation,
      lis: LtiAdvantage::Claims::Lis,
      names_and_roles_service: LtiAdvantage::Claims::NamesAndRolesService,
      assignment_and_grade_service: LtiAdvantage::Claims::AssignmentAndGradeService,
      platform_notification_service: LtiAdvantage::Claims::PlatformNotificationService,
      tool_platform: LtiAdvantage::Claims::Platform,
      roles: Array,
      role_scope_mentor: Array,
      lti1p1: LtiAdvantage::Claims::Lti1p1,
      activity: LtiAdvantage::Claims::Activity,
      eulaservice: LtiAdvantage::Claims::Eulaservice,
    }.freeze

    attr_accessor(*(REQUIRED_CLAIMS + OPTIONAL_CLAIMS))
    attr_accessor(*TYPED_ATTRIBUTES.keys)
    attr_accessor :address,
                  :birthdate,
                  :custom,
                  :email,
                  :email_verified,
                  :family_name,
                  :gender,
                  :given_name,
                  :locale,
                  :middle_name,
                  :name,
                  :nickname,
                  :phone_number,
                  :phone_number_verified,
                  :picture,
                  :preferred_username,
                  :profile,
                  :updated_at,
                  :website,
                  :zoneinfo,
                  :id
    attr_writer :extensions,
                :launch_presentation,
                :list,
                :roles,
                :role_scope_mentor,
                :tool_platform

    def self.create_jws(body, private_key, alg = :RS256)
      JSON::JWT.new(body).sign(private_key, alg).to_s
    end

    def context
      @context ||= TYPED_ATTRIBUTES[:context].new
    end

    def extensions
      @extensions ||= TYPED_ATTRIBUTES[:extensions].new
    end

    def launch_presentation
      @launch_presentation ||= TYPED_ATTRIBUTES[:launch_presentation].new
    end

    def names_and_roles_service
      @names_and_roles_service ||= TYPED_ATTRIBUTES[:names_and_roles_service].new
    end

    def assignment_and_grade_service
      @assignment_and_grade_service ||= TYPED_ATTRIBUTES[:assignment_and_grade_service].new
    end

    def platform_notification_service
      @platform_notification_service ||= TYPED_ATTRIBUTES[:platform_notification_service].new
    end

    def lis
      @lis ||= TYPED_ATTRIBUTES[:lis].new
    end

    def roles
      @roles ||= TYPED_ATTRIBUTES[:roles].new
    end

    def role_scope_mentor
      @role_scope_mentor ||= TYPED_ATTRIBUTES[:role_scope_mentor].new
    end

    def tool_platform
      @tool_platform ||= TYPED_ATTRIBUTES[:tool_platform].new
    end

    def lti1p1
      @lti1p1 ||= TYPED_ATTRIBUTES[:lti1p1].new
    end

    def activity
      @activity ||= TYPED_ATTRIBUTES[:activity].new
    end

    def eulaservice
      @eulaservice ||= TYPED_ATTRIBUTES[:eulaservice].new
    end

    def read_attribute(attribute)
      send(attribute)
    end

    # TODO: remove without_validation_fields when we remove the remove_unwanted_lti_validation_claims flag
    def to_h(without_validation_fields: true)
      LtiAdvantage::Serializers::JwtMessageSerializer.new(self).serializable_hash(without_validation_fields:)
    end

    def to_jws(private_key, alg = :RS256)
      self.class.create_jws(to_h, private_key, alg)
    end
  end
end

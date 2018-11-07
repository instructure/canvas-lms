require 'json/jwt'

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
      sub
      version
    ].freeze

    TYPED_ATTRIBUTES = {
      aud: Array,
      context: LtiAdvantage::Claims::Context,
      custom: Hash,
      extensions: Hash,
      launch_presentation: LtiAdvantage::Claims::LaunchPresentation,
      lis: LtiAdvantage::Claims::Lis,
      names_and_roles_service: LtiAdvantage::Claims::NamesAndRolesService,
      assignment_and_grade_service: LtiAdvantage::Claims::AssignmentAndGradeService,
      tool_platform: LtiAdvantage::Claims::Platform,
      roles: Array,
      role_scope_mentor: Array
    }.freeze

    attr_accessor *REQUIRED_CLAIMS
    attr_accessor *TYPED_ATTRIBUTES.keys
    attr_accessor :address,
                  :birthdate,
                  :custom,
                  :email,
                  :email_verified,
                  :extensions,
                  :family_name,
                  :gender,
                  :given_name,
                  :launch_presentation,
                  :lis,
                  :locale,
                  :middle_name,
                  :name,
                  :nickname,
                  :phone_number,
                  :phone_number_verified,
                  :picture,
                  :tool_platform,
                  :preferred_username,
                  :profile,
                  :roles,
                  :role_scope_mentor,
                  :updated_at,
                  :website,
                  :zoneinfo,
                  :id

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

    def read_attribute(attribute)
      self.send(attribute)
    end

    def to_h
      LtiAdvantage::Serializers::JwtMessageSerializer.new(self).serializable_hash
    end

    def to_jws(private_key, alg = :RS256)
      self.class.create_jws(self.to_h, private_key, alg)
    end
  end
end

#
# Copyright (C) 2016 Instructure, Inc.
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

module ConditionalRelease
  class Service
    private_class_method :new

    DEFAULT_CONFIG = {
      enabled: false, # required
      host: nil,      # required
      protocol: nil,  # defaults to Canvas
      edit_rule_path: "ui/editor",
      create_account_path: 'api/account',
    }.freeze

    def self.env_for(context, user = nil, session: nil, assignment: nil, domain: nil, real_user: nil)
      enabled = self.enabled_in_context?(context)
      env = {
        CONDITIONAL_RELEASE_SERVICE_ENABLED: enabled
      }
      if enabled && user
        env.merge!({
          CONDITIONAL_RELEASE_ENV: {
            jwt: jwt_for(context, user, domain, session: session, real_user: real_user),
            assignment: assignment_attributes(assignment),
            edit_rule_url: edit_rule_url,
            locale: I18n.locale.to_s
          }
        })
      end
      env
    end

    def self.jwt_for(context, user, domain, claims: {}, session: nil, real_user: nil)
      Canvas::Security::ServicesJwt.generate(
        claims.merge({
          sub: user.id.to_s,
          account_id: Context.get_account(context).root_account.lti_guid.to_s,
          context_type: context.class.name,
          context_id: context.id.to_s,
          role: find_role(user, session, context),
          workflow: 'conditonal-release-api',
          canvas_token: Canvas::Security::ServicesJwt.for_user(domain, user, real_user: real_user, workflow: 'conditional-release')
        })
      )
    end

    def self.reset_config_cache
      @config = nil
    end

    def self.config
      @config ||= DEFAULT_CONFIG.merge(config_file)
    end

    def self.configured?
      !!(config[:enabled] && config[:host])
    end

    def self.enabled_in_context?(context)
      !!(configured? && context.feature_enabled?(:conditional_release))
    end

    def self.edit_rule_url
      build_url edit_rule_path
    end

    def self.create_account_url
      build_url create_account_path
    end

    def self.protocol
      config[:protocol] || HostUrl.protocol
    end

    def self.host
      config[:host]
    end

    def self.unique_id
      config[:unique_id] || "conditional-release-service@instructure.auth"
    end

    def self.edit_rule_path
      config[:edit_rule_path]
    end

    def self.create_account_path
      config[:create_account_path]
    end

    class << self
      private
      def config_file
        ConfigFile.load('conditional_release').try(:symbolize_keys) || {}
      end

      def build_url(path)
        "#{protocol}://#{host}/#{path}"
      end

      def find_role(user, session, context)
        if Context.get_account(context).grants_right? user, session, :manage
          'admin'
        elsif context.is_a?(Course) && context.grants_right?(user, session, :manage_assignments)
          'teacher'
        elsif context.grants_right? user, session, :read
          'student'
        end
      end

      def assignment_attributes(assignment)
        return nil unless assignment.present?
        {
          id: assignment.id,
          title: assignment.title,
          description: assignment.description,
          points_possible: assignment.points_possible,
          grading_type: assignment.grading_type,
          submission_types: assignment.submission_types,
          grading_scheme: (assignment.grading_scheme if assignment.uses_grading_standard)
        }
      end
    end
  end
end

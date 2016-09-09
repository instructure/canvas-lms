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
      stats_path: "stats/students_per_range",
      create_account_path: 'api/account',
      content_exports_path: 'api/content_exports',
      content_imports_path: 'api/content_imports',
      rules_summary_path: 'api/rules/summary',
      select_assignment_set_path: 'api/rules/select_assignment_set'
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
            stats_url: stats_url,
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
          domain: domain,
          account_id: Context.get_account(context).root_account.lti_guid.to_s,
          context_type: context.class.name,
          context_id: context.id.to_s,
          role: find_role(user, session, context),
          workflow: 'conditonal-release-api',
          canvas_token: Canvas::Security::ServicesJwt.for_user(domain, user, real_user: real_user, workflow: 'conditional-release')
        })
      )
    end

    def self.rules_for(context, student, content_tags, session)
      return unless enabled_in_context?(context)
      data = rules_data(context, student, Array.wrap(content_tags), session)
      data[:rules]
    end

    def self.clear_submissions_cache_for(user)
      return unless user.present?
      clear_cache_with_key(submissions_cache_key(user))
    end

    def self.clear_rules_cache_for(context, student)
      return if context.blank? || student.blank?
      clear_cache_with_key(rules_cache_key(context, student))
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

    def self.stats_url
      build_url stats_path
    end

    def self.create_account_url
      build_url create_account_path
    end

    def self.rules_summary_url
      build_url rules_summary_path
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

    def self.stats_path
      config[:stats_path]
    end

    def self.create_account_path
      config[:create_account_path]
    end

    def self.content_exports_url
      build_url(config[:content_exports_path])
    end

    def self.content_imports_url
      build_url(config[:content_imports_path])
    end

    def self.rules_summary_path
      config[:rules_summary_path]
    end

    def self.select_assignment_set_url
      build_url(config[:select_assignment_set_path])
    end

    # Returns an http response-like hash { code: string, body: string or object }
    def self.select_mastery_path(context, current_user, student, trigger_assignment_id, assignment_set_id, session)
      return unless enabled_in_context?(context)
      if context.blank? || student.blank? || trigger_assignment_id.blank? || assignment_set_id.blank?
        return { code: '400', body: { message: 'invalid request' } }
      end

      request_data = {
        trigger_assignment: trigger_assignment_id,
        student_id: student.id,
        assignment_set_id: assignment_set_id
      }
      headers = headers_for(context, current_user, domain_for(context), session)
      request = CanvasHttp.post(select_assignment_set_url, headers, form_data: request_data.to_param)
      { code: request.code, body: JSON.parse(request.body) }
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

      def headers_for(context, user, domain, session)
        jwt = jwt_for(context, user, domain, session: session)
        {"Authorization" => "Bearer #{jwt}"}
      end

      def domain_for(context)
        Context.get_account(context).root_account.domain
      end

      def submissions_for(student)
        return [] unless student.present?

        Rails.cache.fetch(submissions_cache_key(student)) do
          keys = [:id, :assignment_id, :score, :"assignments.points_possible"]
          student.submissions.eager_load(:assignment).pluck(*keys).map do |values|
            submission = Hash[keys.zip(values)]
            submission[:points_possible] = submission.delete(:"assignments.points_possible")
            submission
          end
        end
      end

      def rules_data(context, student, content_tags = [], session = {})
        return {rules: []} if context.blank? || student.blank?
        cached = rules_cache(context, student)
        assignments = assignments_for(cached[:rules]) if cached
        cache_expired = newer_than_cache?(content_tags.select(&:content), cached) ||
                        newer_than_cache?(assignments, cached)

        rules_cache(context, student, force: cache_expired) do
          data = { submissions: submissions_for(student) }
          headers = headers_for(context, student, domain_for(context), session)
          req = request_rules(headers, data)
          rules = merge_assignment_data!(req, assignments)
          {rules: rules, updated_at: Time.zone.now}
        end
      end

      def rules_cache(context, student, force: false, &block)
        Rails.cache.fetch(rules_cache_key(context, student), force: force, &block)
      end

      def newer_than_cache?(items, cache)
        cache && cache.key?(:updated_at) && items &&
        items.detect { |item| item.updated_at > cache[:updated_at] }.present?
      end

      def request_rules(headers, data)
        req = CanvasHttp.post(rules_summary_url, headers, form_data: data.to_param)

        if req && req.is_a?(Net::HTTPSuccess)
          JSON.parse(req.body)
        else
          message = "An error occurred when attempting to fetch rules for ConditionalRelease::Service"
          Rails.logger.warn(message)
          Rails.logger.warn(req)
          {error: message}
        end
      end

      def assignments_for(response)
        rules = response.map(&:deep_symbolize_keys)

        # Fetch all the nested assignment_ids for the associated
        # CYOE content from the Rules provided
        ids = rules.flat_map do |rule|
                rule[:assignment_sets].flat_map do |a|
                  a[:assignments].flat_map do |asg|
                    asg[:assignment_id]
                  end
                end
              end

        # Get all the related Assignment models in Canvas
        Assignment.active.where(id: ids)
      end

      def merge_assignment_data!(response, assignments = nil)
        return response if response.blank? || (response.is_a?(Hash) && response.key?(:error))
        assignments = assignments_for(response) if assignments.blank?

        # Merge the Assignment models into the response for the given module item
        rules = response.map(&:deep_symbolize_keys)
        rules.map! do |rule|
          rule[:assignment_sets].map! do |set|
            set[:assignments].map! do |asg|
              assignment = assignments.find { |a| a[:id].to_s == asg[:assignment_id].to_s }
              asg[:model] = assignment && assignment.slice(*assignment_keys)
              asg
            end
            set
          end
          rule
        end
      end

      def assignment_keys
        %i(id title name description due_at unlock_at lock_at
          points_possible min_score max_score grading_type
          submission_types workflow_state context_id
          context_type updated_at context_code)
      end

      def rules_cache_key(context, student)
        ['conditional_release_rules', context.global_id, student.global_id].cache_key
      end

      def submissions_cache_key(student)
        ['conditional_release_submissions', student.global_id].cache_key
      end

      def clear_cache_with_key(key)
        return if key.blank?
        Rails.cache.delete(key)
      end
    end
  end
end

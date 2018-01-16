#
# Copyright (C) 2016 - present Instructure, Inc.
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
  class ServiceError < StandardError; end

  class Service
    private_class_method :new

    DEFAULT_PATHS = {
      base_path: '',
      stats_path: "stats",
      create_account_path: 'api/accounts',
      content_exports_path: 'api/content_exports',
      content_imports_path: 'api/content_imports',
      rules_path: 'api/rules?include[]=all&active=true',
      rules_summary_path: 'api/rules/summary',
      select_assignment_set_path: 'api/rules/select_assignment_set',
      editor_path: 'javascripts/generated/conditional_release_editor.bundle.js'
    }.freeze

    DEFAULT_CONFIG = {
      enabled: false, # required
      host: nil,      # required
      protocol: nil,  # defaults to Canvas
    }.merge(DEFAULT_PATHS).freeze

    def self.env_for(context, user = nil, session: nil, assignment: nil, domain: nil,
                  real_user: nil, includes: [])
      includes = Array.wrap(includes)
      enabled = self.enabled_in_context?(context)
      env = {
        CONDITIONAL_RELEASE_SERVICE_ENABLED: enabled
      }

      if enabled && user
        cyoe_env = {
          jwt: jwt_for(context, user, domain, session: session, real_user: real_user),
          assignment: assignment_attributes(assignment),
          stats_url: stats_url,
          locale: I18n.locale.to_s,
          editor_url: editor_url,
          base_url: base_url,
          context_id: context.id
        }

        cyoe_env[:rule] = rule_triggered_by(assignment, user, session) if includes.include? :rule
        cyoe_env[:active_rules] = active_rules(context, user, session) if includes.include? :active_rules

        new_env = {
          CONDITIONAL_RELEASE_ENV: cyoe_env
        }

        env.merge!(new_env)
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
          workflows: ['conditonal-release-api'],
          canvas_token: Canvas::Security::ServicesJwt.for_user(domain, user, real_user: real_user, workflows: ['conditional-release'])
        })
      )
    end

    def self.rules_for(context, student, content_tags, session)
      return unless enabled_in_context?(context)
      rules_data(context, student, Array.wrap(content_tags), session)
    end

    def self.clear_active_rules_cache(course)
      return unless course.present?
      clear_cache_with_key(active_rules_cache_key(course))
      clear_cache_with_key(active_rules_reverse_cache_key(course))
    end

    def self.clear_applied_rules_cache(course)
      return unless course.present?
      clear_cache_with_key(assignments_cache_key(course))
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
      !!(configured? && context&.feature_enabled?(:conditional_release))
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

    DEFAULT_PATHS.each do |path_name, _path|
      method_name = path_name.to_s.sub(/_path$/, '_url')
      Service.define_singleton_method method_name do
        build_url config[path_name]
      end
    end

    # Returns an http response-like hash { code: string, body: string or object }
    def self.select_mastery_path(context, current_user, student, trigger_assignment, assignment_set_id, session)
      return unless enabled_in_context?(context)
      if context.blank? || student.blank? || trigger_assignment.blank? || assignment_set_id.blank?
        return { code: '400', body: { message: 'invalid request' } }
      end

      trigger_submission = trigger_assignment.submission_for_student(student)
      if trigger_submission.blank? || !trigger_submission.graded? || trigger_assignment.muted?
        return { code: '400', body: { message: 'invalid submission state' } }
      end

      request_data = {
        trigger_assignment: trigger_assignment.id,
        trigger_assignment_score: trigger_submission.score,
        trigger_assignment_points_possible: trigger_assignment.points_possible,
        student_id: student.id,
        assignment_set_id: assignment_set_id
      }
      headers = headers_for(context, current_user, domain_for(context), session)
      request = CanvasHttp.post(select_assignment_set_url, headers, form_data: request_data.to_param)

      # either assignments have changed (req success) or unknown state (req error)
      clear_rules_cache_for(context, student)

      { code: request.code, body: JSON.parse(request.body) }
    end

    def self.triggers_mastery_paths?(assignment, current_user, session = nil)
      rule_triggered_by(assignment, current_user, session).present?
    end

    def self.rule_triggered_by(assignment, current_user, session = nil)
      return unless assignment.present?
      return unless enabled_in_context?(assignment.context)

      rules = active_rules(assignment.context, current_user, session)
      return nil unless rules

      rules.find {|r| r['trigger_assignment'] == assignment.id.to_s}
    end

    def self.rules_assigning(assignment, current_user, session = nil)
      reverse_lookup = Rails.cache.fetch(active_rules_reverse_cache_key(assignment.context)) do
        all_rules = active_rules(assignment.context, current_user, session)
        return nil unless all_rules

        lookup = {}
        all_rules.each do |rule|
          (rule['scoring_ranges'] || []).each do |sr|
            (sr['assignment_sets'] || []).each  do |as|
              (as['assignments'] || []).each do |a|
                if a['assignment_id'].present?
                  lookup[a['assignment_id']] ||= []
                  lookup[a['assignment_id']] << rule
                end
              end
            end
          end
        end
        lookup.each {|_id, rules| rules.uniq!}
        lookup
      end
      reverse_lookup[assignment.id.to_s]
    end

    def self.active_rules(course, current_user, session)
      return unless enabled_in_context?(course)
      return unless course.grants_any_right?(current_user, session, :read, :manage_assignments)

      Rails.cache.fetch(active_rules_cache_key(course)) do
        headers = headers_for(course, current_user, domain_for(course), session)
        request = CanvasHttp.get(rules_url, headers)
        unless request && request.code == '200'
          raise ServiceError, "error fetching active rules #{request}"
        end
        rules = JSON.parse(request.body)

        trigger_ids = rules.map { |rule| rule['trigger_assignment'] }
        trigger_assgs = Assignment.preload(:grading_standard).where(id: trigger_ids).each_with_object({}) do |a, assgs|
          assgs[a.id.to_s] = {
            points_possible: a.points_possible,
            grading_type: a.grading_type,
            grading_scheme: a.uses_grading_standard ? a.grading_scheme : nil,
          }
        end

        rules.each do |rule|
          rule['trigger_assignment_model'] = trigger_assgs[rule['trigger_assignment']]
        end

        rules
      end
    rescue => e
      Canvas::Errors.capture(e, course_id: course.global_id, user_id: current_user.global_id)
      []
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

      def submissions_for(student, context, force: false)
        return [] unless student.present?
        Rails.cache.fetch(submissions_cache_key(student), force: force) do
          keys = [:id, :assignment_id, :score, "assignments.points_possible"]
          context.submissions.
            for_user(student).
            in_workflow_state(:graded).
            where(assignments: {muted: false}).
            eager_load(:assignment).
            pluck(*keys).
            map do |values|
            submission = Hash[keys.zip(values)]
            submission[:points_possible] = submission.delete("assignments.points_possible")
            submission
          end
        end
      end

      def rules_data(context, student, content_tags = [], session = {})
        return [] if context.blank? || student.blank?
        cached = rules_cache(context, student)
        assignments = assignments_for(cached[:rules]) if cached
        force_cache = rules_cache_expired?(context, cached)
        rules_data = rules_cache(context, student, force: force_cache) do
          data = { submissions: submissions_for(student, context, force: force_cache) }
          headers = headers_for(context, student, domain_for(context), session)
          req = request_rules(headers, data)
          {rules: req, updated_at: Time.zone.now}
        end
        rules_data[:rules] = merge_assignment_data(rules_data[:rules], assignments)
        rules_data[:rules]
      rescue ConditionalRelease::ServiceError => e
        Canvas::Errors.capture(e, course_id: context.global_id, user_id: student.global_id)
        []
      end

      def rules_cache(context, student, force: false, &block)
        Rails.cache.fetch(rules_cache_key(context, student), force: force, &block)
      end

      def rules_cache_expired?(context, cache)
        assignment_timestamp = Rails.cache.fetch(assignments_cache_key(context)) do
          Time.zone.now
        end
        if cache && cache.key?(:updated_at)
          assignment_timestamp > cache[:updated_at]
        else
          true
        end
      end

      def request_rules(headers, data)
        req = CanvasHttp.post(rules_summary_url, headers, form_data: data.to_param)

        if req && req.code == '200'
          JSON.parse(req.body)
        else
          message = "error fetching applied rules #{req}"
          raise ServiceError, message
        end
      rescue => e
        raise if e.is_a? ServiceError
        raise ServiceError, e.inspect
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

      def merge_assignment_data(response, assignments = nil)
        return response if response.blank? || (response.is_a?(Hash) && response.key?(:error))
        assignments = assignments_for(response) if assignments.blank?

        # Merge the Assignment models into the response for the given module item
        rules = response.map(&:deep_symbolize_keys)
        rules.map! do |rule|
          rule[:assignment_sets].map! do |set|
            set[:assignments].map! do |asg|
              assignment = assignments.find { |a| a[:id].to_s == asg[:assignment_id].to_s }
              asg[:model] = assignment
              asg if asg[:model].present?
            end.compact!
            set if set[:assignments].present?
          end.compact!
          rule
        end.compact!
        rules.compact
      end

      def assignment_keys
        %i(id title name description due_at unlock_at lock_at
          points_possible min_score max_score grading_type
          submission_types workflow_state context_id
          context_type updated_at context_code)
      end

      def rules_cache_key(context, student)
        ['conditional_release_rules:2', context.global_id, student.global_id].cache_key
      end

      def assignments_cache_key(context)
        ['conditional_release_rules:assignments:2', context.global_id].cache_key
      end

      def submissions_cache_key(student)
        ['conditional_release_submissions:2', student.global_id].cache_key
      end

      def active_rules_cache_key(course)
        ['conditional_release', 'active_rules', course.global_id].cache_key
      end

      def active_rules_reverse_cache_key(course)
        ['conditional_release', 'active_rules_reverse', course.global_id].cache_key
      end

      def clear_cache_with_key(key)
        return if key.blank?
        Rails.cache.delete(key)
      end
    end
  end
end

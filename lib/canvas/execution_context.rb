# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module Canvas
  # Request/job-scoped execution context info based using
  # ActiveSupport::ExecutionContext as the underlying store.
  #
  # When ActiveSupport::ExecutionContext changes, this module automatically infers
  # Canvas-specific attributes canvas-specif attributes based on the changes.
  #
  # Get an atribute by arbitrary key. Returns nil if the key doesn't exist.
  #   Canvas::ExecutionContext[:request_id]
  #
  # Get a hash of attributes filtered to keys relevant to context type. Keys alway symbls.
  #   Canvas::ExecutionContext.to_h
  #
  # Get a hash of HTTP headers, based on context attributes. Keys are always strings with "canvas-" prefix.
  #   These headers are NOT intended to be used for authentication, authorization, or any security-sensitive use case.
  #   Canvas::ExecutionContext.to_headers
  #
  # Checking execution context:
  #   Canvas::ExecutionContext.request?       # => true if this is a web request
  #   Canvas::ExecutionContext.job?           # => true if this is a delayed job
  #
  # The actual data used to infer canvas-specific attributes is set in:
  # - Rails (sets :controller in AS::EC during process_action, triggering eager computation)
  # - inst-jobs (job context details)
  module ExecutionContext
    class << self
      COMMON_ATTRIBUTES = {
        region: -> { Canvas.region || "unknown-region" },
        revision: -> { Canvas.revision || "unknown-revision" },
      }.freeze

      REQUEST_ATTRIBUTES = {
        request_id: -> { RequestContext::Generator.request_id },
      }.freeze

      JOB_ATTRIBUTES = {
        job_global_id: ->(job:) { job.global_id },
        job_source: ->(job:) { job.source },
        job_tag: ->(job:) { job.tag },
      }.freeze

      HEADER_PREFIX = "canvas-"

      def to_h
        context_keys = COMMON_ATTRIBUTES.keys
        context_keys.concat(REQUEST_ATTRIBUTES.keys) if request?
        context_keys.concat(JOB_ATTRIBUTES.keys) if job?

        cached_context.slice(*context_keys).compact
      end

      delegate :[], to: :cached_context

      def to_headers
        to_h.transform_keys { |key| to_header_key(key) }
      end

      def to_header_key(key)
        "#{HEADER_PREFIX}#{key.to_s.tr("_", "-")}"
      end

      def job?
        !cached_context[:job].nil?
      end

      def request?
        !cached_context[:request_id].nil? && !job?
      end

      def clear_cache
        Thread.current[:canvas_execution_context] = nil
      end

      def rebuild_cache
        Thread.current[:canvas_execution_context] = infer_attributes
      rescue => e
        Rails.logger.warn "Error rebuilding execution context cache: #{e.message}"
        clear_cache
      end

      private

      def compute_attributes(attribute_mapping, **)
        attribute_mapping.transform_values do |proc|
          proc.call(**)
        rescue => e
          Rails.logger.warn "Error computing execution context attribute: #{e.message}"
          nil
        end
      end

      def cached_context
        Thread.current[:canvas_execution_context] ||= infer_attributes
      rescue => e
        Rails.logger.warn "Error computing execution context: #{e.message}"
        Thread.current[:canvas_execution_context] = {}
      end

      def context_is_request?(context)
        # Rails sets the controller context for requests
        context.key?(:controller) && !context.key?(:job)
      end

      def context_is_job?(context)
        # Delayed Job sets the job context for background jobs
        context.key?(:job) && !context.key?(:controller)
      end

      def infer_attributes
        context = ActiveSupport::ExecutionContext.to_h
        context.merge!(compute_attributes(COMMON_ATTRIBUTES))

        return context.merge!(compute_attributes(REQUEST_ATTRIBUTES)) if context_is_request?(context)
        return context.merge!(compute_attributes(JOB_ATTRIBUTES, job: context[:job])) if context_is_job?(context)

        context
      end
    end
  end
end

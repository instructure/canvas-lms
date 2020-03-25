#
# Copyright (C) 2020 - present Instructure, Inc.
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
require 'inst-jobs'

module Canvas
  module Apm
    module InstJobs
      # Much of this is taken from ddtrace-rb
      # lib/ddtrace/contrib/delayed_job/plugin.rb
      # because inst jobs is sufficiently distinct that just
      # using that instrumentation as-is failed because it has version
      # requirements unmet by the way we load inst-jobs.
      # As this grows we might look at patching their
      # delayed_job integration to be ok with the shape of
      # inst-jobs by writing our own version of
      # lib/ddtrace/contrib/delayed_job/integration.rb that
      # recognizes inst-jobs as valid and just uses the plugin
      # defined by ddtrace originally for delayed_job
      class Plugin < ::Delayed::Plugin
        class << self
          attr_writer :tracer

          def reset!
            super
            @tracer = nil
          end

          def instrument(job)
            return yield job unless tracer&.enabled
            job_name = job.name
            tracer.trace("inst_jobs", service: "canvas_jobs", resource: job_name) do |span|
              span.set_tag("inst_jobs.id", job.id)
              span.set_tag("inst_jobs.queue", job.queue) if job.queue
              span.set_tag("inst_jobs.priority", job.priority)
              span.set_tag("inst_jobs.attempts", job.attempts)
              span.set_tag("inst_jobs.strand", job.strand) if job.strand.present?
              span.set_tag('shard', job.shard_id.to_s) if job.shard_id.present?
              act_global_id = job.account_id
              span.set_tag('root_account', act_global_id.to_s) if act_global_id.present?
              span.span_type = "worker"
              yield job
            end
          end

          def flush(worker)
            yield worker
            tracer.shutdown! if tracer&.enabled
          end

          def tracer
            return @tracer if @tracer.present?
            Datadog.tracer
          end
        end

        callbacks do |lifecycle|
          lifecycle.around(:invoke_job, &method(:instrument))
          lifecycle.around(:execute, &method(:flush))
        end
      end
    end
  end
end
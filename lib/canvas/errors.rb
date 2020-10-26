# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Canvas
  # The central message bus for errors in canvas.
  #
  # This class is injected both in ApplicationController for capturing
  # exceptions that happen in request/response cycles, and in our
  # Delayed::Job callback for failed jobs.  We also call out to it
  # from several points throughout the codebase directly to register
  # an unexpected occurance that doesn't necessarily bubble up to
  # that point.
  #
  # There's a sentry connector built into canvas, but anything one
  # wants to do with errors can be hooked into this path with the
  # .register! method.
  class Errors

    # register something to happen on every exception that occurs.
    #
    # The parameter is a unique key for this callback, which is
    # used when assembling return values from ".capture" and it's friends.
    #
    # The block should accept two parameters, one for the exception/message
    # and one for contextual info in the form of a hash.  The hash *will*
    # have an ":extra" key, and *may* have a ":tags" key.  tags would
    # be things it might be useful to aggreate errors around (job queue), extras
    # are things that would be useful for tracking down why or in what
    # circumstance an error might occur (request_context_id)
    #
    #   Canvas::Errors.register!(:my_key) do |ex, data|
    #     # do something with the exception
    #   end
    def self.register!(key, &block)
      registry[key] = block
    end

    # "capture" is the thing to call if you want to tell Canvas::Errors
    # that something bad happened.  You can pass in an exception, or
    # just a message.  If you don't build your data hash
    # with a "tags" key and an "extra" key, it will just group all contextual
    # information under "extra"
    def self.capture(exception, data={})
      job_info = check_for_job_context
      request_info = check_for_request_context
      error_info = job_info.deep_merge(request_info).deep_merge(wrap_in_extra(data))
      run_callbacks(exception, error_info)
    end

    # convenience method, use this if you want to apply the 'type' tag without
    # having to pass in a whole hash
    def self.capture_exception(type, exception)
      self.capture(exception, {tags: {type: type.to_s}})
    end

    # This is really just for clearing out the registry during tests,
    # if you call it in production it will dump all registered callbacks
    # that got fired in initializers and such until the process restarts.
    def self.clear_callback_registry!
      @registry = {}
    end

    def self.check_for_request_context
      ctx = Thread.current[:context]
      ctx.present? ? wrap_in_extra(ctx) : {}
    end

    # capturing all the contextual info
    # like job ID and tag can make attaching this error
    # to some debug logs later much easier
    def self.check_for_job_context
      job = Delayed::Worker.current_job
      job ? Canvas::Errors::JobInfo.new(job, nil).to_h : {}
    end

    def self.run_callbacks(exception, extra)
      registry.each_with_object({}) do |(key, callback), outputs|
        outputs[key] = callback.call(exception, extra)
      end
    end
    private_class_method :run_callbacks

    def self.registry
      @registry ||= {}
    end
    private_class_method :registry

    def self.wrap_in_extra(data)
      if data.key?(:tags) || data.key?(:extra)
        data
      else
        {extra: data}
      end
    end
    private_class_method :wrap_in_extra
  end
end

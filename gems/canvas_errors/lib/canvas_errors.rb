# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

##
# CanvasErrors isThe central message bus for errors in canvas.
#
# This class can be injected in ApplicationController for capturing
# exceptions that happen in request/response cycles, or in
# Delayed::Job callbacks for failed jobs, etc.
#
# There's a sentry connector built into canvas, but anything one
# wants to do with errors can be hooked into this path with the
# .register! method.

require "inst-jobs"
require "canvas_errors/job_info"
require "code_ownership"

module CanvasErrors
  DEFAULT_TEAM = "unknown"
  # register something to happen on every exception that occurs.
  #
  # The parameter is a unique key for this callback, which is
  # used when assembling return values from ".capture" and it's friends.
  #
  # The block should accept three parameters, one for the exception/message
  # and one for contextual info in the form of a hash, and one which is the
  # severity "level" of the exception (defaulting to :error)
  #
  # The contextual hash (2nd parameter) *will*
  # have an ":extra" key, and *may* have a ":tags" key.  tags would
  # be things it might be useful to aggreate errors around (job queue), extras
  # are things that would be useful for tracking down why or in what
  # circumstance an error might occur (request_context_id)
  #
  # The ":level" parameter will be one of a predefined set (see ERROR_LEVELS below),
  # so your callback can decide what to do with it.
  #
  #   CanvasErrors.register!(:my_key) do |ex, data, level|
  #     # do something with the exception
  #   end
  def self.register!(key, &block)
    registry[key] = block
  end

  # "capture" is the thing to call if you want to tell CanvasErrors
  # that something bad happened.  You can pass in an exception, or
  # just a message.  If you don't build your data hash
  # with a "tags" key and an "extra" key, it will just group all contextual
  # information under "extra"
  #
  # the ":level" parameter, which defaults
  # to ":error" and (much like log levels), can trigger different
  # reporting outcomes in the callbacks. expected member of ERROR_LEVELS.
  # Registered callbacks can decide what to do about different levels.
  ERROR_LEVELS = %i[info warn error].freeze
  def self.capture(exception, data = {}, level = :error)
    unless ERROR_LEVELS.include?(level)
      Rails.logger.warn("[ERRORS] error level #{level} is not supported, defaulting to :error")
      level = :error
    end
    job_info = check_for_job_context
    request_info = check_for_request_context
    error_info = team_context(exception).deep_merge(job_info.deep_merge(request_info).deep_merge(wrap_in_extra(data)))
    run_callbacks(exception, error_info, level)
  end

  # convenience method, use this if you want to apply the 'type' tag without
  # having to pass in a whole hash
  def self.capture_exception(type, exception, level = :error)
    capture(exception, { tags: { type: type.to_s } }, level)
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
    job ? CanvasErrors::JobInfo.new(job, nil).to_h : {}
  end

  def self.find_team_for_exception(exception)
    CodeOwnership.for_backtrace(exception.backtrace)&.name
  rescue
    # As a failsafe, return the unknown team
    DEFAULT_TEAM
  end

  # Return the current team tag (or default 'unknown') to include in Canvas Errors
  def self.team_context(exception)
    {
      tags: {
        "inst.team" => find_team_for_exception(exception) || DEFAULT_TEAM
      }
    }
  end

  def self.run_callbacks(exception, extra, level = :error)
    registry.transform_values do |callback|
      callback.call(exception, extra, level)
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
      { extra: data }
    end
  end
  private_class_method :wrap_in_extra
end

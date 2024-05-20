# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class CanvasLogger < ActiveSupport::Logger
  def capture_messages(&)
    CanvasLogger.prepend Capture unless CanvasLogger.include?(Capture)
    capture_messages(&)
  end

  def capture_messages!
    CanvasLogger.prepend Capture unless CanvasLogger.include?(Capture)
    captured_message_stack << []
  end

  module Capture
    CAPTURE_LIMIT = 10_000

    def captured_message_stack
      @captured_message_stack ||= []
    end

    def capture_messages!
      captured_messages.clear
    end

    def captured_messages
      captured_message_stack.last
    end

    def capture_messages
      captured_message_stack.push([])
      yield
      captured_messages
    ensure
      captured_message_stack.pop
      captured_messages
    end

    def add(severity, message = nil, progname = nil)
      return if level > severity

      message = (message || (block_given? && yield) || progname).to_s
      captured_message = "[#{Time.now}] #{message}"
      captured_message_stack.each do |messages|
        messages << captured_message if messages.length < CAPTURE_LIMIT
      end
      super(severity, message, progname)
    end
  end
end

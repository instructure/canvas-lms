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

ActiveSupport::TimeWithZone.delegate :to_yaml, :to => :utc
ActiveSupport::SafeBuffer.class_eval do
  def encode_with(coder)
    coder.scalar("!str", self.to_str)
  end
end

module ActiveSupport::Cache
  module RailsCacheShim
    def normalize_key(key, options)
      result = super
      if options && options.has_key?(:use_new_rails) ? options[:use_new_rails] : !CANVAS_RAILS5_1
        result = "rails52:#{result}"
      end
      result
    end

    def delete(key, options = nil)
      r1 = super(key, (options || {}).merge(use_new_rails: !CANVAS_RAILS5_1)) # prefer rails 3 if on rails 3 and vis versa
      r2 = super(key, (options || {}).merge(use_new_rails: CANVAS_RAILS5_1))
      r1 || r2
    end
  end
  Store.prepend(RailsCacheShim)

  unless CANVAS_RAILS5_1
    module AllowMocksInStore
      def compress!(*args)
        if @value && Rails.env.test?
          begin
            super
          rescue TypeError => e
            return
          end
        else
          super
        end
      end
    end
    Entry.prepend(AllowMocksInStore)
  end
end


module IgnoreMonkeyPatchesInDeprecations
  def extract_callstack(callstack)
    return _extract_callstack(callstack) if callstack.first.is_a?(String)

    offending_line = callstack.find { |frame|
      # pass the whole frame to the filter function, so we can ignore specific methods
      !ignored_callstack(frame)
    } || callstack.first

    [offending_line.path, offending_line.lineno, offending_line.label]
  end

  def ignored_callstack(frame)
    if frame.is_a?(String)
        if md = frame.match(/^(.+?):(\d+)(?::in `(.*?)')?/)
          path, _, label = md.captures
        else
          return false
        end
    else
      path, _, label = frame.absolute_path, frame.lineno, frame.label
    end
    return true if path&.start_with?(File.dirname(__FILE__) + "/active_record.rb")
    return true if path&.start_with?(File.expand_path(File.dirname(__FILE__) + "/../../gems/activesupport-suspend_callbacks"))
    return true if path == File.expand_path(File.dirname(__FILE__) + "/../../spec/support/blank_slate_protection.rb")
    return true if path == File.expand_path(File.dirname(__FILE__) + "/../../spec/selenium/common.rb")
    @switchman ||= File.expand_path('..', Gem.loaded_specs['switchman'].full_gem_path) + "/"
    return true if path&.start_with?(@switchman)
    return true if label == 'render' && path&.end_with?("application_controller.rb")
    return true if label == 'named_context_url' && path&.end_with?("application_controller.rb")
    return true if label == 'redirect_to' && path&.end_with?("application_controller.rb")

    return false unless path
    super(path)
  end
end
ActiveSupport::Deprecation.prepend(IgnoreMonkeyPatchesInDeprecations)

module RaiseErrorOnDurationCoercion
  def coerce(other)
    ::Rails.logger.error("Implicit numeric calculations on a duration are getting changed in Rails 5.1 - e.g. `240 / 2.minutes` will return `120` instead of `2` - so please make the duration explicit with to_i")
    raise # i'd raise the message but it gets swallowed up in a TypeError
  end
end
ActiveSupport::Duration.prepend(RaiseErrorOnDurationCoercion)

module Enumerable
  def pluck(*keys)
    if keys.many?
      map { |o| keys.map { |key| o.is_a?(ActiveRecord::Base) ? o.send(key) : o[key] } }
    else
      map { |o| o.is_a?(ActiveRecord::Base) ? o.send(keys.first) : o[keys.first] }
    end
  end
end

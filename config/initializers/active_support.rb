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

Rails.application.config.active_support.use_sha1_digests = true

ActiveSupport::TimeWithZone.delegate :to_yaml, to: :utc
ActiveSupport::SafeBuffer.class_eval do
  def encode_with(coder)
    coder.scalar("!str", to_str)
  end
end

module ActiveSupport::Cache
  Store.prepend(ActiveSupport::CacheRegister::Cache::Store)

  module AllowMocksInStore
    def compress!(*args)
      if @value && Rails.env.test?
        begin
          super
        rescue TypeError
          nil
        end
      else
        super
      end
    end
  end
  Entry.prepend(AllowMocksInStore)
end

module IgnoreMonkeyPatchesInDeprecations
  def extract_callstack(callstack)
    return [] if callstack.empty?
    return _extract_callstack(callstack) if callstack.first.is_a?(String)

    method = ($canvas_rails == "7.1") ? :ignored_callstack? : :ignored_callstack
    offending_line = callstack.find do |frame|
      # pass the whole frame to the filter function, so we can ignore specific methods
      !send(method, frame)
    end || callstack.first

    [offending_line.path, offending_line.lineno, offending_line.label]
  end

  class_eval <<~RUBY, __FILE__, __LINE__ + 1
    def ignored_callstack#{"?" if $canvas_rails == "7.1"}(frame)
      if frame.is_a?(String)
        if (md = frame.match(/^(.+?):(\d+)(?::in `(.*?)')?/))
          path, _, label = md.captures
        else
          return false
        end
      else
        path, _, label = frame.absolute_path || frame.path, frame.lineno, frame.label
        return false unless path
      end
      return true if path&.start_with?(File.dirname(__FILE__) + "/active_record.rb")
      return true if path&.start_with?(File.expand_path(File.dirname(__FILE__) + "/../../gems/activesupport-suspend_callbacks"))
      return true if path == File.expand_path(File.dirname(__FILE__) + "/../../spec/support/blank_slate_protection.rb")
      return true if path == File.expand_path(File.dirname(__FILE__) + "/../../spec/selenium/common.rb")

      @switchman ||= File.expand_path(Gem.loaded_specs["switchman"].full_gem_path) + "/"
      return true if path&.start_with?(@switchman)
      return true if label == "render" && path&.end_with?("application_controller.rb")
      return true if label == "named_context_url" && path&.end_with?("application_controller.rb")
      return true if label == "redirect_to" && path&.end_with?("application_controller.rb")
      return true if label == "block in wrap_block_in_transaction" && path == File.expand_path(File.dirname(__FILE__) + "/../../spec/spec_helper.rb")

      return false unless path

      super(path)
    end
  RUBY
end
ActiveSupport::Deprecation.prepend(IgnoreMonkeyPatchesInDeprecations)

module Enumerable
  def pluck(*keys)
    if keys.many?
      map { |o| keys.map { |key| o.is_a?(ActiveRecord::Base) ? o.send(key) : o[key] } }
    else
      map { |o| o.is_a?(ActiveRecord::Base) ? o.send(keys.first) : o[keys.first] }
    end
  end
end

# frozen_string_literal: true

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

module DynamicSettings
  class FallbackProxy
    PERSISTENCE_FLAG = "dynamic_settings:"
    PERSISTED_TREE = "store"

    attr_reader :data

    def initialize(data = nil, path = nil, ignore_fallback_overrides: false)
      @data = (data || {}).with_indifferent_access
      @path = path
      @ignore_fallback_overrides = ignore_fallback_overrides
      load_fallback_overrides if load_overrides?
    end

    def fetch(key, **_)
      # use .to_s, to act like consul where booleans aren't
      # first class data types
      @data[key]&.to_s
    end
    alias_method :[], :fetch

    # Set multiple key value pairs
    #
    # @param kvs [Hash] Key value pairs where the hash key is the key
    #   and the hash value is the value
    # @param global [nil] Has no effect
    # @return [Hash]
    def set_keys(kvs, global: nil)
      @data.merge!(kvs)
      if overridable?
        kvs.each do |k, v|
          Setting.set(PERSISTENCE_FLAG + append_path(k), v)
        end
      end
    end

    def for_prefix(prefix_extension, **_)
      self.class.new(
        @data[prefix_extension],
        append_path(prefix_extension),
        ignore_fallback_overrides: @ignore_fallback_overrides
      )
    end

    private

    def load_overrides?
      !@ignore_fallback_overrides && @path == PERSISTED_TREE
    end

    def overridable?
      !@ignore_fallback_overrides && @path&.starts_with?(PERSISTED_TREE)
    end

    def load_fallback_overrides
      overrides = Setting.where("name LIKE ?", "#{PERSISTENCE_FLAG + @path}%")
      overrides.each do |setting|
        _tree, *segments, key = setting.name.delete_prefix(PERSISTENCE_FLAG).split("/")
        prefix = @data
        segments.each do |part|
          prefix[part] ||= {}
          prefix = prefix[part]
        end
        prefix[key] = setting.value
      end
    end

    def append_path(prefix)
      prefix_string = prefix.to_s
      @path.nil? ? prefix_string : @path + "/" + prefix_string
    end
  end
end

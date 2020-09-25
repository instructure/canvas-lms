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

module Account::Settings
  module ClassMethods
    def add_setting(setting, opts=nil)
      if opts && opts[:inheritable]
        opts[:hash] = true
        opts[:values] = [:value, :locked]

        self.class_eval "def #{setting}; cached_inherited_setting(:#{setting}); end"
      elsif (opts && opts[:boolean] && opts.has_key?(:default))
        if opts[:default]
          # if the default is true, we want a nil result to evaluate to true.
          # this prevents us from having to backfill true values into a
          # serialized column, which would be expensive.
          self.class_eval "def #{setting}?; settings[:#{setting}] != false; end"
        else
          # if the default is not true, we can fall back to a straight boolean.
          self.class_eval "def #{setting}?; !!settings[:#{setting}]; end"
        end
      end
      self.account_settings_options[setting.to_sym] = opts || {}
    end

    def inheritable_settings
      self.account_settings_options.select{|k, v| v[:inheritable]}.keys
    end
  end

  def self.included(klass)
    klass.extend(ClassMethods)
    klass.send(:cattr_accessor, :account_settings_options)
    klass.account_settings_options ||= {}
  end

  def cached_inherited_setting(setting)
    self.shard.activate do
      RequestCache.cache("inherited_settings", self, setting) do
        Rails.cache.fetch([setting, self.global_id].cache_key) do
          calculate_inherited_setting(setting)
        end
      end
    end
  end

  # should continue down the account chain until it reaches a locked value
  # otherwise use the last explicitly set value
  def calculate_inherited_setting(setting)
    inherited_hash = {:locked => false, :value => self.class.account_settings_options[setting][:default]}
    self.account_chain.reverse_each do |acc|
      current_hash = acc.settings[setting]
      next if current_hash.nil?

      if !current_hash.is_a?(Hash)
        current_hash = {:locked => false, :value => current_hash}
      end
      current_hash[:inherited] = true if (self != acc)

      if current_hash[:locked]
        return current_hash
      else
        inherited_hash = current_hash
      end
    end
    return inherited_hash
  end
end

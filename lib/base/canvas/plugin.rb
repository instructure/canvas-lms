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
#

module Canvas
  class NoPluginError < StandardError; end

  class Plugin
    @registered_plugins = {}

    attr_accessor :meta
    attr_reader :id, :tag

    def initialize(id, tag = nil)
      @id = id.to_s
      @tag = tag.to_s if tag
      @meta = {
        name: id.to_s.humanize,
        description: nil,
        website: nil,
        author: nil,
        author_website: nil,
        version: nil,
        settings_partial: nil,
        settings: nil,
        encrypted_settings: nil,
        base: nil
      }.with_indifferent_access
    end

    # custom serialization, since the meta can containt procs
    def _dump(_depth)
      id.to_s
    end

    def self._load(str)
      find(str)
    end

    def encode_with(coder)
      coder["id"] = id.to_s
    end

    Psych.add_domain_type("ruby/object", "Canvas::Plugin") do |_type, val|
      Canvas::Plugin.find(val.id)
    end

    def default_settings
      settings = @meta[:settings]
      settings = settings.call if settings.respond_to?(:call)
      settings
    end

    def saved_settings
      PluginSetting.settings_for_plugin(id, self)
    end

    def settings
      saved_settings
    end

    def enabled?
      ps = PluginSetting.cached_plugin_setting(id)
      return false unless ps

      ps.valid_settings? && ps.enabled?
    end

    def encrypted_settings
      @meta[:encrypted_settings]
    end

    %i[name description website author author_website].each do |method|
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{method}
          t_if_proc(@meta[:#{method}]) || ''
        end
      RUBY
    end

    def setting(name)
      t_if_proc(settings[name])
    end

    def t_if_proc(attribute)
      attribute.is_a?(Proc) ? instance_exec(&attribute) : attribute
    end

    def validator
      @meta[:validator]
    end

    def version
      @meta[:version]
    end

    def settings_partial
      @meta[:settings_partial]
    end

    def has_settings_partial?
      meta[:settings_partial].present?
    end

    def test_cluster_inherit?
      meta.fetch(:test_cluster_inherit, true)
    end

    # base class/module for this plugin
    def base
      @meta[:base].is_a?(Symbol) ? @meta[:base].to_s.constantize : @meta[:base]
    end

    # arbitrary meta key/value pairs (these aren't configurable settings)
    def metadata(name)
      t_if_proc(@meta[name])
    end

    def translate(key, default, options = {})
      key = "canvas.plugins.#{@id}.#{key}" unless key.start_with?("#")
      I18n.t(key, default, options)
    end
    alias_method :t, :translate

    # Let the plugin do any validations necessary.
    # If the plugin has defined a validator, call
    # the :validate method on that validator.  If it
    # doesn't return a hash then consider it a failure.
    # The validator receives the model so that it can
    # add any errors that it would like.
    def validate_settings(plugin_setting, settings)
      if validator
        begin
          validator_module = Canvas::Plugins::Validators.const_get(validator)
        rescue NameError
          plugin_setting.errors.add(:base, "provided validator #{validator} failed to load")
          return false
        end
        res = validator_module.validate(settings, plugin_setting)
        if res.is_a?(Hash)
          plugin_setting.settings = (plugin_setting.settings || default_settings || {}).with_indifferent_access.merge(res || {})
        else
          false
        end
      else
        plugin_setting.settings = (plugin_setting.settings || default_settings || {}).with_indifferent_access.merge(settings || {})
      end
    end

    def self.register(id, tag = nil, meta = {})
      raise "Id required for a plugin" if id.nil?

      p = Plugin.new(id, tag)
      p.meta.merge! meta
      @registered_plugins[p.id] = p
    end

    def self.all
      @registered_plugins.values.sort_by(&:name)
    end

    def self.all_for_tag(tag)
      @registered_plugins.values.select { |p| p.tag == tag.to_s }.sort_by(&:name)
    end

    def self.find(id)
      @registered_plugins[id.to_s] || nil
    end

    def self.find!(id)
      raise(NoPluginError) if id.nil?

      @registered_plugins[id.to_s] || raise(NoPluginError)
    end

    def self.value_to_boolean(value, ignore_unrecognized: false)
      if [true, false].include?(value)
        return value
      elsif value.is_a?(String) || value.is_a?(Symbol) || value.is_a?(Integer)
        return true if %w[yes y true t on 1].include?(value.to_s.downcase)
        return false if %w[no n false f off 0].include?(value.to_s.downcase)
      else
        ignore_unrecognized = true unless value.nil?
      end
      return nil if ignore_unrecognized

      value.to_i != 0
    end
  end
end

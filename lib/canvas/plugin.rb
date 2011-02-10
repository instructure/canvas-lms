require 'canvas'

module Canvas

  class NoPluginError < StandardError;end

  class Plugin
    @registered_plugins = {}
    
    attr_accessor :meta, :settings
    attr_reader :id, :tag

    def initialize(id, tag=nil)
      @id = id.to_s
      @tag = tag.to_s if tag
      @meta = {
              :name=>id.to_s.humanize,
              :description=>nil,
              :website=>nil,
              :author=>nil,
              :author_website=>nil,
              :version=>nil,
              :settings_partial=>nil,
              :settings=>nil
      }.with_indifferent_access
    end
    
    def name
      @meta[:name]
    end
    
    def default_settings
      @meta[:settings]
    end
    
    def saved_settings
      PluginSetting.settings_for_plugin(self.id, self)
    end
    
    def settings
      # TODO: once we have distributed memcache we can
      # cache this properly across all web servers
      saved_settings
    end
    
    def description
      @meta[:description]
    end
    
    def website
      @meta[:website]
    end
    
    def author
      @meta[:author]
    end
    
    def author_website
      @meta[:author_website]
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
      !meta[:settings_partial].blank?
    end

    # Let the plugin do any validations necessary.
    # If the plugin has defined a validator, call
    # the :validate method on that validator.  If it
    # doesn't return a hash then consider it a failure.
    # The validator receives the model so that it can
    # add any errors that it would like.
    def validate_settings(plugin_setting, settings)
      if meta[:validator] 
        validator_module = Canvas::Plugins::Validators.const_defined?(validator) && Canvas::Plugins::Validators.const_get(validator)
        if validator_module && validator_module.respond_to?(:validate)
          res = validator_module.validate(settings, plugin_setting)
          if res.is_a?(Hash)
            plugin_setting.settings = self.settings.with_indifferent_access.merge(res)
          else
            false
          end
        else
          plugin_setting.errors.add_to_base("provided validator #{validator} failed to load")
          false
        end
      else
        plugin_setting.settings = self.settings.with_indifferent_access.merge(settings)
      end
    end

    def self.register(id, tag=nil, meta={})
      raise "Id required for a plugin" if id.nil?
      p = Plugin.new(id, tag)
      p.meta.merge! meta
      @registered_plugins[p.id] = p
    end
    
    def self.all
      @registered_plugins.values.sort{|p,p2| p.name <=> p2.name}
    end

    def self.all_for_tag(tag)
      @registered_plugins.values.select{|p|p.tag == tag.to_s}.sort{|p,p2| p.name <=> p2.name}
    end

    def self.find(id)
      @registered_plugins[id.to_s] || nil
    end

    def self.find!(id)
      raise(NoPluginError) if id.nil?
      @registered_plugins[id.to_s] || raise(NoPluginError)
    end
  end
  
  module Plugins
    module Validators
    end
  end
end

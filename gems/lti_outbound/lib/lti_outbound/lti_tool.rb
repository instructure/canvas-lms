module LtiOutbound
  class LTITool
    PRIVACY_LEVEL_PUBLIC = :public
    PRIVACY_LEVEL_NAME_ONLY = :name_only
    PRIVACY_LEVEL_EMAIL_ONLY = :email_only
    PRIVACY_LEVEL_ANONYMOUS  = :anonymous

    attr_accessor :consumer_key, :privacy_level, :name, :settings, :shared_secret

    def include_name?
      [PRIVACY_LEVEL_PUBLIC, PRIVACY_LEVEL_NAME_ONLY].include? privacy_level
    end

    def include_email?
      [PRIVACY_LEVEL_PUBLIC, PRIVACY_LEVEL_EMAIL_ONLY].include? privacy_level
    end

    def public?
      [PRIVACY_LEVEL_PUBLIC].include? privacy_level
    end

    def settings
      @settings || {}
    end

    # sets the custom fields from the main tool settings, and any on individual resource type settings
    def set_custom_fields(hash, resource_type)
      fields = [settings[:custom_fields] || {}]
      if resource_type && settings[resource_type.to_sym]
        fields << (settings[resource_type.to_sym][:custom_fields] || {})
      end
      fields.each do |field_set|
        field_set.each do |key, val|
          key = key.to_s.gsub(/[^\w]/, '_').downcase
          if key.match(/^custom_/)
            hash[key] = val
          else
            hash["custom_#{key}"] = val
          end
        end
      end
      nil
    end

    def selection_width(resource_type)
      extension_setting(resource_type, :selection_width)
    end

    def selection_height(resource_type)
      extension_setting(resource_type, :selection_height)
    end

    private

    #Duplicated in ContextExternalTool
    def extension_setting(type, property = nil)
      type = type.to_sym
      return settings[type] unless property
      (settings[type] && settings[type][property]) || settings[property] || extension_default_value(property)
    end

    #Duplicated in ContextExternalTool
    def extension_default_value(property)
      case property
        when :url
          url
        when :selection_width
          800
        when :selection_height
          400
        else
          nil
      end
    end
  end
end

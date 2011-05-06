I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')] +
                  Dir[Rails.root.join('vendor', 'plugins', '*', 'config', 'locales', '**', '*.{rb,yml}')]

Gem.loaded_specs.values.each do |spec|
  path = spec.full_gem_path
  translations_path = File.expand_path(File.join(path, 'config', 'locales'))
  next unless File.directory?(translations_path)
  I18n.load_path += Dir[File.join(translations_path, '**', '*.{rb,yml}')]
end

ActionView::Helpers::FormHelper.module_eval do
  # a convenience method to put the ":" after the label text (or do whatever
  # the selected locale dictates)
  def blabel(object_name, method, text = nil, options = {})
    if text.is_a?(Hash)
      options = text
      text = nil
    end
    options[:before] = true
    label(object_name, method, text, options)
  end

  def label_with_symbol_translation(object_name, method, text = nil, options = {})
    text = method if text.nil? && method.is_a?(Symbol)
    if text.is_a?(Symbol)
      text = 'labels.#{text}' unless text.to_s =~ /\A#/
      text = t(text, options.delete(:en))
    end
    text = before_label(text) if options[:before]
    label_without_symbol_translation(object_name, method, text, options)
  end
  alias_method_chain :label, :symbol_translation

  def before_label(text_or_key, default_value = nil)
    text_or_key = t('labels.' + text_or_key.to_s, default_value) if text_or_key.is_a?(Symbol)
    t("before_label_wrapper", "%{text}:", :text => text_or_key)
  end
end

ActionView::Helpers::FormBuilder.class_eval do
  def blabel(method, text = nil, options = {})
    if text.is_a?(Hash)
      options = text
      text = nil
    end
    options[:before] = true
    label(method, text, options)
  end
end

I18n.class_eval do
  class << self
    include ::ActionView::Helpers::TextHelper
    # if one of the interpolated values is a SafeBuffer (e.g. the result of a
    # link_to call) or the string itself is, we don't want anything to get
    # double-escaped when output in the view (since string is not html_safe).
    # so we escape anything that's not safe prior to interpolation, and make
    # sure we return a SafeBuffer.
    def interpolate_hash_with_html_safety_awareness(string, values)
      if string.html_safe? || values.values.any?{ |v| v.is_a?(ActiveSupport::SafeBuffer) }
        values.each_pair{ |key, value| values[key] = ERB::Util.h(value) unless value.html_safe? }
        string = ERB::Util.h(string) unless string.html_safe?
      end
      interpolate_hash_without_html_safety_awareness(string, values)
    end

    alias_method_chain :interpolate_hash, :html_safety_awareness

    # removes left padding from %e / %k / %l
    def localize_with_whitespace_removal(object, options = {})
      localize_without_whitespace_removal(object, options).gsub(/\s{2,}/, ' ').strip
    end
    alias_method_chain :localize, :whitespace_removal

    def translate_with_default_and_count_magic(key, *args)
      default = args.shift if args.first.is_a?(String) || args.size > 1
      options = args.shift || {}
      options[:default] ||= if options[:count]
        case default
          when String
            pluralize(options[:count], default)
          when Hash
            case default
              when 0
                default[:zero]
              when 1
                default[:one]
            end || default[:other]
          else
            default
        end
      else
        default
      end
      translate_without_default_and_count_magic(key.to_s.sub(/\A#/, ''), options)
    end
    alias_method_chain :translate, :default_and_count_magic
    alias :t :translate
  end
end

ActionView::Base.class_eval do
  def translate(key, default, options = {})
    key = key.to_s
    key = "#{template.base_path}.#{template.name.sub(/\A_/, '')}.#{key}" unless key.sub!(/\A#/, '')
    I18n.translate(key, default, options)
  end
  alias :t :translate
end

ActionController::Base.class_eval do
  def translate(key, default, options = {})
    key = key.to_s
    key = "#{controller_name}.#{action_name}.#{key}" unless key.sub!(/\A#/, '')
    I18n.translate(key, default, options)
  end
  alias :t :translate
end

ActiveRecord::Base.class_eval do
  def translate(key, default, options = {})
    self.class.translate(key, default, options)
  end
  alias :t :translate  

  class << self
    # with STI fallback, e.g. try both 'subclass.key' and 'superclass.key'
    # this is useful when you have t calls in the superclass
    def translate(key, default, options = {})
      key = key.to_s
      unless key.sub!(/\A#/, '')
        scopes = self_and_descendants_from_active_record.map{ |klass| klass.name.underscore }.reverse
        key = "#{scopes.shift}.#{key}"
        default = scopes.map{ |scope| "#{scope}.#{key}"} + Array(default)
      end
      I18n.translate(key, default, options)
    end
    alias :t :translate
  end
end

ActionMailer::Base.class_eval do
  def translate(key, default, options = {})
    key = "#{mailer_name}.#{action_name}.#{key}" unless key.sub!(/\A#/, '')
    I18n.translate(key, default, options)
  end
  alias :t :translate
end

I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')] +
                  Dir[Rails.root.join('vendor', 'plugins', '*', 'config', 'locales', '**', '*.{rb,yml}')]
I18n.load_path -= Dir[Rails.root.join('config', 'locales', 'generated', '**', '*.{rb,yml}')]
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

Gem.loaded_specs.values.each do |spec|
  path = spec.full_gem_path
  translations_path = File.expand_path(File.join(path, 'config', 'locales'))
  next unless File.directory?(translations_path)
  I18n.load_path += Dir[File.join(translations_path, '**', '*.{rb,yml}')]
end

module I18nUtilities
  def before_label(text_or_key, default_value = nil, *args)
    if default_value
      text_or_key = "labels.#{text_or_key}" unless text_or_key.to_s =~ /\A#/
      text_or_key = t(text_or_key, default_value, *args)
    end
    t("#before_label_wrapper", "%{text}:", :text => text_or_key)
  end

  def _label_symbol_translation(method, text, options)
    if text.is_a?(Hash)
      options = text
      text = nil
    end
    text = method if text.nil? && method.is_a?(Symbol)
    if text.is_a?(Symbol)
      text = "labels.#{text}" unless text.to_s =~ /\A#/
      text = t(text, options.delete(:en))
    end
    text = before_label(text) if options[:before]
    return text, options
  end
end

ActionView::Base.send(:include, I18nUtilities)
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
    text, options = _label_symbol_translation(method, text, options)
    label_without_symbol_translation(object_name, method, text, options)
  end
  alias_method_chain :label, :symbol_translation
end

ActionView::Helpers::InstanceTag.send(:include, I18nUtilities)
ActionView::Helpers::FormTagHelper.class_eval do
  def label_tag_with_symbol_translation(method, text = nil, options = {})
    text, options = _label_symbol_translation(method, text, options)
    label_tag_without_symbol_translation(method, text, options)
  end
  alias_method_chain :label_tag, :symbol_translation
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
    attr_writer :localizer

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

    # Public: If a localizer has been set, use it to set the locale and then
    # delete it.
    #
    # Returns nothing.
    def set_locale_with_localizer
      if @localizer
        self.locale = @localizer.call
        @localizer = nil
      end
    end

    def translate_with_default_and_count_magic(key, *args)
      set_locale_with_localizer

      default = args.shift if args.first.is_a?(String) || args.size > 1
      options = args.shift || {}
      options[:default] ||= if options[:count]
        case default
          when String
            default =~ /\A[\w\-]+\z/ ? pluralize(options[:count], default) : default
          when Hash
            case options[:count]
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

      result = translate_without_default_and_count_magic(key.to_s.sub(/\A#/, ''), options)

      # it's assumed that if you're using any wrappers, you're going
      # for html output. so the result will be escaped before being
      # wrapped, then the output tagged as html safe.
      if wrapper = options[:wrapper]
        result = I18n.apply_wrappers(result, wrapper)
      end

      result
    end
    alias_method_chain :translate, :default_and_count_magic
    alias :t :translate
  end

  WRAPPER_REGEXES = {}

  def self.apply_wrappers(string, wrappers)
    string = ERB::Util.h(string) unless string.html_safe?
    wrappers = { '*' => wrappers } unless wrappers.is_a?(Hash)
    wrappers.sort { |a, b| -(a.first.length <=> b.first.length) }.each do |sym, replace|
      regex = (WRAPPER_REGEXES[sym] ||= %r{#{Regexp.escape(sym)}([^#{Regexp.escape(sym)}]*)#{Regexp.escape(sym)}})
      string = string.gsub(regex, replace)
    end
    string.html_safe
  end
end

ActionView::Base.class_eval do
  def i18n_scope
    "#{template.base_path}.#{template.name.sub(/\A_/, '')}"
  end

  def translate(key, default, options = {})
    key = key.to_s
    key = "#{i18n_scope}.#{key}" unless key.sub!(/\A#/, '')
    I18n.translate(key, default, options)
  end
  alias :t :translate
end

ActionController::Base.class_eval do
  def translate(key, default, options = {})
    key = key.to_s
    key = "#{controller_name}.#{key}" unless key.sub!(/\A#/, '')
    I18n.translate(key, default, options)
  end
  alias :t :translate
end

ActiveRecord::Base.class_eval do
  include I18nUtilities
  extend I18nUtilities

  def translate(key, default, options = {})
    self.class.translate(key, default, options)
  end
  alias :t :translate  

  class << self
    def translate(key, default, options = {})
      key = key.to_s
      key = "#{name.underscore}.#{key}" unless key.sub!(/\A#/, '')
      I18n.translate(key, default, options)
    end
    alias :t :translate

    def validates_locale(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      args << :locale if args.empty?
      if options[:allow_nil] && !options[:allow_empty]
        before_validation do |record|
          args.each do |field|
            record.write_attribute(field, nil) if record.read_attribute(field) == ''
          end
        end
      end
      args.each do |field|
        validates_inclusion_of field, options.merge(:in => I18n.available_locales.map(&:to_s))
      end
    end
  end
end

ActionMailer::Base.class_eval do
  def translate(key, default, options = {})
    key = key.to_s
    key = "#{mailer_name}.#{action_name}.#{key}" unless key.sub!(/\A#/, '')
    I18n.translate(key, default, options)
  end
  alias :t :translate
end

ActiveSupport::CoreExtensions::Array::Conversions.class_eval do
  def to_sentence_with_simple_or(options = {})
    if options == :or
      to_sentence_without_simple_or(:two_words_connector => I18n.t('support.array.or.two_words_connector'),
                                    :last_word_connector => I18n.t('support.array.or.last_word_connector'))
    else
      to_sentence_without_simple_or(options)
    end
  end
  alias_method_chain :to_sentence, :simple_or
end

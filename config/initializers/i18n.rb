# loading all the locales has a significant (>30%) impact on the speed of initializing canvas
# so we skip it in situations where we don't need the locales, such as in development mode and in rails console
skip_locale_loading = (Rails.env.development? || Rails.env.test? || $0 == 'irb') && !ENV['RAILS_LOAD_ALL_LOCALES']
if skip_locale_loading
  I18n.load_path = I18n.load_path.grep(%r{/(locales|en)\.yml\z})
else
  I18n.load_path << (Rails.root + "config/locales/locales.yml").to_s # add it at the end, to trump any weird/invalid stuff in locale-specific files
end

I18n.backend = I18nema::Backend.new
I18nema::Backend.send(:include, I18n::Backend::Fallbacks)
I18n.backend.init_translations

I18n.enforce_available_locales = true

if ENV['LOLCALIZE']
  require 'i18n_tasks'
  I18n.send :extend, I18nTasks::Lolcalize
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
    text = before_label(text) if options.delete(:before)
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
      if string.is_a?(ActiveSupport::SafeBuffer) && string.html_safe?
        string.class.new(interpolate_hash_without_html_safety_awareness(string.to_str, values))
      else
        interpolate_hash_without_html_safety_awareness(string, values)
      end
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
    wrappers.sort_by { |a| -a.first.length }.each do |sym, replace|
      regex = (WRAPPER_REGEXES[sym] ||= %r{#{Regexp.escape(sym)}([^#{Regexp.escape(sym)}]*)#{Regexp.escape(sym)}})
      string = string.gsub(regex, replace)
    end
    string.html_safe
  end

  def self.qualified_locale
    I18n.backend.direct_lookup(I18n.locale.to_s, "qualified_locale") || "en-US"
  end
end

if CANVAS_RAILS2
  ActionView::Base.class_eval do
    def i18n_scope
      "#{template.base_path}.#{template.name.sub(/\A_/, '')}"
    end
  end
else
  ActionView::LookupContext.class_eval do
    attr_accessor :i18n_scope
  end

  ActionView::TemplateRenderer.class_eval do
    def render_template_with_assign(template, *a)
      old_i18n_scope = @lookup_context.i18n_scope
      if template.respond_to?(:virtual_path) && (virtual_path = template.virtual_path)
        @lookup_context.i18n_scope = virtual_path.sub(/\/_/, '/').gsub('/', '.')
      end
      render_template_without_assign(template, *a)
    ensure
      @lookup_context.i18n_scope = old_i18n_scope
    end
    alias_method_chain :render_template, :assign
  end

  ActionView::PartialRenderer.class_eval do
    def render_partial_with_assign
      old_i18n_scope = @lookup_context.i18n_scope
      @lookup_context.i18n_scope = @path.sub(/\/_/, '/').gsub('/', '.') if @path
      render_partial_without_assign
    ensure
      @lookup_context.i18n_scope = old_i18n_scope
    end
    alias_method_chain :render_partial, :assign
  end

  ActionView::Base.class_eval do
    delegate :i18n_scope, :to => :lookup_context
  end
end

ActionView::Base.class_eval do
  # can accept either translate(key, default: "default text", option: ...) or
  # translate(key, "default text", option: ...). when using the former (default
  # in the options), it's treated as if prepended with a # anchor.
  def translate(key, *rest)
    options = rest.extract_options!
    default_in_options = options.has_key?(:default)
    default_in_args = !rest.empty?
    raise ArgumentError, "wrong arity" if rest.size > 1
    raise ArgumentError, "didn't provide default in args or options" if !default_in_args && !default_in_options
    raise ArgumentError, "can't provide default in both args and options" if default_in_args && default_in_options
    default = default_in_options ? options[:default] : rest.first
    key = key.to_s
    key = "#{i18n_scope}.#{key}" unless default_in_options || key.sub!(/\A#/, '')
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

    # so that we don't load up the locales until we need them
    LOCALE_LIST = []
    def LOCALE_LIST.include?(item)
      I18n.available_locales.map(&:to_s).include?(item)
    end

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
        validates_inclusion_of field, options.merge(:in => LOCALE_LIST)
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

require 'active_support/core_ext/array/conversions'

class Array
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

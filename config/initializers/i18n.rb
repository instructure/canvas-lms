# loading all the locales has a significant (>30%) impact on the speed of initializing canvas
# so we skip it in situations where we don't need the locales, such as in development mode and in rails console
skip_locale_loading = (Rails.env.development? ||
  Rails.env.test? ||
  $0 == 'irb' ||
  $PROGRAM_NAME == 'rails_console' ||
  $0 =~ /rake$/)
if ENV['RAILS_LOAD_ALL_LOCALES']
  skip_locale_loading = ENV['RAILS_LOAD_ALL_LOCALES'] == '0'
end
# always load locales for rake tasks that we know need them
if $0 =~ /rake$/ && !($ARGV & ["i18n:generate_js",
                               "canvas:compile_assets",
                               "canvas:compile_assets_dev",
                               "js:test"]).empty?
  skip_locale_loading = false
end

load_path = Rails.application.config.i18n.railties_load_path
if skip_locale_loading
  load_path.replace(load_path.grep(%r{/(locales|en)\.yml\z}))
else
  load_path << (Rails.root + "config/locales/locales.yml").to_s # add it at the end, to trump any weird/invalid stuff in locale-specific files
end

Rails.application.config.i18n.enforce_available_locales = true
Rails.application.config.i18n.fallbacks = true

module DontTrustI18nPluralizations
  def pluralize(locale, entry, count)
    super
  rescue I18n::InvalidPluralizationData => e
    Rails.logger.error("#{e.message} in locale #{locale.inspect}")
    ""
  end

  # make sure count special values get formatted
  def interpolate(locale, string, values = {})
    if values[:count] && values[:count].is_a?(Numeric)
      values[:count] = ActiveSupport::NumberHelper.number_to_delimited(values[:count])
    end
    super
  end
end
I18n::Backend::Simple.include(DontTrustI18nPluralizations)

module CalculateDeprecatedFallbacks
  def reload!
    super
    I18n.available_locales.each do |locale|
      if (deprecated_for = I18n.backend.send(:lookup, locale.to_s, 'deprecated_for'))
        I18n.fallbacks[locale] = I18n.fallbacks[deprecated_for.to_sym]
      end
    end
  end
end
I18n.singleton_class.prepend CalculateDeprecatedFallbacks

I18nliner.infer_interpolation_values = false

module I18nliner
  module RehashArrays
    def infer_pluralization_hash(default, *args)
      if default.is_a?(Array) && default.all?{|a| a.is_a?(Array) && a.size == 2 && a.first.is_a?(Symbol)}
        # this was a pluralization hash but rails 4 made it an array in the view helpers
        return Hash[default]
      end
      super
    end
  end
  CallHelpers.extend(RehashArrays)
end

if ENV['LOLCALIZE']
  require 'i18n_tasks'
  I18n.send :extend, I18nTasks::Lolcalize
end

module I18nUtilities
  def before_label(text_or_key, default_value = nil, *args)
    if default_value
      text_or_key = "labels.#{text_or_key}" unless text_or_key.to_s =~ /\A#/
      text_or_key = respond_to?(:t) ? t(text_or_key, default_value, *args) : I18n.t(text_or_key, default_value, *args)
    end
    I18n.t("#before_label_wrapper", "%{text}:", :text => text_or_key)
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

  def n(*args)
    I18n.n(*args)
  end
end

ActionView::Base.send(:include, I18nUtilities)
ActionView::Helpers::FormHelper.send(:include, I18nUtilities)
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
  # when removing this, be sure to remove it from i18nliner_extensions.rb
  alias_method_chain :label, :symbol_translation
end

ActionView::Helpers::FormTagHelper.send(:include, I18nUtilities)
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

module NumberLocalizer
  # precision (default nil): if nil, use the precision of the passed in number.
  #   if you want to cap precision, and have less precise numbers not have trailing zeros, you should be
  #   rounding the number before passing to this helper, and not passing precision
  # percentage (default false): format as a percentage
  def n(number, precision: nil, percentage: false)
    if percentage
      # no precision? default to the number's precision, not to some arbitrary precision
      if precision.nil?
        precision = 9
        strip_insignificant_zeros = true
      end
      return ActiveSupport::NumberHelper.number_to_percentage(number,
                                                              precision: precision,
                                                              strip_insignificant_zeros: strip_insignificant_zeros)
    end

    if precision.nil?
      return ActiveSupport::NumberHelper.number_to_delimited(number)
    end

    ActiveSupport::NumberHelper.number_to_rounded(number, precision: precision)
  end
end
I18n.singleton_class.include(NumberLocalizer)

I18n.send(:extend, Module.new {
  attr_accessor :localizer

  # Public: If a localizer has been set, use it to set the locale and then
  # delete it.
  #
  # Returns nothing.
  def set_locale_with_localizer
    if localizer
      self.locale = localizer.call
      self.localizer = nil
    end
  end

  def translate(*args)
    set_locale_with_localizer

    begin
      super
    rescue I18n::MissingInterpolationArgument
      # if we change an en default and its interpolation logic without
      # changing its key, we might have broken translations during the
      # window where we're waiting for updated translations. broken as in
      # crashy, not just missing. if that's the case, just fall back to
      # english, rather than asploding
      key, options = I18nliner::CallHelpers.infer_arguments(args)
      raise if (options[:locale] || locale) == default_locale
      super(key, options.merge(locale: default_locale))
    end
  end
  alias :t :translate

  def bigeasy_locale
    backend.send(:lookup, locale.to_s, "bigeasy_locale") || locale.to_s.tr('-', '_')
  end

  def fullcalendar_locale
    backend.send(:lookup, locale.to_s, "fullcalendar_locale") || locale.to_s.downcase
  end

  def moment_locale
    backend.send(:lookup, locale.to_s, "moment_locale") || locale.to_s.downcase
  end
})

# see also corresponding extractor logic in
# i18n_extraction/i18nliner_extensions
require "i18n_extraction/i18nliner_scope_extensions"

ActionView::Template.class_eval do
  def render_with_i18nliner_scope(view, *args, &block)
    old_i18nliner_scope = view.i18nliner_scope
    if @virtual_path
      view.i18nliner_scope = I18nliner::Scope.new(@virtual_path.gsub(/\/_?/, '.'))
    end
    render_without_i18nliner_scope(view, *args, &block)
  ensure
    view.i18nliner_scope = old_i18nliner_scope
  end
  alias_method_chain :render, :i18nliner_scope
end

ActionView::Base.class_eval do
  attr_accessor :i18nliner_scope
end

ActionController::Base.class_eval do
  def i18nliner_scope
    @i18nliner_scope ||= I18nliner::Scope.new(controller_path.tr('/', '.'))
  end
end

ActiveRecord::Base.class_eval do
  include I18nUtilities
  extend I18nUtilities

  def i18nliner_scope
    self.class.i18nliner_scope
  end

  def self.i18nliner_scope
    @i18nliner_scope ||= I18nliner::Scope.new(name.underscore)
  end

  class << self
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
        validates_inclusion_of field, options.merge(:in => LOCALE_LIST, :if => :"#{field}_changed?")
      end
    end
  end
end

ActionMailer::Base.class_eval do
  def i18nliner_scope
    @i18nliner_scope ||= I18nliner::Scope.new("#{mailer_name}.#{action_name}")
  end

  def translate(key, default, options = {})
    key, options = I18nliner::CallHelpers.infer_arguments(args)
    options = inferpolate(options) if I18nliner.infer_interpolation_values
    options[:i18nliner_scope] = i18nliner_scope
    I18n.translate(key, options)
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

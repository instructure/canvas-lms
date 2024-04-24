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

module CanvasI18nFallbacks
  # see BCP-47 "Tags for Identifying Languages" for the grammar
  # definition that led to this pattern match. It is not 100%
  # strictly implemented but this will be more than sufficient
  # for Canvas
  LANG_PAT = /
    ^
    ([a-z]{2,3})                               # language
    (-[a-z]{4})?                               # optional script
    (-(?:[a-z]{2}|[0-9]{3}))?                  # optional region
    ((?:-(?:[a-z0-9]{5,8}|[0-9][a-z0-9]{3}))*) # optional variants
    ((?:-[a-wy-z](?:-[a-z0-9]{2,8})*)*)        # optional extensions
    (-x(?:-[a-z0-9]{1,8})+)*                   # optional private use
    $
  /ix

  # This fallback order is more intelligent than simply lopping off
  # elements from the end. For instance, in Canvas we use the private
  # tag x-k12 in several locales, and we would want to keep that as long
  # as possible, for instance we would like sv-FI-x-k12 to fall back to
  # sv-x-k12 first, and then sv.
  FALLBACK_ORDER = [
    [0, 1, 2, 3, 4, 5].freeze,   # everything
    [0, 1, 2, 3, 5].freeze,      # remove extensions
    [0, 1, 2, 5].freeze,         # remove variants
    [0, 1, 5].freeze,            # remove region
    [0, 1, 2].freeze,            # remove private tags
    [0, 2, 5].freeze,            # remove script
    [0, 2].freeze,               # only language and region
    [0, 5].freeze,               # only language and private tags
    [0, 1].freeze,               # only language and script
    [0].freeze                   # only language code
  ].freeze

  def self.fallbacks(locale)
    result = locale.match LANG_PAT

    return [] unless result

    existing_elements = result.captures.map(&:present?)

    order = FALLBACK_ORDER.map do |a|
      a.dup.select { |e| existing_elements[e] }
    end

    order.uniq.map do |ordering|
      ordering.map { |idx| result.captures[idx] }.join.to_sym
    end
  end
end

# Now monkey-patch the i18n gem's Fallbacks::compute method to call our
# fallback generator rather than its own.
# rubocop:disable Style/OptionalBooleanParameter
module I18n
  module Locale
    class Fallbacks < Hash
      def compute(tags, include_defaults = true, exclude = [])
        result = Array(tags).flat_map do |tag|
          tags = CanvasI18nFallbacks.fallbacks(tag).map(&:to_sym) - exclude
          tags.each { |t| tags += compute(@map[t], false, exclude + tags) if @map[t] }
          tags
        end
        result.push(*defaults) if include_defaults
        result.uniq!
        result.compact!
        result
      end
    end
  end
end
# rubocop:enable Style/OptionalBooleanParameter

Rails.configuration.to_prepare do
  Rails.application.config.i18n.enforce_available_locales = true
  Rails.application.config.i18n.fallbacks = true

  # create a unique backend class with the behaviors we want
  backend_class = Class.new(I18n::Backend::MetaLazyLoadable)
  backend_class.prepend(I18n::Backend::DontTrustPluralizations)
  backend_class.include(I18n::Backend::CSV)
  backend_class.include(I18n::Backend::Fallbacks)

  I18n.backend = backend_class.new(
    meta_keys: %w[aliases community crowdsourced custom locales],
    lazy_load: !Rails.application.config.eager_load
  )
end

module FormatInterpolatedNumbers
  def interpolate_hash(string, values)
    values = values.dup
    values.each do |key, value|
      next unless value.is_a?(Numeric)

      values[key] = ActiveSupport::NumberHelper.number_to_delimited(value)
    end
    super(string, values)
  end
end
I18n.singleton_class.prepend(FormatInterpolatedNumbers)

I18nliner.infer_interpolation_values = false

module I18nliner
  module RehashArrays
    def infer_pluralization_hash(default, *args)
      if default.is_a?(Array) && default.all? { |a| a.is_a?(Array) && a.size == 2 && a.first.is_a?(Symbol) }
        # this was a pluralization hash but rails 4 made it an array in the view helpers
        return default.to_h
      end

      super
    end
  end
  CallHelpers.extend(RehashArrays)
end

if ENV["LOLCALIZE"]
  require "i18n_tasks"
  I18n.extend I18nTasks::Lolcalize
end

module I18nUtilities
  def before_label(text_or_key, default_value = nil, *args)
    if default_value
      text_or_key = "labels.#{text_or_key}" unless text_or_key.to_s.start_with?("#")
      text_or_key = respond_to?(:t) ? t(text_or_key, default_value, *args) : I18n.t(text_or_key, default_value, *args)
    end
    I18n.t("#before_label_wrapper", "%{text}:", text: text_or_key)
  end

  def _label_symbol_translation(method, text, options)
    if text.is_a?(Hash)
      options = text
      text = nil
    end
    text = method if text.nil? && method.is_a?(Symbol)
    if text.is_a?(Symbol)
      text = "labels.#{text}" unless text.to_s.start_with?("#")
      text = t(text, options.delete(:en))
    end
    text = before_label(text) if options.delete(:before)
    [text, options]
  end

  def n(...)
    I18n.n(...)
  end
end

ActionView::Base.include I18nUtilities
ActionView::Helpers::FormHelper.include I18nUtilities
ActionView::Helpers::FormTagHelper.include I18nUtilities

module I18nFormHelper
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

  # when removing this, be sure to remove it from i18nliner_extensions.rb
  def label(object_name, method, text = nil, options = {})
    text, options = _label_symbol_translation(method, text, options)
    super(object_name, method, text, options)
  end
end
ActionView::Base.include(I18nFormHelper)
ActionView::Helpers::FormHelper.prepend(I18nFormHelper)

module I18nFormTagHelper
  def label_tag(method, text = nil, options = {})
    text, options = _label_symbol_translation(method, text, options)
    super(method, text, options)
  end
end
ActionView::Helpers::FormTagHelper.prepend(I18nFormTagHelper)

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
        precision = 5
        strip_insignificant_zeros = true
      end
      return ActiveSupport::NumberHelper.number_to_percentage(number,
                                                              precision:,
                                                              strip_insignificant_zeros:)
    end

    if precision.nil?
      return ActiveSupport::NumberHelper.number_to_delimited(number)
    end

    ActiveSupport::NumberHelper.number_to_rounded(number, precision:)
  end

  def form_proper_noun_singular_genitive(noun)
    if I18n.locale.to_s.start_with?("de") && %(s ß x z).include?(noun.last)
      "#{noun}'"
    else
      I18n.t("#proper_noun_singular_genitive", "%{noun}'s", noun:)
    end
  end
end
I18n.singleton_class.include(NumberLocalizer)

I18n.extend(Module.new do
  attr_accessor :localizer

  # Public: If a localizer has been set, use it to set the locale and then
  # delete it.
  #
  # Returns nothing.
  def set_locale_with_localizer
    if localizer
      local_localizer, self.localizer = localizer, nil
      self.locale = local_localizer.call
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
  alias_method :t, :translate

  def locale
    set_locale_with_localizer
    super
  end

  def bigeasy_locale
    backend.send(:lookup, locale.to_s, "bigeasy_locale") || locale.to_s.tr("-", "_")
  end

  def fullcalendar_locale
    backend.send(:lookup, locale.to_s, "fullcalendar_locale") || locale.to_s.downcase
  end

  def rtl?
    backend.send(:lookup, locale.to_s, "rtl")
  end

  def moment_locale
    backend.send(:lookup, locale.to_s, "moment_locale") || locale.to_s.downcase
  end

  def dow_offset
    backend.send(:lookup, locale.to_s, "dow_offset") || 0
  end
end)

# see also corresponding extractor logic in
# i18n_extraction/i18nliner_extensions
require "i18n_extraction/i18nliner_scope_extensions"

module I18nTemplate
  def render(view, *, **)
    old_i18nliner_scope = view.i18nliner_scope
    if @virtual_path
      view.i18nliner_scope = I18nliner::Scope.new(@virtual_path.gsub(%r{/_?}, "."))
    end
    super
  ensure
    view.i18nliner_scope = old_i18nliner_scope
  end
end
ActionView::Template.prepend(I18nTemplate)

ActionView::Base.class_eval do
  attr_accessor :i18nliner_scope
end

ActionController::Base.class_eval do
  def i18nliner_scope
    @i18nliner_scope ||= I18nliner::Scope.new(controller_path.tr("/", "."))
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
    class LocalesProxy
      def include?(item)
        I18n.available_locales.map(&:to_s).include?(item)
      end
    end
    LOCALE_LIST = LocalesProxy.new

    def validates_locale(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      args << :locale if args.empty?
      if options[:allow_nil] && !options[:allow_empty]
        before_validation do |record|
          args.each do |field|
            record.write_attribute(field, nil) if record.read_attribute(field) == ""
          end
        end
      end
      args.each do |field|
        validates_inclusion_of field, options.merge(in: LOCALE_LIST, if: :"#{field}_changed?")
      end
    end
  end
end

module ToSentenceWithSimpleOr
  def to_sentence(options = {})
    if options == :or
      super(two_words_connector: I18n.t("support.array.or.two_words_connector"),
            last_word_connector: I18n.t("support.array.or.last_word_connector"))
    else
      super
    end
  end
end
Array.prepend(ToSentenceWithSimpleOr)

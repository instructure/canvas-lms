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

module LocaleSelection
  def infer_locale(options = {})
    context = options[:context]
    user = options[:user]
    root_account = options[:root_account]
    accept_language = options[:accept_language]
    session_locale = options[:session_locale]

    # groups cheat and set the context to be the group after get_context runs
    # but before set_locale runs, but we want to do locale lookup based on the
    # actual context.
    if context && context.is_a?(Group) && context.context
      context = context.context
    end

    sources = [
      -> { context.locale if context.try(:is_a?, Course) },
      -> { user.locale if user && user.locale },
      -> { session_locale if session_locale },
      -> { context.account.try(:default_locale, true) if context.try(:is_a?, Course) },
      -> { context.default_locale(true) if context.try(:is_a?, Account) },
      -> { root_account.try(:default_locale) },
      -> {
        if accept_language && locale = infer_browser_locale(accept_language, LocaleSelection.locales_with_aliases)
          user.update_attribute(:browser_locale, locale) if user && user.browser_locale != locale
          locale
        end
         },
      -> { user.try(:browser_locale) },
      -> { I18n.default_locale.to_s }
          ]

    sources.each do |source|
      locale = source.call
      locale = nil unless I18n.locale_available?(locale)
      return locale if locale
    end
    nil
  end

  QUALITY_VALUE = /;q=([01]\.(\d{0,3})?)/
  LANGUAGE_RANGE = /([a-zA-Z]{1,8}(-[a-zA-Z]{1,8})*|\*)(#{QUALITY_VALUE})?/
  SEPARATOR = /\s*,\s*/
  ACCEPT_LANGUAGE = /\A#{LANGUAGE_RANGE}(#{SEPARATOR}#{LANGUAGE_RANGE})*\z/

  def infer_browser_locale(accept_language, locales_with_aliases)
    return nil unless accept_language =~ ACCEPT_LANGUAGE
    supported_locales = locales_with_aliases.keys

    ranges = accept_language.downcase.split(SEPARATOR).map{ |range|
      quality = (range =~ QUALITY_VALUE) ? $1.to_f : 1
      [range.sub(/\s*;.*/, ''), quality]
    }
    ranges = ranges.sort_by{ |r,| r == '*' ? 1 : -r.count('-') }
    # we want the longest ranges first (and * last of all), since the "quality
    # factor assigned to a [language] ... is the quality value of the longest
    # language-range ... that matches", e.g.
    #   given that i accept 'en, es;q=0.9, en-US;q=0.8'
    #     and canvas is localized in 'en-US' and 'es'
    #   then i should get 'es' (en and en-US ranges both match en-US, and
    #                           en-US range is a longer match, so it loses)

    best_locales = supported_locales.inject([]) { |ary, locale|
      if best_range = ranges.detect { |r, q| r + '-' == (locale.downcase + '-')[0..r.size] || r == '*' }
        ary << [locale, best_range.last, ranges.index(best_range)] unless best_range.last == 0
      end
      ary
    }.sort_by{ |l, q, pos| [-q, pos, l.count('-'), l]}
    # wrt the sorting here, rfc2616 doesn't specify which tag is preferable
    # if there is a quality tie (due to prefix matching or otherwise).
    # technically they are equally acceptable.  we've decided to break ties
    # with:
    # * position listed in header (tie here comes from '*')
    # * length of locale (shorter first)
    # * alphabetical
    #
    # this seems reasonable for scenarios like the following:
    #   given that i accept 'en'
    #     and canvas is localized in 'en-US', 'en-GB-oy' and 'en-CA-eh'
    #   then i should get 'en-US'

    result = best_locales.first&.first

    # translate back to an actual locale, if it happened to be an alias
    result = locales_with_aliases[result] if locales_with_aliases[result]
    result
  end

  # gives you a hash of localized locales, e.g. {"en" => "English", "es" => "Español" }
  # if the locale name is not yet translated, it won't be included (even if
  # there are other translations for that locale)
  def available_locales
    result = {}
    settings = Canvas::Plugin.find(:i18n).settings || {}
    enabled_custom_locales = settings.select { |locale, enabled| enabled }.map(&:first).map(&:to_sym)
    I18n.available_locales.each do |locale|
      name = I18n.send(:t, :locales, :locale => locale)[locale]
      custom = I18n.send(:t, :custom, locale: locale) == true
      next if custom && !enabled_custom_locales.include?(locale)
      result[locale.to_s] = name if name
    end
    result
  end

  def self.custom_locales
    @custom_locales ||= I18n.available_locales.select{ |locale| I18n.send(:t, :custom, :locale => locale) == true }.sort
  end

  def crowdsourced_locales
    @crowdsourced_locales ||= I18n.available_locales.select{ |locale| I18n.send(:t, :crowdsourced, :locale => locale) == true }
  end

  def self.locales_with_aliases
    @locales_with_aliases ||= begin
      locales = I18n.available_locales.map { |l| [l.to_s, nil] }.to_h
      locales.keys.each do |locale|
        aliases = Array.wrap(I18n.send(:t, :aliases, locale: locale, default: nil))
        aliases.each do |a|
          locales[a] = locale
        end
      end
      locales
    end
  end
end

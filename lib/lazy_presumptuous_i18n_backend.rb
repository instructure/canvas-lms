# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

# Based off of I18n::Backend::Simple, this backend makes a presumption about
# your locale files -- with the exception of any file ending in `locales.yml`,
# every locale file should contain exactly one top-level key, and the file's
# name (minus the`.yml` extension) should be the same as that key. If you follow
# this convention, then this backend will lazy-load your languages. This can cut
# down dramatically on app initialization time (~35%) at the expense of a
# little delay (less than 1 second in local tests) the first time each new
# language is queried (which, in places like dev environments, targeted test
# runs, and rails console usage, is typically never).
#
# One more presumption: `meta_keys` are only stored in `locales.yml`. We
# eager-extract those so that they can be fetched without triggering a
# lazy-load of the entire locale. This accommodates methods like those found in
# the `LocaleSelection` module.
#
# There's a fair amount of copy-pasta from I18n::Backend::Simple in here that
# just replaces `translations` with `lazy_translations`. That's because the
# former is used in a few places (specs and rake tasks, incuding a task from
# i18nliner) that expect it to return the full set of translations for all
# languages. Therefore we avoid invoking `translations` in most places and
# instead use `lazy_translations` whenever possible, which only provides
# strings that have already been loaded.
class LazyPresumptuousI18nBackend
  include I18n::Backend::Base
  include I18n::Backend::Fallbacks

  def initialize(meta_keys: [], logger: nil)
    @meta_keys = meta_keys.map(&:to_s)
    @logger = logger
    @initialized = false
    @locale_metadata = {}
    @lazy_translations = {}
    @registered_translations = {}
    @load_locale_mutex = Mutex.new
  end

  # Rails will invoke this in an eager-loaded environment (i.e. production).
  def eager_load!
    ensure_initialized
    available_locales.each { |loc| load_locale(loc) }
    super
  end

  def available_locales
    ensure_initialized
    lazy_translations.keys | registered_translations.keys.map(&:to_sym)
  end

  def store_translations(locale, data, _options = nil)
    if I18n.enforce_available_locales &&
       I18n.available_locales_initialized? &&
       !I18n.available_locales.include?(locale.to_sym) &&
       !I18n.available_locales.include?(locale.to_s)
      return data
    end

    locale = locale.to_sym
    lazy_translations[locale] ||= {}
    data = data.deep_symbolize_keys
    lazy_translations[locale].deep_merge!(data)
  end

  def load_translations(*filenames)
    # overriding this method from I18n::Backend::Base to register files instead of load them
    filenames = I18n.load_path if filenames.empty?
    filenames.flatten.each { |filename| register_file(filename) }
  end

  def reload!
    log "reloading i18n backend"
    @initialized = false
    @locale_metadata = {}
    @lazy_translations = {}
    @registered_translations = {}
    super
  end

  # this is only used by external callers (including i18nliner), and it's only
  # used when they want to retrieve the full database of translations. so
  # eager-load everything before handing it over.
  def translations
    eager_load!
    lazy_translations
  end

  private

  attr_reader :registered_translations, :lazy_translations, :locale_metadata, :meta_keys, :initialized

  def ensure_initialized
    unless initialized
      load_translations
      @initialized = true
    end
  end

  def log(msg)
    @logger&.call(msg)
  end

  def register_file(filename)
    case (locale_from_filename = File.basename(filename, ".*"))
    when /locales$/
      data = YAML.load_file(filename)
      data.each do |locale, locale_data|
        # `store_translations` uses `deep_symbolize_keys`, so we do too to make
        # cached metadata lookups behave just like they would if they weren't
        # cached.
        locale_metadata[locale] = locale_data.slice(*meta_keys).deep_symbolize_keys
        register_translations(locale, locale_data)
      end
      log "parsing and registering #{filename} [#{data.keys.join(", ")}]"
    when "community"
      data = CSV.read(filename, headers: true)
      csv_locales = data.headers - ["key"]
      csv_locales.each do |csv_locale|
        locale_data = {
          community: data.map { |row| [row["key"].to_sym, row[csv_locale]] }.to_h
        }
        register_translations(csv_locale, locale_data)
      end
      log "parsing and registering #{filename} [#{csv_locales.join(", ")}]"
    else
      log "registering locale [#{locale_from_filename}] << #{filename}"
      register_translations(locale_from_filename, filename)
    end
  end

  def lookup(locale, key, scope = [], options = {})
    ensure_initialized

    if meta_keys.include?(key.to_s)
      return locale_metadata[locale.to_s].try(:[], key.to_sym)
    end

    load_locale(locale)

    # the rest of the method is copy-pasta from I18n::Backend::Simple except s/translations/lazy_translations/
    keys = I18n.normalize_keys(locale, key, scope, options[:separator])

    keys.inject(lazy_translations) do |result, partial_key|
      return nil unless result.is_a?(Hash)

      unless result.key?(partial_key)
        partial_key = partial_key.to_s.to_sym
        return nil unless result.key?(partial_key)
      end
      result = result[partial_key]
      result = resolve(locale, partial_key, result, options.merge(scope: nil)) if result.is_a?(Symbol)
      result
    end
  end

  def register_translations(locale, path_or_hash)
    registered_translations[locale] ||= []
    # if it's already registered, get rid of the old entry, so the list only
    # contains unique items. can't just use a Set because order matters --
    # later entries should override earlier ones.
    registered_translations[locale].delete(path_or_hash)
    registered_translations[locale] << path_or_hash
  end

  def load_locale(locale)
    locale = locale.to_s
    @load_locale_mutex.synchronize do
      if (paths_and_hashes = registered_translations.delete(locale))
        log "lazy-loading locale: #{locale} (#{paths_and_hashes.size} files)"
        paths_and_hashes.each do |path_or_hash|
          if path_or_hash.is_a?(Hash)
            store_translations(locale, path_or_hash)
          else
            load_file(path_or_hash)
          end
        end
      end
    end
  end
end

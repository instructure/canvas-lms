# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

# SimplyVersioned 0.9.3
#
# Simple ActiveRecord versioning
# Copyright (c) 2007,2008 Matt Mower <self@mattmower.com>
# Released under the MIT license (see accompany MIT-LICENSE file)
#

require "simply_versioned/gem_version"
require "simply_versioned/version"

module SimplyVersioned
  class BadOptions < StandardError
    def initialize(keys)
      super("Keys: #{keys.join(",")} are not known by SimplyVersioned")
    end
  end

  DEFAULTS = {
    keep: nil,
    automatic: true,
    exclude: [],
    explicit: false,
    # callbacks
    when: nil,
    on_create: nil,
    on_update: nil,
    on_load: nil
  }.freeze

  module ClassMethods
    # Marks this ActiveRecord model as being versioned. Calls to +create+ or +save+ will,
    # in future, create a series of associated Version instances that can be accessed via
    # the +versions+ association.
    #
    # Options:
    # +keep+ - specifies the number of old versions to keep (default = nil, never delete old versions)
    # +automatic+ - controls whether versions are created automatically (default = true, save versions)
    # +exclude+ - specify columns that will not be saved (default = [], save all columns)
    #
    # Additional INSTRUCTURE options:
    # +explicit+ - explicit versioning keeps the last version up to date,
    #              but doesn't automatically create new versions (default = false)
    # +when+ - callback to indicate whether an instance needs a version
    #          saved or not. if present, the model is passed to the
    #          callback which should return true or false, true indicating
    #          a version should be saved. if absent, versions are saved if
    #          any attribute other than updated_at is changed.
    # +on_create+ - callback to allow additional changes to a new version
    #               that's about to be saved.
    # +on_update+ - callback to allow additional changes to an updated (see
    #               +explicit+ parameter) version that's about to be saved.
    # +on_load+   - callback to allow processing or changes after loading
    #               (finding) the version from the database.
    #
    # To save the record without creating a version either set +versioning_enabled+ to false
    # on the model before calling save or, alternatively, use +without_versioning+ and save
    # the model from its block.
    #

    def simply_versioned(options = {})
      bad_keys = options.keys - SimplyVersioned::DEFAULTS.keys
      raise SimplyVersioned::BadOptions, bad_keys unless bad_keys.empty?

      options.reverse_merge!(DEFAULTS)
      options[:exclude] = Array(options[:exclude]).map(&:to_s)

      has_many :versions,
               -> { order("number DESC") },
               class_name: "SimplyVersioned::Version",
               as: :versionable,
               dependent: :destroy,
               inverse_of: :versionable,
               extend: VersionsProxyMethods
      # INSTRUCTURE: Added to allow quick access to the most recent version
      # See 'current_version' below for the common use of current_version_unidirectional
      has_one :current_version_unidirectional,
              -> { order("number DESC") },
              class_name: "SimplyVersioned::Version",
              as: :versionable
      # INSTRUCTURE: Lets us ignore certain things when deciding whether to store a new version
      before_save :check_if_changes_are_worth_versioning
      after_save :simply_versioned_create_version

      cattr_accessor :simply_versioned_options
      self.simply_versioned_options = options

      class_eval do
        def versioning_enabled=(enabled)
          instance_variable_set(:@simply_versioned_enabled, enabled)
        end

        def versioning_enabled?
          enabled = instance_variable_get(:@simply_versioned_enabled)
          if enabled.nil?
            enabled = instance_variable_set(:@simply_versioned_enabled, simply_versioned_options[:automatic])
          end
          enabled
        end
      end
    end
  end

  # Methods that will be defined on the ActiveRecord model being versioned
  module InstanceMethods
    # Revert the attributes of this model to their values as of an earlier version.
    #
    # Pass either a Version instance or a version number.
    #
    # options:
    # +except+ specify a list of attributes that are not restored (default: created_at, updated_at)
    #
    def revert_to_version(version, options = {})
      options.reverse_merge!({
                               except: [:created_at, :updated_at]
                             })

      version = case version
                when Version
                  version
                when Integer
                  versions.where(number: version).first
                end

      raise "Invalid version (#{version.inspect}) specified!" unless version

      options[:except] = options[:except].map(&:to_s)

      update(YAML.load(version.yaml).except(*options[:except]))
    end

    # Invoke the supplied block passing the receiver as the sole block argument with
    # versioning enabled or disabled depending upon the value of the +enabled+ parameter
    # for the duration of the block.
    def with_versioning(enabled = true)
      versioning_was_enabled = versioning_enabled?
      explicit_versioning_was_enabled = @simply_versioned_explicit_enabled
      explicit_enabled = false
      if enabled.is_a?(Hash)
        opts = enabled
        enabled = true
        explicit_enabled = true if opts[:explicit]
      end
      self.versioning_enabled = enabled
      @simply_versioned_explicit_enabled = explicit_enabled
      # INSTRUCTURE: always create a version if explicitly told to do so
      @versioning_explicitly_enabled = enabled == true
      begin
        yield self
      ensure
        @versioning_explicitly_enabled = nil
        self.versioning_enabled = versioning_was_enabled
        @simply_versioned_explicit_enabled = explicit_versioning_was_enabled
      end
    end

    def without_versioning(&)
      with_versioning(false, &)
    end

    def unversioned?
      versions.nil? || !versions.exists?
    end

    def versioned?
      !unversioned?
    end

    # INSTRUCTURE: Added to allow model instances pulled out
    # of versions to still know their version number
    def force_version_number(number)
      @simply_versioned_version_number = number
    end
    attr_accessor :simply_versioned_version_model

    def version_number
      if @simply_versioned_version_number
        @simply_versioned_version_number
      elsif @preloaded_current_version_number
        @preloaded_current_version_number
      else
        versions.maximum(:number) || 0
      end
    end

    def current_version?
      !@simply_versioned_version_number
    end

    # Create a bi-directional current_version association so we don't need
    # to reload the 'versionable' object each time we access the model
    def current_version
      current_version_unidirectional.tap do |version|
        version.versionable = self
      end
    end

    protected

    # INSTRUCTURE: If defined on a method, allow a check
    # on the before_save to see if the changes are worth
    # creating a new version for
    def check_if_changes_are_worth_versioning
      @changes_are_worth_versioning = if simply_versioned_options[:when]
                                        simply_versioned_options[:when].call(self)
                                      else
                                        (changes.keys.map(&:to_s) - simply_versioned_options[:exclude] - ["updated_at"]).present?
                                      end
      true
    end

    def simply_versioned_create_version
      # INSTRUCTURE
      if versioning_enabled? && (@versioning_explicitly_enabled || @changes_are_worth_versioning)
        @changes_are_worth_versioning = nil
        if simply_versioned_options[:explicit] && !@simply_versioned_explicit_enabled && versioned?
          version = versions.current
          version.yaml = attributes.except(*simply_versioned_options[:exclude]).to_yaml
          if version.save
            simply_versioned_options[:on_update].try(:call, self, version)
          end
        else
          version = versions.create(yaml: attributes.except(*simply_versioned_options[:exclude]).to_yaml)
          if version.valid?
            simply_versioned_options[:on_create].try(:call, self, version)
            versions.clean_old_versions(simply_versioned_options[:keep].to_i) if simply_versioned_options[:keep]
          end
        end
      end
      true
    end
  end

  module VersionsProxyMethods
    # Anything that returns a Version should have its versionable pre-
    # populated. This is basically a way of getting around the fact that
    # ActiveRecord doesn't have a polymorphic :inverse_of option.
    def method_missing(method, *a, &)
      case method
      when :minimum, :maximum, :exists?, :all, :find_all, :each
        populate_versionables(super)
      when :find
        case a.first
        when :all          then populate_versionables(super)
        when :first, :last then populate_versionable(super)
        else super
        end
      else
        super
      end
    end

    def populate_versionables(versions)
      versions.each { |v| populate_versionable(v) } if versions.is_a?(Array)
      versions
    end

    def populate_versionable(version)
      if version && !version.frozen?
        version.versionable = proxy_association.owner
      end
      version
    end

    # Get the Version instance corresponding to this models for the specified version number.
    def get_version(number)
      populate_versionable where(number:).first
    end
    alias_method :get, :get_version

    # Get the first Version corresponding to this model.
    def first_version
      populate_versionable reorder("number ASC").limit(1).to_a.first
    end
    alias_method :first, :first_version

    # Get the current Version corresponding to this model.
    def current_version
      populate_versionable reorder("number DESC").limit(1).to_a.first
    end
    alias_method :current, :current_version

    # If the model instance has more versions than the limit specified, delete all excess older versions.
    def clean_old_versions(versions_to_keep)
      where("number <= ?", maximum(:number) - versions_to_keep).each(&:destroy)
    end
    alias_method :purge, :clean_old_versions

    # Return the Version for this model with the next higher version
    def next_version(number)
      populate_versionable reorder("number ASC").where("number > ?", number).limit(1).to_a.first
    end
    alias_method :next, :next_version

    # Return the Version for this model with the next lower version
    def previous_version(number = nil)
      versions = reorder("number DESC")
      versions = versions.where("number <= ?", number) if number
      versions = versions.limit(2).to_a
      populate_versionable versions.last if versions.length == 2
    end
    alias_method :previous, :previous_version
  end

  def self.included(receiver)
    receiver.extend ClassMethods
    receiver.include InstanceMethods
  end
end

ActiveRecord::Base.include SimplyVersioned

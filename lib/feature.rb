# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
#

class Feature
  ATTRS = %i[feature
             display_name
             description
             applies_to
             state
             root_opt_in
             beta
             type
             shadow
             release_notes_url
             custom_transition_proc
             visible_on
             after_state_change_proc
             autoexpand
             touch_context].freeze
  attr_reader(*ATTRS)

  def initialize(opts = {})
    @state = "allowed"
    opts.each do |key, val|
      next unless ATTRS.include?(key)
      next if key == :state && !%w[hidden off allowed on allowed_on].include?(val)

      instance_variable_set :"@#{key}", val
    end
    # for RootAccount features, "allowed" state is redundant; show "off" instead
    @root_opt_in = true if @applies_to == "RootAccount"
  end

  def clone_for_cache
    Feature.new(feature: @feature, state: @state)
  end

  def default?
    true
  end

  def locked?(query_context)
    query_context.blank? || (!can_override? && !hidden?)
  end

  def enabled?
    @state == STATE_ON || @state == STATE_DEFAULT_ON
  end

  def can_override?
    @state == STATE_DEFAULT_OFF || @state == STATE_DEFAULT_ON
  end

  def hidden?
    @state == "hidden"
  end

  def shadow?
    @shadow || false
  end

  def self.environment
    if Rails.env.development?
      :development
    elsif Rails.env.test?
      :ci
    elsif ApplicationController.test_cluster_name == "beta"
      :beta
    elsif ApplicationController.test_cluster_name == "test"
      :test
    else
      :production
    end
  end

  def self.production_environment?
    environment == :production
  end

  # Register one or more features.  Must be done during application initialization.
  # NOTE: there is refactoring going on for feature flags: ADMIN-2538
  #       if you need to add/modify/delete a FF, they have been moved to ./lib/feature_flags/*yml
  # The feature_hash is as follows:
  #   automatic_essay_grading: {
  #     display_name: -> { I18n.t('features.automatic_essay_grading', 'Automatic Essay Grading') },
  #     description: -> { I18n.t('features.automatic_essay_grading_description, 'Popup text describing the feature goes here') },
  #     applies_to: 'Course',     # or 'RootAccount' or 'Account' or 'User'
  #     state: 'allowed',         # or 'on', 'hidden', or 'disabled'
  #                               # - 'hidden' means the feature must be set by a site admin before it will be visible
  #                               #   (in that context and below) to other users
  #                               # - 'disabled' means the feature will not appear in the feature list and
  #                               #   cannot be turned on. It is intended for use in environment state overrides.
  #     root_opt_in: false,       # if true, 'allowed' features in source or site admin
  #                               # will be inherited in "off" state by root accounts
  #     beta: false,              # 'beta' tag shown in UI
  #     release_notes_url: 'http://example.com/',
  #
  #     # allow overriding feature definitions on a per-environment basis
  #     # valid environments are development, production, beta, test, ci
  #     environments: {
  #       production: {
  #         state: 'disabled'
  #       }
  #     }
  #
  #     # optional: you can supply a Proc to attach warning messages to and/or forbid certain transitions
  #     # see lib/feature/draft_state.rb for example usage
  #     custom_transition_proc: ->(user, context, from_state, transitions) do
  #       if from_state == 'off' && context.is_a?(Course) && context.has_submitted_essays?
  #         transitions['on']['warning'] = I18n.t('features.automatic_essay_grading.enable_warning',
  #           'Enabling this feature after some students have submitted essays may yield inconsistent grades.')
  #       end
  #     end,
  #
  #     # optional hook to be called before after a feature flag change
  #     # queue a delayed_job to perform any nontrivial processing
  #     after_state_change_proc:  ->(user, context, old_state, new_state) { ... }
  #   }
  STATE_OFF = "off"
  STATE_ON = "on"
  STATE_DEFAULT_OFF = "allowed"
  STATE_DEFAULT_ON = "allowed_on"
  STATE_HIDDEN = "hidden"
  STATE_DISABLED = "disabled"

  VALID_STATES = [STATE_ON, STATE_DEFAULT_OFF, STATE_DEFAULT_ON, STATE_HIDDEN, STATE_DISABLED].freeze
  VALID_APPLIES_TO = %w[Course Account RootAccount User SiteAdmin].freeze
  VALID_ENVS = %i[development ci beta test production].freeze
  VALID_TYPES = %w[feature_option setting].freeze

  DISABLED_FEATURE = Feature.new.freeze

  def self.register(feature_hash)
    @features ||= {}
    feature_hash.each do |feature_name, attrs|
      apply_environment_overrides!(feature_name, attrs)
      feature = feature_name.to_s
      validate_attrs(attrs, feature)
      @features[feature] = if attrs[:state] == STATE_DISABLED
                             DISABLED_FEATURE
                           else
                             Feature.new({ feature: }.merge(attrs))
                           end
    end
  end

  def self.validate_attrs(attrs, feature)
    raise "state is required for feature #{feature}" unless attrs[:state]
    raise "applies_to is required for feature #{feature}" unless attrs[:applies_to]
    raise "invalid 'state' for feature #{feature}: must be one of #{VALID_STATES}, is #{attrs[:state]}" unless VALID_STATES.include? attrs[:state]
    raise "invalid 'applies_to' for feature #{feature}: must  be one of #{VALID_APPLIES_TO}, is #{attrs[:applies_to]}" unless VALID_APPLIES_TO.include? attrs[:applies_to]
    raise "invalid 'type' for feature #{feature}: must  be one of #{VALID_TYPES}, is #{attrs[:type]}" unless VALID_TYPES.include? attrs[:type]
  end

  def self.definitions
    @features ||= {}
    @features.freeze unless @features.frozen?
    @features
  end

  def self.apply_environment_overrides!(feature_name, feature_hash)
    environments = feature_hash.delete(:environments)
    if environments
      raise "invalid environment tag for feature #{feature_name}: must be one of #{VALID_ENVS}" unless (environments.keys - VALID_ENVS).empty?

      env = environment
      if environments.key?(env)
        feature_hash.merge!(environments[env])
      end
    end
  end

  def applies_to_object(object)
    case @applies_to
    when "SiteAdmin"
      object.is_a?(Account) && object.site_admin?
    when "RootAccount"
      object.is_a?(Account) && object.root_account?
    when "Account"
      object.is_a?(Account)
    when "Course"
      object.is_a?(Course) || object.is_a?(Account)
    when "User"
      object.is_a?(User) || (object.is_a?(Account) && object.site_admin?)
    else
      false
    end
  end

  def self.exists?(feature)
    definitions.key?(feature.to_s)
  end

  def self.feature_applies_to_object(feature, object)
    feature_def = definitions[feature.to_s]
    return false unless feature_def

    feature_def.applies_to_object(object)
  end

  def self.applicable_features(object, type: nil)
    applicable_types = []
    case object
    when Account
      applicable_types << "Account"
      applicable_types << "Course"
      applicable_types << "RootAccount" if object.root_account?
      applicable_types << "User" if object.site_admin?
      applicable_types << "SiteAdmin" if object.site_admin?
    when Course
      applicable_types << "Course"
    when User
      applicable_types << "User"
    end
    definitions.values.select { |fd| applicable_types.include?(fd.applies_to) && (type.nil? || fd.type == type) }
  end

  def default_transitions(context, orig_state)
    valid_states = [STATE_OFF, STATE_ON]
    valid_states += [STATE_DEFAULT_OFF, STATE_DEFAULT_ON] if context.is_a?(Account)
    (valid_states - [orig_state]).index_with do |state|
      { "locked" => [STATE_DEFAULT_OFF, STATE_DEFAULT_ON].include?(state) && ((@applies_to == "RootAccount" &&
        context.is_a?(Account) && context.root_account? && !context.site_admin?) || @applies_to == "SiteAdmin") }
    end
  end

  def transitions(user, context, orig_state)
    h = default_transitions(context, orig_state)
    if @custom_transition_proc.is_a?(Proc)
      @custom_transition_proc.call(user, context, orig_state, h)
    end
    h
  end

  def self.transitions(feature_name, user, context, orig_state)
    fd = definitions[feature_name.to_s]
    return nil unless fd

    fd.transitions(user, context, orig_state)
  end

  def self.remove_obsolete_flags
    valid_features = definitions.keys
    cutoff = 60.days.ago
    delete_scope = FeatureFlag.where("updated_at<?", cutoff).where.not(feature: valid_features)
    delete_scope.in_batches.delete_all
  end
end

FeatureFlags::Loader.load_feature_flags

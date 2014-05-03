#
# Copyright (C) 2013 Instructure, Inc.
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
  ATTRS = [:feature, :display_name, :description, :applies_to, :state, :root_opt_in, :enable_at, :beta, :development, :release_notes_url, :custom_transition_proc, :after_state_change_proc]
  attr_reader *ATTRS

  def initialize(opts = {})
    @state = 'allowed'
    opts.each do |key, val|
      next unless ATTRS.include?(key)
      next if key == :state && !%w(hidden off allowed on).include?(val)
      instance_variable_set "@#{key}", val
    end
  end

  def default?
    true
  end

  def locked?(query_context, current_user = nil)
    query_context.blank? || !allowed? && !hidden?
  end

  def enabled?
    @state == 'on'
  end

  def allowed?
    @state == 'allowed'
  end

  def hidden?
    @state == 'hidden'
  end

  # Register one or more features.  Must be done during application initialization.
  # The feature_hash is as follows:
=begin
  automatic_essay_grading: {
    display_name: lambda { I18n.t('features.automatic_essay_grading', 'Automatic Essay Grading') },
    description: lambda { I18n.t('features.automatic_essay_grading_description, 'Popup text describing the feature goes here') },
    applies_to: 'Course', # or 'RootAccount' or 'Account' or 'User'
    state: 'allowed',     # or 'off' or 'on' or 'hidden'
    root_opt_in: false,   # if true, 'allowed' features in source or site admin
                          # will be inherited in "off" state by root accounts
    enable_at: Date.new(2014, 1, 1),  # estimated release date shown in UI
    beta: false,          # 'beta' tag shown in UI
    development: false,   # 'development' tag shown in UI
    release_notes_url: 'http://example.com/',

    # optional: you can supply a Proc to attach warning messages to and/or forbid certain transitions
    # see lib/feature/draft_state.rb for example usage
    custom_transition_proc: ->(user, context, from_state, transitions) do
      if from_state == 'off' && context.is_a?(Course) && context.has_submitted_essays?
        transitions['on']['warning'] = I18n.t('features.automatic_essay_grading.enable_warning',
          'Enabling this feature after some students have submitted essays may yield inconsistent grades.')
      end
    end,

    # optional hook to be called before after a feature flag change
    # queue a delayed_job to perform any nontrivial processing
    after_state_change_proc:  ->(context, old_state, new_state) { ... }
  }
=end

  def self.register(feature_hash)
    @features ||= {}
    feature_hash.each do |k, v|
      feature = k.to_s
      @features[feature] = Feature.new({feature: feature}.merge(v))
    end
  end

  # TODO: register built-in features here
  # (plugins may register additional features during application initialization)
  register(
    'google_docs_domain_restriction' =>
    {
      display_name: -> { I18n.t('features.google_docs_domain_restriction', 'Google Docs Domain Restriction') },
      description: -> { I18n.t('google_docs_domain_restriction_description', <<END) },
Google Docs Domain Restriction allows Google Docs submissions and collaborations
to be restricted to a single domain. Students attempting to submit assignments or
join collaborations on an unapproved domain will receive an error message notifying them
that they will need to update their Google Docs integration.
END
      applies_to: 'RootAccount',
      state: 'hidden',
      root_opt_in: true
    },
    'outcome_gradebook' =>
    {
      display_name: -> { I18n.t('features.outcome_gradebook', 'Outcome Gradebook') },
      description:  -> { I18n.t('outcome_gradebook_description', <<-END) },
Outcome Gradebook provides a way for teachers to quickly view student and course
progress on course learning outcomes. Outcomes are presented in a Gradebook-like
format and student progress is displayed both as a numerical score and as mastered/near
mastery/remedial.
END
      applies_to: 'Course',
      state: 'allowed',
      root_opt_in: false,
      development: false
    },
    'student_outcome_gradebook' =>
    {
      display_name: -> { I18n.t('features.student_outcome_gradebook', 'Student Outcome Gradebook') },
      description:  -> { I18n.t('student_outcome_gradebook_description', <<-END) },
Student Outcome Gradebook provides a way for students to quickly view progress
on course learning outcomes. Outcomes are presented in a Gradebook-like
format and progress is displayed both as a numerical score and as mastered/near
mastery/remedial.
END
      applies_to: 'Course',
      state: 'hidden',
      root_opt_in: true,
      development: true
    },
    'screenreader_gradebook' =>
    {
      display_name: -> { I18n.t('features.screenreader_gradebook', 'Screenreader Gradebook') },
      description:  -> { I18n.t('screenreader_gradebook_description', <<-END) },
Screenreader Gradebook provides an interface to gradebook that is designed for accessibility.
END
      applies_to: 'Course',
      state: 'hidden',
      root_opt_in: true,
      development: true
    },
    'differentiated_assignments' =>
    {
      display_name: -> { I18n.t('features.differentiated_assignments', 'Differentiated Assignments') },
      description:  -> { I18n.t('differentiated_assignments_description', <<-END) },
Differentiated Assignments is a *beta* feature that enables choosing which section(s) an assignment applies to.
Sections that are not given an assignment will not see it in their course content and their final grade will be
calculated without those points.
END
      applies_to: 'Course',
      state: 'hidden',
      root_opt_in: true,
      development: true
    }
  )

  def self.definitions
    @features ||= {}
    @features.freeze unless @features.frozen?
    @features
  end

  def applies_to_object(object)
    case @applies_to
      when 'RootAccount'
        object.is_a?(Account) && object.root_account?
      when 'Account'
        object.is_a?(Account)
      when 'Course'
        object.is_a?(Course) || object.is_a?(Account)
      when 'User'
        object.is_a?(User) || object.is_a?(Account) && object.site_admin?
      else
        false
    end
  end

  def self.feature_applies_to_object(feature, object)
    feature_def = definitions[feature.to_s]
    return false unless feature_def
    feature_def.applies_to_object(object)
  end

  def self.applicable_features(object)
    applicable_types = []
    if object.is_a?(Account)
      applicable_types << 'Account'
      applicable_types << 'Course'
      applicable_types << 'RootAccount' if object.root_account?
      applicable_types << 'User' if object.site_admin?
    elsif object.is_a?(Course)
      applicable_types << 'Course'
    elsif object.is_a?(User)
      applicable_types << 'User'
    end
    definitions.values.select{ |fd| applicable_types.include?(fd.applies_to) }
  end

  def self.default_transitions(context, orig_state)
    valid_states = %w(off on)
    valid_states << 'allowed' if context.is_a?(Account)
    (valid_states - [orig_state]).inject({}) do |transitions, state|
      transitions[state] = { 'locked' => false }
      transitions
    end
  end

  def self.transitions(feature, user, context, orig_state)
    h = Feature.default_transitions(context, orig_state)
    fd = definitions[feature.to_s]
    if fd.custom_transition_proc.is_a?(Proc)
      fd.custom_transition_proc.call(user, context, orig_state, h)
    end
    h
  end
end

# load feature definitions
Dir.glob("#{Rails.root}/lib/features/*.rb").each { |file| require file }


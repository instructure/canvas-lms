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
    # for RootAccount features, "allowed" state is redundant; show "off" instead
    @root_opt_in = true if @applies_to == 'RootAccount'
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
    'new_styles' =>
    {
      display_name: -> { I18n.t('features.new_styles', 'Use New Styles') },
      description: -> { I18n.t('new_styles_description', <<-END) },
We are working on a UI facelift to Canvas. Turn this on to opt-in to seeing the
updated, simplified look and feel of the Canvas interface.
END
      applies_to: 'RootAccount',
      state: 'allowed',
      beta: true,
      development: true
    },
    'html5_first_videos' =>
    {
      display_name: -> { I18n.t('features.html5_first_videos', 'Prefer HTML5 for video playback') },
      description: -> { I18n.t('html5_first_videos_description', <<-END) },
By default, Canvas will try to use Flash first to play videos. Turn this on to try using HTML5 first,
then fall back to Flash.
END
      applies_to: 'RootAccount',
      state: 'allowed',
      beta: true,
      development: true
    },
    'high_contrast' =>
    {
      display_name: -> { I18n.t('features.high_contrast', 'Use High Contrast Styles') },
      description: -> { I18n.t('high_contrast_description', <<-END) },
If you would prefer a higher-contrast version of the Canvas user interface, enable this.
This might be useful for people with impaired vision or dificulty reading.
END
      applies_to: 'User',
      state: 'allowed',
      beta: true,
      development: true
    },
    'outcome_gradebook' =>
    {
      display_name: -> { I18n.t('features.learning_mastery_gradebook', 'Learning Mastery Gradebook') },
      description:  -> { I18n.t('learning_mastery_gradebook_description', <<-END) },
Learning Mastery Gradebook provides a way for teachers to quickly view student and course
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
      display_name: -> { I18n.t('features.student_outcome_gradebook', 'Student Learning Mastery Gradebook') },
      description:  -> { I18n.t('student_outcome_gradebook_description', <<-END) },
Student Learning Mastery Gradebook provides a way for students to quickly view progress
on course learning outcomes. Outcomes are presented in a Gradebook-like
format and progress is displayed both as a numerical score and as mastered/near
mastery/remedial.
END
      applies_to: 'Course',
      state: 'allowed',
      root_opt_in: false,
      development: false
    },
  'post_grades' =>
      {
          display_name: -> { I18n.t('features.post_grades', 'Post Grades to SIS') },
          description:  -> { I18n.t('post_grades_description', <<-END) },
Post Grades allows teachers to post grades back to enabled SIS systems: Powerschool,
Aspire (SIS2000), JMC, and any other SIF-enabled SIS that accepts the SIF elements GradingCategory,
 GradingAssignment, GradingAssignmentScore.
          END
          applies_to: 'Course',
          state: 'hidden',
          root_opt_in: true,
          development: true
      },
    'screenreader_gradebook' =>
    {
      display_name: -> { I18n.t('features.individual_gradebook', 'Individual Gradebook View') },
      description:  -> { I18n.t('individual_gradebook_description', <<-END) },
Individual Gradebook View provides a gradebook view that is designed for accessibility.
END
      applies_to: 'Course',
      state: 'on',
      root_opt_in: true,
      development: false
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
    },
    'quiz_stats' =>
    {
      display_name: -> { I18n.t('features.new_quiz_statistics', 'New Quiz Statistics Page') },
      description: -> { I18n.t('new_quiz_statistics_desc', <<-END) },
When Draft State is allowed/on, this enables the new quiz statistics page for an account.
END
      applies_to: 'Course',
      state: 'hidden',
      development: true
    },
    'quiz_moderate' =>
    {
      display_name: -> { I18n.t('features.new_quiz_moderate', 'New Quiz Moderate Page') },
      description: -> { I18n.t('new_quiz_moderate_desc', <<-END) },
When Draft State and Quiz Statistics is allowed/on, this enables the new quiz moderate page for an account.
END
      applies_to: 'Course',
      state: 'hidden',
      development: true
    },
    'student_groups_next' =>
    {
      display_name: -> { I18n.t('features.student_groups', 'New Student Groups Page') },
      description:  -> { I18n.t('student_groups_desc', <<-END) },
This enables the new student group page for an account. The new page was build to provide a more dynamic group signup
experience.
END
      applies_to: 'RootAccount',
      state: 'allowed',
      root_opt_in: true,
      development: true
    },
    'better_file_browsing' =>
    {
      display_name: -> { I18n.t('features.better_file_browsing', 'Better File Browsing') },
      description:  -> { I18n.t('better_file_browsing_description', <<-END) },
A new, simpler, more user friendly file browsing interface.  If you turn this on at the course level,
then all of the users in that course will see the new interface.  To get it to show up when someone
goes to the personal files page for a user ('/files') then you need to turn it on for the account they are a memeber of.
END

      applies_to: 'Course',
      state: 'hidden',
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

  def default_transitions(context, orig_state)
    valid_states = %w(off on)
    valid_states << 'allowed' if context.is_a?(Account)
    (valid_states - [orig_state]).inject({}) do |transitions, state|
      transitions[state] = { 'locked' => (state == 'allowed' && @applies_to == 'RootAccount' &&
          context.is_a?(Account) && context.root_account? && !context.site_admin?) }
      transitions
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
end

# load feature definitions
Dir.glob("#{Rails.root}/lib/features/*.rb").each { |file| require file }


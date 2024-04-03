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
#

require "canvas/draft_state_validations"

class AbstractAssignment < ActiveRecord::Base
  self.table_name = "assignments"

  self.ignored_columns += ["group_category"]

  include Workflow
  include TextHelper
  include HasContentTags
  include CopyAuthorizedLinks
  include Mutable
  include ContextModuleItem
  include DatesOverridable
  include SearchTermHelper
  include Canvas::DraftStateValidations
  include TurnitinID
  include Plannable
  include DuplicatingObjects
  include LockedFor
  include Lti::Migratable

  GRADING_TYPES = OpenStruct.new(
    {
      points: "points",
      percent: "percent",
      letter_grade: "letter_grade",
      gpa_scale: "gpa_scale",
      pass_fail: "pass_fail",
      not_graded: "not_graded"
    }
  )

  ALLOWED_GRADING_TYPES = GRADING_TYPES.to_h.values.freeze
  POINTED_GRADING_TYPES = [
    GRADING_TYPES.points,
    GRADING_TYPES.percent,
    GRADING_TYPES.letter_grade,
    GRADING_TYPES.gpa_scale
  ].freeze

  OFFLINE_SUBMISSION_TYPES = %i[on_paper external_tool none not_graded wiki_page].freeze
  SUBMITTABLE_TYPES = %w[online_quiz discussion_topic wiki_page].freeze
  LTI_EULA_SERVICE = "vnd.Canvas.Eula"
  AUDITABLE_ATTRIBUTES = %w[
    muted
    due_at
    points_possible
    anonymous_grading
    moderated_grading
    final_grader_id
    grader_count
    omit_from_final_grade
    hide_in_gradebook
    grader_names_visible_to_final_grader
    grader_comments_visible_to_graders
    graders_anonymous_to_graders
    anonymous_instructor_annotations
  ].freeze

  DEFAULT_POINTS_POSSIBLE = 0

  DUPLICATED_IN_CONTEXT = "duplicated_in_context"
  QUIZ_SUBMISSION_VERSIONS_LIMIT = 65
  QUIZZES_NEXT_TIMEOUT = 15.minutes

  attr_accessor(
    :resource_map,
    :copying,
    :grade_posting_in_progress,
    :needs_update_cached_due_dates,
    :previous_id,
    :saved_by,
    :skip_schedule_peer_reviews,
    :unposted_anonymous_submissions,
    :updated_submissions, # for testing
    :user_submitted
  )

  attr_reader :assignment_changed, :posting_params_for_notifications
  attr_writer :updating_user

  include MasterCourses::Restrictor
  restrict_columns :content, [:title, :description]
  restrict_assignment_columns
  restrict_columns :state, [:workflow_state]

  attribute :lti_resource_link_custom_params, :string, default: nil
  # Serializing this as JSON vs a Hash allows us to distinguish between nil (no changes need to be made)
  # and an actual Hash to set custom params to, which could be an empty hash.
  serialize :lti_resource_link_custom_params, coder: JSON
  attribute :lti_resource_link_lookup_uuid, :string, default: nil
  attribute :lti_resource_link_url, :string, default: nil
  attribute :line_item_resource_id, :string, default: nil
  attribute :line_item_tag, :string, default: nil

  has_many :submissions, -> { active.preload(:grading_period) }, inverse_of: :assignment, foreign_key: :assignment_id
  has_many :all_submissions, class_name: "Submission", dependent: :delete_all, inverse_of: :assignment, foreign_key: :assignment_id
  has_many :observer_alerts, through: :all_submissions
  has_many :provisional_grades, through: :submissions
  belongs_to :annotatable_attachment, class_name: "Attachment"
  has_many :attachments, as: :context, inverse_of: :context, dependent: :destroy
  has_many :assignment_student_visibilities, inverse_of: :assignment, foreign_key: :assignment_id
  has_one :quiz, class_name: "Quizzes::Quiz", inverse_of: :assignment, foreign_key: :assignment_id
  belongs_to :assignment_group
  has_one :discussion_topic, -> { where(root_topic_id: nil).order(:created_at) }, inverse_of: :assignment, foreign_key: :assignment_id
  has_one :wiki_page, inverse_of: :assignment, foreign_key: :assignment_id
  has_many :learning_outcome_alignments, -> { where("content_tags.tag_type='learning_outcome' AND content_tags.workflow_state<>'deleted'").preload(:learning_outcome) }, as: :content, inverse_of: :content, class_name: "ContentTag"
  has_one :rubric_association, -> { where(purpose: "grading").order(:created_at).preload(:rubric) }, as: :association, inverse_of: :association_object
  has_one :rubric, -> { merge(RubricAssociation.active) }, through: :rubric_association
  has_one :teacher_enrollment, -> { preload(:user).where(enrollments: { workflow_state: "active", type: "TeacherEnrollment" }) }, class_name: "TeacherEnrollment", foreign_key: "course_id", primary_key: "context_id"
  has_many :ignores, as: :asset
  has_many :moderated_grading_selections, class_name: "ModeratedGrading::Selection", inverse_of: :assignment, foreign_key: :assignment_id
  belongs_to :context, polymorphic: [:course]
  delegate :moderated_grading_max_grader_count, to: :course
  belongs_to :grading_standard
  belongs_to :group_category
  belongs_to :grader_section, class_name: "CourseSection", optional: true
  belongs_to :final_grader, class_name: "User", optional: true
  has_many :active_groups, -> { merge(GroupCategory.active).merge(Group.active) }, through: :group_category, source: :groups
  has_many :assigned_students, through: :submissions, source: :user
  has_many :enrollments_for_assigned_students, -> { active.not_fake.where("enrollments.course_id = submissions.course_id") }, through: :assigned_students, source: :enrollments
  has_many :sections_for_assigned_students, -> { active.distinct }, through: :enrollments_for_assigned_students, source: :course_section

  belongs_to :duplicate_of, class_name: "Assignment", optional: true, inverse_of: :duplicates
  has_many :duplicates, class_name: "Assignment", inverse_of: :duplicate_of, foreign_key: "duplicate_of_id"

  has_many :assignment_configuration_tool_lookups, dependent: :delete_all, inverse_of: :assignment, foreign_key: :assignment_id
  has_many :tool_settings_context_external_tools, through: :assignment_configuration_tool_lookups, source: :tool, source_type: "ContextExternalTool"
  has_many :line_items, inverse_of: :assignment, class_name: "Lti::LineItem", dependent: :destroy, foreign_key: :assignment_id

  has_one :external_tool_tag, class_name: "ContentTag", as: :context, inverse_of: :context, dependent: :destroy
  has_one :score_statistic, dependent: :destroy, inverse_of: :assignment, foreign_key: :assignment_id
  has_one :post_policy, dependent: :destroy, inverse_of: :assignment, foreign_key: :assignment_id

  has_many :moderation_graders, inverse_of: :assignment, foreign_key: :assignment_id
  has_many :moderation_grader_users, through: :moderation_graders, source: :user

  has_many :auditor_grade_change_records,
           class_name: "Auditors::ActiveRecord::GradeChangeRecord",
           dependent: :destroy,
           inverse_of: :assignment,
           foreign_key: :assignment_id
  has_many :lti_resource_links,
           as: :context,
           inverse_of: :context,
           class_name: "Lti::ResourceLink",
           dependent: :destroy

  has_many :conditional_release_rules, class_name: "ConditionalRelease::Rule", dependent: :destroy, foreign_key: "trigger_assignment_id", inverse_of: :trigger_assignment
  has_many :conditional_release_associations, class_name: "ConditionalRelease::AssignmentSetAssociation", dependent: :destroy, inverse_of: :assignment, foreign_key: :assignment_id
  has_one :master_content_tag, class_name: "MasterCourses::MasterContentTag", inverse_of: :assignment, foreign_key: :content_id

  belongs_to :parent_assignment, class_name: "Assignment", inverse_of: :sub_assignments
  has_many :sub_assignments, -> { active }, foreign_key: :parent_assignment_id, inverse_of: :parent_assignment
  has_many :sub_assignment_submissions, through: :sub_assignments, source: :submissions

  scope :assigned_to_student, ->(student_id) { joins(:submissions).where(submissions: { user_id: student_id }) }
  scope :anonymous, -> { where(anonymous_grading: true) }
  scope :moderated, -> { where(moderated_grading: true) }
  scope :auditable, -> { anonymous.or(moderated) }
  scope :type_quiz_lti, lambda {
    all.primary_shard.activate do
      # the offsets in this query are important hints to the PG query planner to execute this efficiently
      where(ContentTag.where("content_tags.context_id=assignments.id")
                      .where(context_type: "Assignment", content_type: "ContextExternalTool")
                      .where(ContextExternalTool.where("context_external_tools.id=content_tags.content_id").quiz_lti.offset(0).arel.exists)
                      .offset(0).arel.exists)
    end
  }
  scope :not_type_quiz_lti, -> { where.not(id: type_quiz_lti) }

  scope :exclude_muted_associations_for_user, lambda { |user|
    joins("LEFT JOIN #{Submission.quoted_table_name} ON submissions.user_id = #{User.connection.quote(user.id_for_database)} AND submissions.assignment_id = assignments.id")
      .joins("LEFT JOIN #{PostPolicy.quoted_table_name} pc on pc.assignment_id  = assignments.id")
      .where(<<~SQL.squish)
        assignments.id IS NULL
             OR submissions.posted_at IS NOT NULL
             OR assignments.grading_type = 'not_graded'
             OR pc.id IS NULL
             OR (pc.id IS NOT NULL AND pc.post_manually = False)
      SQL
  }
  scope :nondeleted, -> { where.not(workflow_state: "deleted") }

  validates_associated :external_tool_tag, if: :external_tool?
  validate :group_category_changes_ok?
  validate :turnitin_changes_ok?
  validate :vericite_changes_ok?
  validate :anonymous_grading_changes_ok?
  validate :no_anonymous_group_assignments
  validate :due_date_ok?, unless: :active_assignment_overrides?
  validate :assignment_overrides_due_date_ok?
  validate :discussion_group_ok?
  validate :positive_points_possible?
  validate :reasonable_points_possible?
  validate :moderation_setting_ok?
  validate :assignment_name_length_ok?, unless: :deleted?
  validate :annotatable_and_group_exclusivity_ok?
  validate :allowed_extensions_length_ok?
  validates :lti_context_id, presence: true, uniqueness: true
  validates :grader_count, numericality: true
  validates :allowed_attempts, numericality: { greater_than: 0 }, unless: proc { |a| a.allowed_attempts == -1 }, allow_nil: true
  validates :sis_source_id, uniqueness: { scope: :root_account_id }, allow_nil: true

  with_options unless: :moderated_grading? do
    validates :graders_anonymous_to_graders, absence: true
    validates :grader_section, absence: true
    validates :final_grader, absence: true
  end

  with_options if: -> { moderated_grading? } do
    validates :grader_count, numericality: { greater_than: 0 }
    validate :grader_section_ok?
    validate :final_grader_ok?
  end

  accepts_nested_attributes_for :external_tool_tag, update_only: true, reject_if: proc { |attrs|
    # only accept the url, link_settings, content_type, content_id and new_tab params
    # the other accessible params don't apply to an content tag being used as an external_tool_tag
    content = case attrs["content_type"]
              when "Lti::MessageHandler", "lti/message_handler"
                Lti::MessageHandler.find(attrs["content_id"].to_i)
              when "ContextExternalTool", "context_external_tool"
                ContextExternalTool.find(attrs["content_id"].to_i)
              end
    attrs[:content] = content if content
    attrs[:external_data] = JSON.parse(attrs[:external_data]) if attrs["external_data"].present? && attrs[:external_data].is_a?(String)
    attrs.slice!(:url, :new_tab, :content, :external_data, :link_settings)
    false
  }
  before_validation do |assignment|
    assignment.points_possible = nil unless assignment.graded?
    clear_moderated_grading_attributes(assignment) unless assignment.moderated_grading?
    assignment.lti_context_id ||= SecureRandom.uuid
    if assignment.external_tool? && assignment.external_tool_tag
      assignment.external_tool_tag.context = assignment
      assignment.external_tool_tag.content_type ||= "ContextExternalTool"
    else
      assignment.association(:external_tool_tag).reset
    end
    assignment.infer_grading_type
    true
  end

  # included to make it easier to work with api, which returns
  # sis_source_id as sis_assignment_id.
  alias_attribute :sis_assignment_id, :sis_source_id

  def checkpoint?
    false
  end

  def context_code
    "#{context_type.downcase}_#{context_id}"
  end

  def positive_points_possible?
    return false if points_possible.to_i >= 0
    return false unless points_possible_changed?

    errors.add(
      :points_possible,
      I18n.t(
        "invalid_points_possible",
        "The value of possible points for this assignment must be zero or greater."
      )
    )
  end

  def reasonable_points_possible?
    return false if points_possible.to_i < 1_000_000_000
    return false unless points_possible_changed?

    errors.add(
      :points_possible,
      I18n.t(
        "The value of possible points for this assignment cannot exceed 999999999."
      )
    )
  end

  def get_potentially_conflicting_titles(title_base)
    assignment_titles = Assignment.active.for_course(context_id)
                                  .starting_with_title(title_base).pluck("title").to_set
    wiki_titles = if wiki_page
                    wiki_page.get_potentially_conflicting_titles(title_base)
                  else
                    [].to_set
                  end
    assignment_titles.union(wiki_titles)
  end

  # The relevant associations that are copied are:
  #
  # learning_outcome_alignments, rubric_association, wiki_page,
  # assignment_configuration_tool_lookups
  #
  # In the case of wiki_page, a new wiki_page will be created.  The underlying
  # rubric association, however, will simply point to the original rubric
  # rather than copying the rubric.
  #
  # Other has_ relations are not duplicated for various reasons.
  # These are:
  #
  # attachments, submissions, provisional_grades, lti stuff, discussion_topic
  # ignores, moderated_grading_selections, teacher_enrollment
  # TODO: Try to get more of that stuff duplicated
  def duplicate(opts = {})
    raise "This assignment can't be duplicated" unless can_duplicate?

    # Don't clone a new record
    return self if new_record?

    default_opts = {
      duplicate_wiki_page: true,
      duplicate_discussion_topic: true,
      duplicate_plagiarism_tool_association: true,
      copy_title: nil,
      user: nil
    }
    opts_with_default = default_opts.merge(opts)

    result = clone
    result.all_submissions.clear
    result.attachments.clear
    result.ignores.clear
    result.moderated_grading_selections.clear
    result.grades_published_at = nil
    %i[discussion_topic
       integration_data
       integration_id
       lti_context_id
       migration_id
       sis_source_id
       turnitin_id].each do |attr|
      result.send(:"#{attr}=", nil)
    end
    result.peer_review_count = 0
    result.peer_reviews_assigned = false

    # Default to the last position of all active assignments in the group.  Clients can still
    # override later.  Just helps to avoid duplicate positions.
    result.position = Assignment.active.where(assignment_group:).maximum(:position) + 1
    result.title =
      opts_with_default[:copy_title] || get_copy_title(self, t("Copy"), title)

    if wiki_page && opts_with_default[:duplicate_wiki_page]
      result.wiki_page = wiki_page.duplicate({
                                               duplicate_assignment: false,
                                               copy_title: result.title
                                             })
    end

    if discussion_topic && opts_with_default[:duplicate_discussion_topic]
      result.discussion_topic = discussion_topic.duplicate({
                                                             duplicate_assignment: false,
                                                             copy_title: result.title,
                                                             user: opts_with_default[:user]
                                                           })
    end

    result.discussion_topic&.assignment = result

    if assignment_configuration_tool_lookups.present? && opts_with_default[:duplicate_plagiarism_tool_association]
      result.assignment_configuration_tool_lookups = [
        assignment_configuration_tool_lookups.first.dup
      ]
    end

    # Learning outcome alignments seem to get copied magically, possibly
    # through the rubric
    if active_rubric_association?
      result.rubric_association = rubric_association.clone
      result.rubric_association.skip_updating_points_possible = true
    end

    # Link the duplicated assignment to this assignment
    result.duplicate_of = self

    # If this assignment uses an external tool, duplicate that too, and mark
    # the assignment as "duplicating"
    if external_tool? && external_tool_tag.present?
      result.external_tool_tag = external_tool_tag.dup
      result.workflow_state = "duplicating"
      result.duplication_started_at = Time.zone.now
    else
      result.workflow_state = "unpublished"
    end

    result.post_to_sis = false

    result
  end

  def finish_duplicating
    return unless ["duplicating", "failed_to_duplicate"].include?(workflow_state)

    self.workflow_state = if root_account.feature_enabled?(:course_copy_alignments)
                            "outcome_alignment_cloning"
                          else
                            (duplicate_of&.workflow_state == "published" || !can_unpublish?) ? "published" : "unpublished"
                          end
  end

  def finish_alignment_cloning
    return unless ["outcome_alignment_cloning", "failed_to_clone_outcome_alignment"].include?(workflow_state)

    self.workflow_state =
      (duplicate_of&.workflow_state == "published" || !can_unpublish?) ? "published" : "unpublished"
  end

  def can_duplicate?
    return false if quiz?
    return false if external_tool_tag.present? && submission_types.include?("external_tool") && !quiz_lti?

    true
  end

  def ensure_points_possible!
    return if points_possible.present?
    return unless grading_type_requires_points?

    update!(points_possible: DEFAULT_POINTS_POSSIBLE)
  end

  # Returns the value to be stored in the polymorphic type column for Polymorphic Associations.
  def self.polymorphic_name
    "Assignment"
  end

  # Returns the value to be used for asset string prefixes.
  def self.reflection_type_name
    name.underscore
  end

  def self.serialization_root_key
    name.underscore
  end

  def self.url_context_class
    self
  end

  def self.clean_up_duplicating_assignments
    duplicating_for_too_long.update_all(
      duplication_started_at: nil,
      workflow_state: "failed_to_duplicate",
      updated_at: Time.zone.now
    )
  end

  def self.clean_up_cloning_alignments
    cloning_alignments_for_too_long.update_all(
      duplication_started_at: nil,
      workflow_state: "failed_to_clone_outcome_alignment",
      updated_at: Time.zone.now
    )
  end

  def self.clean_up_importing_assignments
    importing_for_too_long.update_all(
      importing_started_at: nil,
      workflow_state: "failed_to_import",
      updated_at: Time.zone.now
    )
  end

  def self.clean_up_migrating_assignments
    migrating_for_too_long.update_all(
      duplication_started_at: nil,
      workflow_state: "failed_to_migrate",
      updated_at: Time.zone.now
    )
  end

  delegate :restrict_quantitative_data?, to: :course

  def group_category_changes_ok?
    return false unless group_category_id_changed?

    if has_submitted_submissions?
      errors.add :group_category_id,
                 I18n.t("The group category can't be changed because students have already submitted on this assignment")
    end

    if anonymous_grading? && !anonymous_grading_changed?
      errors.add :group_category_id, I18n.t("Anonymously graded assignments can't be group assignments")
    end
  end
  private :group_category_changes_ok?

  def turnitin_changes_ok?
    return false unless turnitin_enabled_changed?

    if has_submitted_submissions?
      errors.add :turnitin_enabled,
                 I18n.t("The plagiarism platform settings can't be changed because students have already submitted on this assignment")
    end
  end
  private :turnitin_changes_ok?

  def vericite_changes_ok?
    return false unless vericite_enabled_changed?

    if has_submitted_submissions?
      errors.add :vericite_enabled,
                 I18n.t("The plagiarism platform settings can't be changed because students have already submitted on this assignment")
    end
  end
  private :vericite_changes_ok?

  def anonymous_grading_changes_ok?
    return false unless anonymous_grading_changed?

    if group_category.present? && !group_category_id_changed?
      errors.add :anonymous_grading, I18n.t("Group assignments can't be anonymously graded")
    end
  end
  private :anonymous_grading_changes_ok?

  def no_anonymous_group_assignments
    return unless group_category_id_changed? && anonymous_grading_changed?

    if group_category.present? && anonymous_grading?
      errors.add :base, I18n.t("Can't enable anonymous grading and group assignments together")
    end
  end
  private :no_anonymous_group_assignments

  def due_date_required?
    AssignmentUtil.due_date_required?(self)
  end

  def max_name_length
    if AssignmentUtil.assignment_name_length_required?(self)
      return AssignmentUtil.assignment_max_name_length(context)
    end

    Assignment.maximum_string_length
  end

  def secure_params(include_description: true)
    body = {}
    body[:lti_assignment_id] = lti_context_id || SecureRandom.uuid
    body[:lti_assignment_description] = lti_safe_description if include_description
    Canvas::Security.create_jwt(body)
  end

  def discussion_group_ok?
    return false unless new_record? || group_category_id_changed?
    return false unless group_category_id && submission_types == "discussion_topic"

    errors.add :group_category_id, I18n.t("discussion_group_category_locked",
                                          "Group categories cannot be set directly on a discussion assignment, but should be set on the discussion instead")
  end

  def provisional_grades_exist?
    return false unless moderated_grading? || moderated_grading_changed?

    ModeratedGrading::ProvisionalGrade
      .where(submission_id: submissions.having_submission.select(:id))
      .where.not(score: nil).exists?
  end

  def graded_submissions_exist?
    return false unless graded?

    (graded_count > 0) || provisional_grades_exist?
  end

  def moderation_setting_ok?
    if moderated_grading_changed? && graded_submissions_exist?
      errors.add :moderated_grading, I18n.t("Moderated grading setting cannot be changed if graded submissions exist")
    end
    if (moderated_grading_changed? || new_record?) && moderated_grading?
      unless graded?
        errors.add :moderated_grading, I18n.t("Moderated grading setting cannot be enabled for ungraded assignments")
      end
      if has_group_category?
        errors.add :moderated_grading, I18n.t("Moderated grading setting cannot be enabled for group assignments")
      end
      if peer_reviews
        errors.add :moderated_grading, I18n.t("Moderated grading setting cannot be enabled for peer reviewed assignments")
      end
    end
  end

  def external_tool?
    submission_types == "external_tool"
  end

  validates :context_id, :context_type, :workflow_state, presence: true

  validates :title, presence: { if: :title_changed? }
  validates :description, length: { maximum: maximum_long_text_length, allow_blank: true }
  validate :frozen_atts_not_altered, if: :frozen?, on: :update
  validates :grading_type, inclusion: { in: ALLOWED_GRADING_TYPES }
  validates :hide_in_gradebook, inclusion: { in: [true, false] }
  validates :hide_in_gradebook, comparison: { equal_to: :omit_from_final_grade }, if: :hide_in_gradebook?
  validates :hide_in_gradebook, inclusion: { in: [false] }, if: -> { points_possible.present? && points_possible > 0 }

  acts_as_list scope: :assignment_group
  simply_versioned keep: 5
  sanitize_field :description, CanvasSanitize::SANITIZE
  copy_authorized_links(:description) { [context, nil] }

  def root_account
    context&.root_account
  end

  def name
    title
  end

  def name=(val)
    self.title = val
  end

  serialize :integration_data, type: Hash

  serialize :turnitin_settings, type: Hash
  # file extensions allowed for online_upload submission
  serialize :allowed_extensions, type: Array

  def allowed_extensions=(new_value)
    # allow both comma and whitespace as separator
    new_value = new_value.split(/[\s,]+/) if new_value.is_a?(String)

    # remove the . if they put it on, and extra whitespace
    new_value.map! { |v| v.strip.delete_prefix(".").downcase } if new_value.is_a?(Array)

    write_attribute(:allowed_extensions, new_value)
  end

  # ensure a root_account_id is set before validation so that we can
  # properly validate sis_source_id uniqueness by root_account_id
  before_validation :set_root_account_id, on: :create
  before_create :set_muted

  before_save :ensure_post_to_sis_valid,
              :process_if_quiz,
              :default_values,
              :validate_assignment_overrides,
              :mute_if_changed_to_anonymous,
              :mute_if_changed_to_moderated

  before_destroy :delete_observer_alerts

  def delete_observer_alerts
    observer_alerts.in_batches(of: 10_000).delete_all
  end

  after_save  :update_submissions_and_grades_if_details_changed,
              :update_grading_period_grades,
              :touch_assignment_group,
              :touch_context,
              :update_grading_standard,
              :update_submittable,
              :update_submissions_later,
              :delete_empty_abandoned_children,
              :update_cached_due_dates,
              :apply_late_policy,
              :update_line_items,
              :ensure_manual_posting_if_anonymous,
              :ensure_manual_posting_if_moderated,
              :create_default_post_policy

  after_save  :start_canvadocs_render, if: :saved_change_to_annotatable_attachment_id?
  after_save  :update_due_date_smart_alerts, if: :update_cached_due_dates?
  after_save  :mark_module_progressions_outdated, if: :update_cached_due_dates?
  after_save  :workflow_change_refresh_content_partication_counts, if: :saved_change_to_workflow_state?
  after_save  :submission_types_change_refresh_content_participation_counts, if: :saved_change_to_submission_types?
  after_save  :track_anonymously_graded_new_quizzes, if: :saved_change_to_anonymous_grading?

  after_commit :schedule_do_auto_peer_review_job_if_automatic_peer_review

  with_options if: -> { auditable? && @updating_user.present? } do
    after_create :create_assignment_created_audit_event!
    after_update :create_assignment_updated_audit_event!
    after_save :create_grades_posted_audit_event!, if: :saved_change_to_grades_published_at
  end

  has_a_broadcast_policy

  def create_assignment_created_audit_event!
    auditable_changes = AUDITABLE_ATTRIBUTES.each_with_object({}) do |attribute, map|
      map[attribute] = attributes[attribute] unless attributes[attribute].nil?
    end

    create_audit_event!(event_type: :assignment_created, payload: auditable_changes)
  end
  private :create_assignment_created_audit_event!

  def create_assignment_updated_audit_event!
    auditable_changes = if became_auditable?
                          AUDITABLE_ATTRIBUTES.each_with_object({}) do |attribute, map|
                            next if attributes[attribute].nil?

                            map[attribute] = if saved_changes.key?(attribute)
                                               saved_changes[attribute]
                                             else
                                               [attributes[attribute], attributes[attribute]]
                                             end
                          end
                        else
                          saved_changes.slice(*AUDITABLE_ATTRIBUTES)
                        end

    return if auditable_changes.empty?

    create_audit_event!(event_type: :assignment_updated, payload: auditable_changes)
  end
  private :create_assignment_updated_audit_event!

  def create_audit_event!(event_type:, payload:)
    AnonymousOrModerationEvent.create!(
      assignment: self,
      user: @updating_user,
      event_type:,
      payload:
    )
  end
  private :create_audit_event!

  # track events when an assignment is anonymous or moderated grading also track when save_changes includes
  # anonymous_grading or moderated_grading grading see also: #became_auditable? for when an assignment's
  # anonymous/moderated grading setting has gone from disabled to enabled
  def auditable?
    anonymous_grading? ||
      moderated_grading? ||
      saved_change_to_anonymous_grading? ||
      saved_change_to_moderated_grading?
  end

  # saved_changes includes anonymous_grading or moderated grading changing from disabled to enabled
  def became_auditable?
    saved_change_to_anonymous_grading?(from: false, to: true) || saved_change_to_moderated_grading?(from: false, to: true)
  end
  private :became_auditable?

  def create_grades_posted_audit_event!
    return if @updating_user.nil?

    AnonymousOrModerationEvent.create!(
      assignment: self,
      event_type: :grades_posted,
      payload: saved_changes.slice(:grades_published_at),
      user: @updating_user
    )
  end
  private :create_grades_posted_audit_event!

  after_save :remove_assignment_updated_flag # this needs to be after has_a_broadcast_policy for the message to be sent

  def validate_assignment_overrides(opts = {})
    if opts[:force_override_destroy] || will_save_change_to_group_category_id?
      # needs to be .each(&:destroy) instead of .update_all(:workflow_state =>
      # 'deleted') so that the override gets versioned properly
      active_assignment_overrides
        .where(set_type: "Group")
        .each do |o|
          o.dont_touch_assignment = true
          o.destroy
        end
    end

    AssignmentOverrideStudent.clean_up_for_assignment(self)
  end

  def schedule_do_auto_peer_review_job_if_automatic_peer_review
    return unless needs_auto_peer_reviews_scheduled?

    # When saving the assignment set the @next_auto_peer_review_date variable,
    # use it as the run_at date for the next job. Otherwise, use the method
    # of the same name to get the next automatic peer review date based on
    # this assignment's configuration.
    run_at = @next_auto_peer_review_date || next_auto_peer_review_date
    return if run_at.blank?

    run_at = 1.minute.from_now if run_at < 1.minute.from_now # delay immediate run in case associated objects are still being saved
    delay(run_at:,
          on_conflict: :overwrite,
          singleton: Shard.birth.activate { "assignment:auto_peer_review:#{id}" })
      .do_auto_peer_review
  end

  alias_method :skip_schedule_peer_reviews?, :skip_schedule_peer_reviews
  def needs_auto_peer_reviews_scheduled?
    !skip_schedule_peer_reviews? && peer_reviews? && automatic_peer_reviews? && !peer_reviews_assigned?
  end

  def do_auto_peer_review
    assign_peer_reviews if needs_auto_peer_reviews_scheduled?
  end

  def touch_assignment_group
    if saved_change_to_assignment_group_id? && assignment_group_id_before_last_save.present?
      AssignmentGroup.where(id: assignment_group_id_before_last_save).update_all(updated_at: Time.zone.now.utc)
    end
    AssignmentGroup.where(id: assignment_group_id).update_all(updated_at: Time.zone.now.utc) if assignment_group_id
    true
  end

  def track_anonymously_graded_new_quizzes
    return unless quiz_lti?

    if anonymous_grading_changed?(to: true)
      InstStatsd::Statsd.increment("assignment.new_quiz.anonymous.enabled")
    end
  end

  def ab_guid_through_rubric
    # ab_guid is an academic benchmark guid - it can be saved on the assignmenmt itself, or accessed through this association
    rubric&.learning_outcome_alignments&.filter_map { |loa| loa.learning_outcome.vendor_guid } || []
  end

  def update_student_submissions(updating_user)
    graded_at = Time.zone.now
    submissions.graded.preload(:user).find_each do |s|
      if grading_type == "pass_fail" && ["complete", "pass"].include?(s.grade)
        s.score = points_possible
      end
      s.grade = score_to_grade(s.score, s.grade)
      s.graded_at = graded_at
      s.assignment = self
      s.assignment_changed_not_sub = true
      s.grade_change_event_author_id = updating_user&.id
      s.grader = updating_user if updating_user

      # Skip the grade calculation for now. We'll do it at the end.
      s.skip_grade_calc = true
      s.with_versioning(explicit: true) { s.save! }
    end

    unless saved_by == :migration
      context.recompute_student_scores
    end
  end

  def needs_to_update_submissions?
    !id_before_last_save.nil? &&
      (saved_change_to_points_possible? || saved_change_to_grading_type? || saved_change_to_grading_standard_id?) &&
      submissions.graded.exists?
  end
  private :needs_to_update_submissions?

  def start_canvadocs_render
    return if annotatable_attachment.blank? || annotatable_attachment.canvadoc&.available?

    canvadocs_opts = { preferred_plugins: [Canvadocs::RENDER_PDFJS], wants_annotation: true }
    annotatable_attachment.submit_to_canvadocs(1, **canvadocs_opts)
  end
  private :start_canvadocs_render

  # if a teacher changes the settings for an assignment and students have
  # already been graded, then we need to update the "grade" column to
  # reflect the changes
  def update_submissions_and_grades_if_details_changed
    if needs_to_update_submissions?
      delay_if_production.update_student_submissions(@updating_user)
    else
      update_grades_if_details_changed
    end
    true
  end

  def needs_to_recompute_grade?
    !id_before_last_save.nil? && (
      saved_change_to_points_possible? ||
      saved_change_to_workflow_state? ||
      saved_change_to_assignment_group_id? ||
      saved_change_to_only_visible_to_overrides? ||
      saved_change_to_omit_from_final_grade?
    )
  end
  private :needs_to_recompute_grade?

  def update_grades_if_details_changed
    if needs_to_recompute_grade? && saved_by != :migration
      self.class.connection.after_transaction_commit { context.recompute_student_scores }
    end
    true
  end
  private :update_grades_if_details_changed

  def update_grading_period_grades
    return true unless saved_change_to_due_at? && !saved_change_to_id? && context.grading_periods? && saved_by != :migration

    grading_period_was = GradingPeriod.for_date_in_course(date: due_at_before_last_save, course: context)
    grading_period = GradingPeriod.for_date_in_course(date: due_at, course: context)
    return true if grading_period_was&.id == grading_period&.id

    if grading_period_was
      # recalculate just the old grading period's score
      context.recompute_student_scores(grading_period_id: grading_period_was.id, update_course_score: false)
    end

    unless needs_to_recompute_grade? || needs_to_update_submissions?
      # recalculate the new grading period's score. If the grading period group is
      # weighted, then we need to recalculate the overall course score too. (If
      # grading period is nil, make sure we pass true for `update_course_score`
      # so we can use a singleton job.)
      context.recompute_student_scores(
        grading_period_id: grading_period&.id,
        update_course_score: grading_period.blank? || grading_period.grading_period_group&.weighted?
      )
    end
    true
  end
  private :update_grading_period_grades

  def create_in_turnitin
    return false unless context.turnitin_settings
    return true if turnitin_settings[:current]

    turnitin = Turnitin::Client.new(*context.turnitin_settings)
    res = turnitin.createOrUpdateAssignment(self, turnitin_settings)

    # make sure the defaults get serialized
    self.turnitin_settings = turnitin_settings

    if res[:assignment_id]
      turnitin_settings[:created] = true
      turnitin_settings[:current] = true
      turnitin_settings.delete(:error)
    else
      turnitin_settings[:error] = res
    end
    save
    turnitin_settings[:current]
  end

  def turnitin_settings(settings = nil)
    if super().empty?
      # turnitin settings are overloaded for all plagiarism services as requested, so
      # alternative services can send in their own default settings, otherwise,
      # default to Turnitin settings
      if settings.nil?
        settings = Turnitin::Client.default_assignment_turnitin_settings
        default_originality = course.turnitin_originality if course
        settings[:originality_report_visibility] = default_originality if default_originality
      end
      settings
    else
      super()
    end
  end

  def turnitin_settings=(settings)
    settings = if vericite_enabled?
                 VeriCite::Client.normalize_assignment_vericite_settings(settings)
               else
                 Turnitin::Client.normalize_assignment_turnitin_settings(settings)
               end
    unless settings.blank?
      [:created, :error].each do |key|
        settings[key] = turnitin_settings[key] if turnitin_settings[key]
      end
    end
    write_attribute :turnitin_settings, settings
  end

  def create_in_vericite
    return false unless Canvas::Plugin.find(:vericite).try(:enabled?)
    return true if turnitin_settings[:current] && turnitin_settings[:vericite]

    vericite = VeriCite::Client.new
    res = vericite.createOrUpdateAssignment(self, turnitin_settings)

    # make sure the defaults get serialized
    self.turnitin_settings = turnitin_settings

    if res[:assignment_id]
      turnitin_settings[:created] = true
      turnitin_settings[:current] = true
      turnitin_settings[:vericite] = true
      turnitin_settings.delete(:error)
    else
      turnitin_settings[:error] = res
    end
    save
    turnitin_settings[:current]
  end

  def vericite_settings
    turnitin_settings(VeriCite::Client.default_assignment_vericite_settings)
  end

  def vericite_settings=(settings)
    settings = VeriCite::Client.normalize_assignment_vericite_settings(settings)
    unless settings.blank?
      [:created, :error].each do |key|
        settings[key] = turnitin_settings[key] if turnitin_settings[key]
      end
    end
    write_attribute :turnitin_settings, settings
  end

  def self.all_day_interpretation(opts = {})
    if opts[:due_at]
      if opts[:due_at] == opts[:due_at_was]
        # (comparison is modulo time zone) no real change, leave as was
        [opts[:all_day_was], opts[:all_day_date_was]]
      else
        # 'normal' case. compare due_at to fancy midnight and extract its
        # date-part
        [(opts[:due_at].strftime("%H:%M") == "23:59"), opts[:due_at].to_date]
      end
    else
      # no due at = all_day and all_day_date are irrelevant
      [false, nil]
    end
  end

  def self.remove_user_as_final_grader(user_id, course_id)
    strand_identifier = Course.find(course_id).root_account.global_id
    delay_if_production(strand: "Assignment.remove_user_as_final_grader:#{strand_identifier}",
                        priority: Delayed::LOW_PRIORITY)
      .remove_user_as_final_grader_immediately(user_id, course_id)
  end

  def self.remove_user_as_final_grader_immediately(user_id, course_id)
    Assignment.where(context_id: course_id, context_type: "Course", final_grader_id: user_id).find_each do |assignment|
      # going this route instead of doing an update_all so that we create a new
      # assignment version when this update happens
      assignment.update!(final_grader_id: nil)
    end
  end

  def ensure_post_to_sis_valid
    self.post_to_sis = false unless gradeable?
    true
  end
  private :ensure_post_to_sis_valid

  def default_values
    raise "Assignments can only be assigned to Course records" if context_type && context_type != "Course"

    self.title ||= (assignment_group.default_assignment_name rescue nil) || "Assignment"

    infer_all_day
    self.position = position_was if will_save_change_to_position? && position.nil? # don't allow setting to nil

    if !assignment_group || (assignment_group.deleted? && !deleted?)
      ensure_assignment_group(false)
    end
    self.submission_types ||= "none"
    if will_save_change_to_submission_types? && ["none", "on_paper"].include?(self.submission_types)
      self.allowed_attempts = nil
    end
    self.peer_reviews_assigned = false if peer_reviews_due_at_changed?
    %i[
      all_day
      could_be_locked
      grade_group_students_individually
      anonymous_peer_reviews
      turnitin_enabled
      vericite_enabled
      moderated_grading
      omit_from_final_grade
      hide_in_gradebook
      freeze_on_copy
      copied
      only_visible_to_overrides
      post_to_sis
      peer_reviews_assigned
      peer_reviews
      automatic_peer_reviews
      muted
      intra_group_peer_reviews
      anonymous_grading
    ].each { |attr| self[attr] = false if self[attr].nil? }
    self.graders_anonymous_to_graders = false unless grader_comments_visible_to_graders
  end
  protected :default_values

  def ensure_assignment_group(do_save = true)
    return if assignment_group_id

    context.require_assignment_group
    self.assignment_group = context.assignment_groups.active.first
    if do_save
      GuardRail.activate(:primary) { save! }
    end
  end

  def attendance?
    submission_types == "attendance"
  end

  def due_date
    all_day ? all_day_date : due_at
  end

  def delete_empty_abandoned_children
    if governs_submittable? && saved_change_to_submission_types?
      each_submission_type do |submittable, type|
        unless self.submission_types == type.to_s
          submittable&.unlink!(:assignment)
        end
      end
    end
  end

  def update_submissions_later
    delay_if_production.update_submissions if saved_change_to_points_possible?
  end

  def update_submissions
    @updated_submissions ||= []
    Submission.suspend_callbacks(:update_assignment, :touch_graders) do
      submissions.find_each do |submission|
        @updated_submissions << submission
        submission.save!
      end
    end
    context.clear_todo_list_cache(:admins) if context.is_a?(Course)
  end

  def update_submittable
    # If we're updating the assignment's muted status as part of posting
    # grades, don't bother doing this
    return true if !governs_submittable? || deleted? || grade_posting_in_progress

    if self.submission_types == "online_quiz" && @saved_by != :quiz
      quiz = Quizzes::Quiz.where(assignment_id: self).first || context.quizzes.build
      quiz.assignment_id = id
      quiz.title = self.title
      quiz.description = description
      quiz.due_at = due_at
      quiz.unlock_at = unlock_at
      quiz.lock_at = lock_at
      quiz.points_possible = points_possible
      quiz.assignment_group_id = assignment_group_id
      quiz.workflow_state = "created" if quiz.deleted?
      quiz.saved_by = :assignment
      quiz.workflow_state = published? ? "available" : "unpublished"
      quiz.save if quiz.changed?
    elsif self.submission_types == "discussion_topic" && @saved_by != :discussion_topic
      topic = discussion_topic || context.discussion_topics.build(user: @updating_user)
      topic.message = description
      save_submittable(topic)
      self.discussion_topic = topic
    elsif context.conditional_release? &&
          self.submission_types == "wiki_page" && @saved_by != :wiki_page
      page = wiki_page || context.wiki_pages.build(user: @updating_user)
      save_submittable(page)
      self.wiki_page = page
    end
  end

  def save_submittable(submittable)
    submittable.assignment_id = id
    submittable.title = self.title
    submittable.saved_by = :assignment
    submittable.updated_at = Time.zone.now
    submittable.workflow_state = "active" if submittable.deleted?
    submittable.workflow_state = published? ? "active" : "unpublished"
    submittable.save
  end
  protected :save_submittable

  def update_grading_standard
    grading_standard&.save!
  end

  def all_context_module_tags
    all_tags = context_module_tags.to_a
    each_submission_type do |submission, _, short_type|
      all_tags.concat(submission.context_module_tags) if send(:"#{short_type}?")
    end
    all_tags
  end

  def context_module_action(user, action, points = nil)
    all_context_module_tags.each { |tag| tag.context_module_action(user, action, points) }
  end

  def recalculate_module_progressions(submission_ids)
    # recalculate the module progressions now that the assignment is unmuted
    submitted_scope = Submission.having_submission.or(Submission.graded)
    student_ids = submissions.merge(submitted_scope).where(id: submission_ids).pluck(:user_id)
    return if student_ids.blank?

    tags = all_context_module_tags
    return unless tags.any?

    modules = ContextModule.where(id: tags.map(&:context_module_id)).ordered.to_a.select do |mod|
      mod.completion_requirements&.any? { |req| req[:type] == "min_score" && tags.map(&:id).include?(req[:id]) }
    end
    return unless modules.any?

    modules.each do |mod|
      if mod.context_module_progressions.where(current: true, user_id: student_ids).update_all(current: false) > 0
        mod.delay_if_production(n_strand: ["evaluate_module_progressions", global_context_id],
                                singleton: "evaluate_module_progressions:#{mod.global_id}").evaluate_all_progressions
      end
    end
  end

  # @see Lti::Migratable
  def migrate_to_1_3_if_needed!(tool)
    # Don't do anything unless the tool is actually a 1.3 tool
    return unless tool&.use_1_3? && tool.developer_key.present?

    # The assignment has already been migrated.
    return if line_items.active.present? && primary_resource_link&.lti_1_1_id.present?

    # If the tool is nil, as is the case in just-in-time launches,
    # update_line_items will re-lookup the appropriate tool for us.
    # Otherwise, tool will be a 1.3 tool that was already fetched
    # appropriately, so we can just pass it in and avoid re-querying.
    update_line_items(tool, lti_1_1_id: lti_resource_link_id)
  end

  # filtered by context during migrate_content_to_1_3
  # @see Lti::Migratable
  def self.directly_associated_items(tool_id)
    Assignment.nondeleted.joins(:external_tool_tag).where(content_tags: { content_id: tool_id })
  end

  # filtered by context during migrate_content_to_1_3
  # @see Lti::Migratable
  def self.indirectly_associated_items(_tool_id)
    # TODO: this does not account for assignments that _are_ linked to a
    # tool and the tag has a content_id, but the content_id doesn't match
    # the current tool
    Assignment.nondeleted.joins(:external_tool_tag).where(content_tags: { content_id: nil })
  end

  # @see Lti::Migratable
  def self.fetch_direct_batch(ids, &)
    Assignment.where(id: ids).find_each(&)
  end

  # @see Lti::Migratable
  def self.fetch_indirect_batch(tool_id, new_tool_id, ids)
    Assignment
      .where(id: ids)
      .preload(:external_tool_tag)
      .find_each do |a|
        # again, look for the 1.1 tool by excluding the new tool from this query.
        # a (currently) unavoidable N+1, sadly
        a_tool = ContextExternalTool.find_external_tool(a.external_tool_tag.url, a, nil, new_tool_id)
        next if a_tool.nil? || a_tool.id != tool_id

        yield a
      end
  end

  def create_assignment_line_item!
    update_line_items
  end

  def update_line_items(lti_1_3_tool = nil, lti_1_1_id: nil)
    # TODO: Edits to existing Assignment<->Tool associations are (mostly) ignored
    #
    # A few key points as a result:
    #
    # - Adding a 1.3 Tool to an Assignment which did not _ever_ have one previously _is_ supported and will result
    # in LineItem+ResourceLink creation. But otherwise any attempt to add/edit/delete the Tool binding will have no
    # impact on associated LineItems and ResourceLinks, even if it means those associations are now stale.
    #
    # - Associated LineItems and ResourceLinks are never deleted b/c this could possibly result in grade loss (cascaded
    # delete from ResourceLink->LineItem->Result)
    #
    # - So in the case where a Tool association is abandoned or re-pointed to a different Tool, the Assignment's
    # previously created LineItems and ResourceLinks will still exist and will be anomalous. I.e. they will be bound to
    # a different tool than the Assignment.
    #
    # - Until this is resolved, clients trying to resolve an Assignment via ResourceLink->LineItem->Assignment chains
    # have to remember to also check that the Assignment's ContentTag is still associated with the same
    # ContextExternalTool as the ResourceLink. Also check Assignment.external_tool?.
    #
    # - Edits to assignment title and points_possible always propagate to the primary associated LineItem, even if the
    # currently bound Tool doesn't support LTI 1.3 or if the LineItem's ResourceLink doesn't agree with Assignment's
    # ContentTag on the currently bound tool. Presumably you always want correct data in the LineItem, regardless of
    # which Tool it's bound to.
    GuardRail.activate(:primary) do
      transaction do
        if lti_1_3_external_tool_tag?(lti_1_3_tool) && line_items.empty?
          rl = Lti::ResourceLink.create!(
            context: self,
            custom: validate_resource_link_custom_params,
            resource_link_uuid: lti_context_id,
            context_external_tool: lti_1_3_tool || tool_from_external_tool_tag,
            url: lti_resource_link_url,
            lti_1_1_id:
          )

          li = line_items.create!(
            label: title,
            score_maximum: points_possible,
            resource_link: rl,
            coupled: true,
            resource_id: line_item_resource_id,
            tag: line_item_tag,
            start_date_time: unlock_at,
            end_date_time: due_at
          )
          create_results_from_prior_grades(li)
        elsif saved_change_to_title? || saved_change_to_points_possible? || saved_change_to_due_at? || saved_change_to_unlock_at?
          if (li = line_items.find(&:assignment_line_item?))
            li.label = title
            li.score_maximum = points_possible || 0
            li.tag = line_item_tag if line_item_tag
            li.resource_id = line_item_resource_id if line_item_resource_id
            li.start_date_time = unlock_at
            li.end_date_time = due_at
            li.save!
          end
        end

        if lti_1_3_external_tool_tag?(lti_1_3_tool) && !lti_resource_links.empty?
          options = {}
          validated_params = validate_resource_link_custom_params
          # Check if they actually passed something that isn't just our default value of nil, such as an
          # empty string to signify they really want to set the custom params to nil, then format
          # it for storage.
          if !lti_resource_link_custom_params.nil? && validated_params != primary_resource_link.custom
            options[:custom] = validated_params
          end

          options[:lookup_uuid] = lti_resource_link_lookup_uuid unless lti_resource_link_lookup_uuid.nil?
          options[:url] = lti_resource_link_url if lti_resource_link_url
          options[:lti_1_1_id] = lti_1_1_id if lti_1_1_id.present?

          primary_resource_link.update!(options) unless options.empty?
        end
      end
    end
  end
  protected :update_line_items

  # This should only be called once, upon line item creation.
  # It ensures that any prior scores are reflected in the AGS Results API,
  # and creates results like they are created in the AGS Scores API.
  # It ignores any previous submission versions in favor of the most recent.
  def create_results_from_prior_grades(line_item)
    submissions.where.not(score: nil).each do |sub|
      line_item.results.create!(
        submission: sub,
        user: sub.user,
        created_at: Time.zone.now,
        updated_at: sub.graded_at,
        result_score: sub.score,
        result_maximum: points_possible || 0,
        extensions: {
          Lti::Result::AGS_EXT_SUBMISSION => { submitted_at: sub.submitted_at }
        }
      )
    end
  end
  protected :create_results_from_prior_grades

  def validate_resource_link_custom_params
    Lti::DeepLinkingUtil.validate_custom_params(lti_resource_link_custom_params)
  end
  private :validate_resource_link_custom_params

  def primary_resource_link
    @primary_resource_link ||= lti_resource_links.find_by(
      resource_link_uuid: lti_context_id,
      context: self
    )
  end

  def lti_1_3_external_tool_tag?(lti_1_3_tool)
    return false unless external_tool?
    return false unless external_tool_tag&.content_type == "ContextExternalTool"
    return lti_1_3_tool.use_1_3? if lti_1_3_tool

    # Lookup the tool and check if the LTI version is 1.3
    tool_from_external_tool_tag&.use_1_3?
  end
  private :lti_1_3_external_tool_tag?

  def tool_from_external_tool_tag
    @tool_from_external_tool_tag = ContextExternalTool.from_content_tag(
      external_tool_tag,
      context
    )
  end

  # call this to perform notifications on an Assignment that is not being saved
  # (useful when a batch of overrides associated with a new assignment have been saved)
  def do_notifications!(prior_version = nil, notify = false)
    # TODO: this will blow up if the group_category string is set on the
    # previous version, because it gets confused between the db string field
    # and the association.  one more reason to drop the db column
    prior_version ||= versions.previous(current_version.number).try(:model)
    self.notify_of_update = notify || false
    broadcast_notifications(prior_version || dup)
    remove_assignment_updated_flag
  end

  def course_broadcast_data
    context&.broadcast_data
  end

  def notify_of_update=(val)
    @assignment_changed = Canvas::Plugin.value_to_boolean(val)
  end

  def notify_of_update
    false
  end

  def remove_assignment_updated_flag
    @assignment_changed = false
    true
  end

  def points_uneditable?
    (self.submission_types == "online_quiz") # && self.quiz && (self.quiz.edited? || self.quiz.available?))
  end

  workflow do
    state :published do
      event :unpublish, transitions_to: :unpublished
    end
    state :unpublished do
      event :publish, transitions_to: :published
    end
    state :duplicating do
      event :fail_to_duplicate, transitions_to: :failed_to_duplicate
    end
    state :failed_to_duplicate
    state :importing do
      event :finish_importing, transitions_to: :unpublished
      event :fail_to_import, transitions_to: :fail_to_import
    end
    state :fail_to_import
    state :migrating do
      event :finish_migrating, transitions_to: :unpublished
      event :fail_to_migrate, transitions_to: :failed_to_migrate
    end
    state :failed_to_migrate
    state :deleted
    state :outcome_alignment_cloning do
      event :fail_to_clone_alignment, transitions_to: :failed_to_clone_outcome_alignment
    end
    state :failed_to_clone_outcome_alignment
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    ContentTag.delete_for(self)
    rubric_association.destroy if active_rubric_association?
    save!

    each_submission_type { |submission| submission.destroy if submission && !submission.deleted? }
    conditional_release_rules.destroy_all
    conditional_release_associations.destroy_all
    refresh_course_content_participation_counts

    # Assignment owns deletion of Lti::LineItem, Lti::ResourceLink
    # destroy_all removes associations, so avoid that
    lti_resource_links.find_each(&:destroy)

    ScheduledSmartAlert.where(context_type: "Assignment", context_id: id).destroy_all
    ScheduledSmartAlert.where(context_type: "AssignmentOverride", context_id: assignment_override_ids).destroy_all
  end

  def workflow_change_refresh_content_partication_counts
    trigger_workflow_states = %w[published unpublished]
    refresh_course_content_participation_counts if trigger_workflow_states.include?(workflow_state)
  end

  def submission_types_change_refresh_content_participation_counts
    previous_submission_types = submission_types_before_last_save
    submission_types_trigger = previous_submission_types == "not_graded" || submission_types == "not_graded"
    refresh_course_content_participation_counts if submission_types_trigger
  end

  def refresh_course_content_participation_counts
    progress = context.progresses.build(tag: "refresh_content_participation_counts")
    progress.save!
    progress.process_job(
      context,
      :refresh_content_participation_counts,
      { singleton: "refresh_content_participation_counts:#{context.global_id}" }
    )
  end

  def time_zone_edited
    CGI.unescapeHTML(read_attribute(:time_zone_edited) || "")
  end

  def restore(from = nil)
    self.workflow_state = has_student_submissions? ? "published" : "unpublished"
    save
    each_submission_type do |submission, _, short_type|
      submission.restore(:assignment) if from != short_type && submission
    end
    lti_resource_links.find_each(&:undestroy)
    external_tool_tag&.update!(workflow_state: "active")
  end

  def participants_with_overridden_due_at
    Assignment.participants_with_overridden_due_at([self])
  end

  def self.participants_with_overridden_due_at(assignments)
    overridden_users = []

    AssignmentOverride.active.overriding_due_at.where(assignment_id: assignments).each do |o|
      overridden_users.concat(o.applies_to_students)
    end

    overridden_users.uniq!
    overridden_users
  end

  def students_with_visibility(scope = nil)
    scope ||= context.all_students.where("enrollments.workflow_state NOT IN ('inactive', 'rejected')")
    return scope unless differentiated_assignments_applies?

    scope.able_to_see_assignment_in_course_with_da(id, context.id)
  end

  def process_if_quiz
    if self.submission_types == "online_quiz"
      self.points_possible = quiz.points_possible if quiz&.available?
      copy_attrs = %w[due_at lock_at unlock_at]
      if quiz && @saved_by != :quiz &&
         copy_attrs.any? { |attr| changes[attr] }
        copy_attrs.each { |attr| quiz.send :"#{attr}=", send(attr) }
        quiz.saved_by = :assignment
        quiz.save
      end
    end
  end
  protected :process_if_quiz

  delegate :grading_scheme, to: :grading_standard_or_default

  def infer_grading_type
    self.grading_type = nil if grading_type.blank?
    self.grading_type = "pass_fail" if self.submission_types == "attendance"
    self.grading_type = "not_graded" if self.submission_types == "wiki_page"
    self.grading_type ||= "points"
  end

  def score_to_grade_percent(score = 0.0)
    if points_possible && points_possible > 0
      result = score.to_f / points_possible
      (result * 100.0).round(2)
    else
      # there's not really any reasonable value we can set here -- if the
      # assignment is worth no points, any percentage is as valid as any other.
      score.to_f
    end
  end

  def grading_standard_or_default
    grading_standard ||
      # use the course's custom grading standard before using defaults
      context.grading_standard ||
      context.default_grading_standard ||
      GradingStandard.default_instance
  end

  def score_to_grade(score = 0.0, given_grade = nil, force_letter_grade = false)
    result = score.to_f
    case force_letter_grade ? "letter_grade" : self.grading_type
    when "percent"
      result = "#{round_if_whole(score_to_grade_percent(score))}%"
    when "pass_fail"
      passed = if points_possible && points_possible > 0
                 score.to_f > 0
               elsif given_grade
                 given_grade == "complete" || given_grade == "pass"
               end
      result = passed ? "complete" : "incomplete"
    when "letter_grade", "gpa_scale"
      if points_possible.to_f > 0.0
        score = BigDecimal(score.to_s.presence || "0.0") / BigDecimal(points_possible.to_s)
        result = grading_standard_or_default.score_to_grade((score * 100).to_f)
      elsif given_grade
        # this block is hit when a zero pointed assignment has been graded
        result = if force_letter_grade
                   if score == 0
                     "complete"
                   elsif score < 0
                     given_grade
                   else
                     # show a perfect grade when positive / 0
                     grading_standard_or_default.score_to_grade(100)
                   end
                 else
                   # the score for a zero-point letter_grade assignment could be considered
                   # to be *any* grade, so look at what the current given grade is
                   # instead of trying to calculate it
                   given_grade
                 end
      else
        # there's not really any reasonable value we can set here -- if the
        # assignment is worth no points, and the grader didn't enter an
        # explicit letter grade, any letter grade is as valid as any other.
        result = grading_standard_or_default.score_to_grade(score.to_f)
      end
    end
    round_if_whole(result).to_s
  end

  def interpret_grade(grade, prefer_points_over_scheme: false)
    case grade.to_s
    when /^[+-]?\d*\.?\d+%$/
      # interpret as a percentage
      percentage = grade.to_f / BigDecimal("100.0")
      points_possible.to_f * percentage
    when /^[+-]?\d*\.?\d+$/
      if !prefer_points_over_scheme && uses_grading_standard && (standard_based_score = grading_standard_or_default.grade_to_score(grade))
        (points_possible || 0.0) * standard_based_score / 100.0
      else
        grade.to_f
      end
    when "pass", "complete"
      points_possible.to_f
    when "fail", "incomplete"
      0.0
    else
      # try to treat it as a letter grade
      if uses_grading_standard && (standard_based_score = grading_standard_or_default.grade_to_score(grade))
        ((points_possible || 0.0).to_d * standard_based_score.to_d / BigDecimal("100.0")).to_f
      else
        nil
      end
    end
  end

  def grade_to_score(grade = nil, prefer_points_over_scheme: false)
    return nil if grade.blank?

    parsed_grade = interpret_grade(grade, prefer_points_over_scheme:)
    case self.grading_type
    when *POINTED_GRADING_TYPES
      score = parsed_grade
    when "pass_fail"
      # only allow full points or no points for pass_fail assignments
      score = case parsed_grade.to_f
              when points_possible
                points_possible
              when 0.0
                0.0
              else
                nil
              end
    when "not_graded"
      score = nil
    else
      raise "oops, we need to interpret a new grading_type. get coding."
    end
    score
  end

  def uses_grading_standard
    ["letter_grade", "gpa_scale"].include? grading_type
  end

  def infer_times
    # set the time to 11:59 pm in the creator's time zone, if none given
    self.due_at = CanvasTime.fancy_midnight(due_at) if will_save_change_to_due_at?
    self.lock_at = CanvasTime.fancy_midnight(lock_at) if will_save_change_to_lock_at?
  end

  def infer_all_day(tz = nil)
    # make the comparison to "fancy midnight" and the date-part extraction in
    # the time zone that was active during editing
    time_zone = tz || (ActiveSupport::TimeZone.new(time_zone_edited) rescue nil) || Time.zone
    self.all_day, self.all_day_date = Assignment.all_day_interpretation(
      due_at: due_at&.in_time_zone(time_zone),
      due_at_was:,
      all_day_was:,
      all_day_date_was:
    )
  end

  def to_atom(opts = {})
    extend ApplicationHelper
    author_name = context.present? ? context.name : t("atom_no_author", "No Author")
    content = "#{before_label(:due, "Due")} #{datetime_string(due_at, :due_date)}"
    unless opts[:exclude_description]
      content += "<br/>#{description}<br/><br/>
        <div>
          #{description}
        </div>
      "
    end

    title = t(:feed_entry_title, "Assignment: %{assignment}", assignment: self.title) unless opts[:include_context]
    title = t(:feed_entry_title_with_course, "Assignment, %{course}: %{assignment}", assignment: self.title, course: context.name) if opts[:include_context]

    {
      title:,
      updated: updated_at.utc,
      published: created_at.utc,
      id: "tag:#{HostUrl.default_host},#{created_at.strftime("%Y-%m-%d")}:/assignments/#{feed_code}_#{due_at.strftime("%Y-%m-%d-%H-%M") rescue "none"}",
      content:,
      link: direct_link,
      author: author_name
    }
  end

  def start_at
    due_at
  end

  def end_at
    due_at
  end

  def direct_link
    "http://#{HostUrl.context_host(context)}/#{context_url_prefix}/assignments/#{id}"
  end

  def context_prefix
    context_url_prefix
  end

  def to_ics(in_own_calendar: true, preloaded_attachments: {}, user: nil)
    CalendarEvent::IcalEvent.new(self).to_ics(in_own_calendar:,
                                              preloaded_attachments:,
                                              include_description: include_description?(user))
  end

  def include_description?(user, lock_info = nil)
    return false unless user

    lock_info = locked_for?(user, check_policies: true) if lock_info.nil?
    !lock_info || (lock_info[:can_view] && !lock_info[:context_module])
  end

  def all_day
    read_attribute(:all_day) || (new_record? && !!due_at && (due_at.strftime("%H:%M") == "23:59" || due_at.strftime("%H:%M") == "00:00"))
  end

  def self.preload_context_module_tags(assignments, include_context_modules: false)
    module_tags_include =
      if include_context_modules
        { context_module_tags: :context_module }
      else
        :context_module_tags
      end

    ActiveRecord::Associations.preload(assignments, [
                                         module_tags_include,
                                         :context, # necessary while wiki_page assignments behind feature flag
                                         { discussion_topic: :context_module_tags },
                                         { wiki_page: :context_module_tags },
                                         { quiz: :context_module_tags }
                                       ])
  end

  def self.preload_unposted_anonymous_submissions(assignments)
    # Don't do anything if there are no assignments OR unposted anonymous submissions are already preloaded
    if assignments.is_a?(Array) &&
       (assignments.empty? || assignments.all? { |a| !a.unposted_anonymous_submissions.nil? })
      return
    end

    # Ignore test student enrollments so that adding a test student doesn't
    # inadvertently flip a posted anonymous assignment back to unposted
    assignment_ids_with_unposted_anonymous_submissions =
      Assignment
      .where(id: assignments, anonymous_grading: true)
      .where(Submission.active.unposted.joins(user: :enrollments)
            .where("submissions.user_id = users.id")
            .where("submissions.assignment_id = assignments.id")
            .where("enrollments.course_id = assignments.context_id")
            .merge(Enrollment.of_student_type.where(workflow_state: "active"))
            .arel.exists)
      .pluck(:id).to_set

    assignments.each do |assignment|
      assignment.unposted_anonymous_submissions = assignment_ids_with_unposted_anonymous_submissions.include?(assignment.id)
    end

    nil
  end

  def touch_on_unlock_if_necessary
    if unlock_at && Time.zone.now < unlock_at && 1.hour.from_now > unlock_at
      GuardRail.activate(:primary) do
        # Because of assignemnt overrides, an assignment can have the same global id but
        # a different unlock_at time, so include that in the singleton key so that different
        # unlock_at times are properly handled.
        singleton = "touch_on_unlock_assignment_#{global_id}_#{unlock_at}"
        delay(run_at: unlock_at, singleton:).touch_assignment_and_submittable
      end
    end
  end

  def touch_assignment_and_submittable
    touch
    submittable_object&.touch
    if submittable_object.is_a?(DiscussionTopic) && submittable_object.root_topic?
      submittable_object.child_topics.touch_all
    end
  end

  def low_level_locked_for?(user, opts = {})
    return false if opts[:check_policies] && context.grants_right?(user, :read_as_admin)

    RequestCache.cache(locked_request_cache_key(user)) do
      locked = false
      assignment_for_user = overridden_for(user)
      if assignment_for_user.unlock_at && assignment_for_user.unlock_at > Time.zone.now
        locked = { object: assignment_for_user, unlock_at: assignment_for_user.unlock_at }
      elsif could_be_locked && (item = locked_by_module_item?(user, opts))
        locked = { object: self, module: item.context_module }
      elsif assignment_for_user.lock_at && assignment_for_user.lock_at < Time.zone.now
        locked = { object: assignment_for_user, lock_at: assignment_for_user.lock_at, can_view: true }
      else
        each_submission_type do |submission, _, short_type|
          next unless send(:"#{short_type}?")

          if (submission_locked = submission.low_level_locked_for?(user, opts.merge(skip_assignment: true)))
            locked = submission_locked
          end
          break
        end
      end
      assignment_for_user.touch_on_unlock_if_necessary
      locked
    end
  end

  def self.assignment_type?(type)
    %w[quiz attendance discussion_topic wiki_page external_tool].include? type.to_s
  end

  def self.get_submission_type(assignment_type)
    if assignment_type?(assignment_type)
      type = assignment_type.to_s
      type = "online_quiz" if type == "quiz"
      type = type.to_sym if assignment_type.is_a?(Symbol)
      type
    end
  end

  def submission_types_array
    (self.submission_types || "").split(",")
  end

  def submittable_type?
    submission_types && ![
      "",
      "none",
      "not_graded",
      "online_quiz",
      "discussion_topic",
      "wiki_page",
      "attendance"
    ].include?(self.submission_types)
  end

  def submittable_object
    case self.submission_types
    when "online_quiz"
      quiz
    when "discussion_topic"
      discussion_topic
    when "wiki_page"
      wiki_page
    end
  end

  def each_submission_type
    if block_given?
      submittable_types = %i[discussion_topic quiz]
      submittable_types << :wiki_page if context.try(:conditional_release?)
      submittable_types.each do |asg_type|
        submittable = send(asg_type)
        yield submittable, Assignment.get_submission_type(asg_type), asg_type
      end
    end
  end

  def graded_count
    return read_attribute(:graded_count).to_i if read_attribute(:graded_count)

    Rails.cache.fetch(["graded_count", self].cache_key) do
      submissions.graded.in_workflow_state("graded").count
    end
  end

  def submitted?(user: nil, submission: nil)
    submission = submissions.find_by(user:) if submission.nil? && user.present?
    submission.present? && (non_digital_submission? || submission.has_submission?)
  end

  def has_submitted_submissions?
    return @has_submitted_submissions unless @has_submitted_submissions.nil?

    submitted_count > 0
  end
  attr_writer :has_submitted_submissions

  def submitted_count
    return read_attribute(:submitted_count).to_i if read_attribute(:submitted_count)

    Rails.cache.fetch(["submitted_count", self].cache_key) do
      submissions.having_submission.count
    end
  end

  set_policy do
    given { |user, session| context.grants_right?(user, session, :read) && published? }
    can :read and can :read_own_submission

    given do |user, session|
      (submittable_type? || submission_types == "discussion_topic") &&
        context.grants_right?(user, session, :participate_as_student) &&
        !locked_for?(user) &&
        visible_to_user?(user) &&
        !excused_for?(user)
    end
    can :submit

    given do |user, session|
      (submittable_type? || %w[discussion_topic online_quiz none not_graded].include?(submission_types)) &&
        context.grants_right?(user, session, :participate_as_student) &&
        visible_to_user?(user)
    end
    can :attach_submission_comment_files

    given { |user, session| context.grants_right?(user, session, :read_as_admin) }
    can :read

    given { |user, session| context.grants_right?(user, session, :manage_grades) }
    can :grade and
      can :attach_submission_comment_files and
      can :manage_files_add and
      can :manage_files_edit and
      can :manage_files_delete

    given do |user, session|
      !context.root_account.feature_enabled?(:granular_permissions_manage_assignments) &&
        context.grants_right?(user, session, :manage_assignments)
    end
    can :create and can :read

    given do |user, session|
      context.root_account.feature_enabled?(:granular_permissions_manage_assignments) &&
        context.grants_right?(user, session, :manage_assignments_add)
    end
    can :create and can :read

    given { |user, session| user_can_update?(user, session) }
    can :update

    given do |user, session|
      !context.root_account.feature_enabled?(:granular_permissions_manage_assignments) &&
        context.grants_right?(user, session, :manage_assignments) &&
        (context.account_membership_allows(user) ||
         !in_closed_grading_period?)
    end
    can :delete

    given do |user, session|
      context.root_account.feature_enabled?(:granular_permissions_manage_assignments) &&
        context.grants_right?(user, session, :manage_assignments_delete) &&
        (context.account_membership_allows(user) ||
         !in_closed_grading_period?)
    end
    can :delete
  end

  def user_can_update?(user, session = nil)
    return false unless context.grants_any_right?(user, session, :manage_assignments, :manage_assignments_edit)
    return true unless moderated_grading?

    # a moderated assignment may only be edited by the assignment's moderator (assuming one has
    # been specified) or by a user with the Select Final Grade permission.
    final_grader_id.blank? || context.grants_right?(user, :select_final_grade)
  end

  def user_can_read_grades?(user, session = nil)
    RequestCache.cache("user_can_read_grades", self, user, session) do
      context.grants_right?(user, session, :view_all_grades) ||
        (published? && context.grants_right?(user, session, :manage_grades))
    end
  end

  def filter_attributes_for_user(hash, user, _session)
    if (lock_info = locked_for?(user, check_policies: true))
      hash.delete("description") unless include_description?(user, lock_info)
      hash["lock_info"] = lock_info
    end
  end

  def participants(opts = {})
    return context.participants(opts) unless differentiated_assignments_applies?

    participants_with_visibility(opts)
  end

  def participants_with_visibility(opts = {})
    users = context.participating_admins

    student_scope = students_with_visibility(context.participating_students_by_date)
    student_scope = student_scope.where.not(id: opts[:excluded_user_ids]) if opts[:excluded_user_ids]
    applicable_students = student_scope.to_a
    users += applicable_students

    if opts[:include_observers]
      users += User.observing_students_in_course(applicable_students.map(&:id), context_id)
      users += User.observing_full_course(context.id)
    end

    users.uniq
  end

  def title_with_id
    "#{title} (#{id})"
  end

  def title_slug
    CanvasTextHelper.truncate_text(title, ellipsis: "")
  end

  def self.title_and_id(str)
    if str =~ /\A(.*)\s\((\d+)\)\z/
      [$1, $2]
    else
      [str, nil]
    end
  end

  def group_students(student)
    group = group_category.group_for(student) if has_group_category?
    students = if group
                 group.users
                      .joins(:enrollments)
                      .where(enrollments: { course_id: context })
                      .merge(Course.instance_exec(&Course.reflections["admin_visible_student_enrollments"].scope).only(:where))
                      .order("users.id") # this helps with preventing deadlock with other things that touch lots of users
                      .distinct
                      .to_a
               else
                 [student]
               end

    [group, students]
  end

  def multiple_module_actions(student_ids, action, points = nil)
    students = context.students.where(id: student_ids)
    students.each do |user|
      context_module_action(user, action, points)
    end
  end

  def assigned?(user)
    if association(:submissions).loaded?
      submissions.any? { |sub| sub.user_id == user.id }
    else
      submissions.where(user:).exists?
    end
  end

  def submission_for_student(user)
    submission_for_student_id(user.id)
  end

  def submission_for_student_id(user_id)
    all_submissions.where(user_id:).first_or_initialize
  end

  def compute_grade_and_score(grade, score, prefer_points_over_scheme: false)
    grade = nil if grade == ""

    if grade
      score = grade_to_score(grade, prefer_points_over_scheme:)
    end
    if score
      grade = score_to_grade(score, grade)
    end
    [grade, score]
  end

  def grade_student(original_student, opts = {})
    raise ::Assignment::GradeError, "Student is required" unless original_student
    unless context.includes_user?(original_student, context.admin_visible_student_enrollments) # allows inactive users to be graded
      raise ::Assignment::GradeError, "Student must be enrolled in the course as a student to be graded"
    end
    raise ::Assignment::GradeError, "Grader must be enrolled as a course admin" if opts[:grader] && !context.grants_right?(opts[:grader], :manage_grades)

    opts[:excused] = Canvas::Plugin.value_to_boolean(opts.delete(:excuse)) if opts.key? :excuse
    raise ::Assignment::GradeError, "Cannot simultaneously grade and excuse an assignment" if opts[:excused] && (opts[:grade] || opts[:score])
    raise ::Assignment::GradeError, "Provisional grades require a grader" if opts[:provisional] && opts[:grader].nil?

    opts.delete(:id)
    group, students = group_students(original_student)
    submissions = []
    grade_group_students = !(grade_group_students_individually || opts[:excused])

    if has_sub_assignments? && root_account&.feature_enabled?(:discussion_checkpoints)
      sub_assignment_tag = opts.delete(:sub_assignment_tag)
      checkpoint_assignment = find_checkpoint(sub_assignment_tag)
      if sub_assignment_tag.blank? || checkpoint_assignment.nil?
        raise ::Assignment::GradeError, "Must provide a valid sub assignment tag when grading checkpointed discussions"
      end

      checkpoint_submissions = checkpoint_assignment.grade_student(original_student, opts)
      parent_submissions = all_submissions.where(user_id: checkpoint_submissions.map(&:user_id))
      return parent_submissions.preload(:grading_period, :stream_item).to_a
    end

    # grading a student results in a teacher occupying a grader slot for that assignment if it is moderated.
    ensure_grader_can_adjudicate(grader: opts[:grader], provisional: opts[:provisional], occupy_slot: true) do
      if grade_group_students
        find_or_create_submissions(students, Submission.preload(:grading_period, :stream_item, :lti_result)) do |submission|
          submission.skip_grader_check = true if opts[:skip_grader_check]
          submission&.lti_result&.mark_reviewed!
          submissions << save_grade_to_submission(submission, original_student, group, opts)
        end
      else
        submission = find_or_create_submission(original_student, skip_grader_check: opts[:skip_grader_check])
        submission.skip_grader_check = true if opts[:skip_grader_check]
        submission&.lti_result&.mark_reviewed!
        submissions << save_grade_to_submission(submission, original_student, group, opts)
      end
    end

    submissions.compact
  end

  def tool_settings_resource_codes
    lookup = assignment_configuration_tool_lookups.first
    return {} unless lookup.present?

    lookup.resource_codes
  end

  def tool_settings_tool_name
    tool = tool_settings_tool
    return if tool.blank?
    if tool.instance_of? Lti::MessageHandler
      return tool_settings_tool.tool_proxy&.name
    end

    tool.name
  end

  def tool_settings_tool
    tool_settings_tools.first
  end

  def tool_settings_tool=(tool)
    self.tool_settings_tools = [tool] if tool_settings_tool != tool
  end

  def clear_tool_settings_tools
    assignment_configuration_tool_lookups.clear
  end

  def tool_settings_tools=(tools)
    clear_tool_settings_tools
    tools.each do |t|
      if t.instance_of? ContextExternalTool
        tool_settings_context_external_tools << t
      elsif t.instance_of? Lti::MessageHandler
        product_family = t.tool_proxy.product_family
        assignment_configuration_tool_lookups.new(
          tool_vendor_code: product_family.vendor_code,
          tool_product_code: product_family.product_code,
          tool_resource_type_code: t.resource_handler.resource_type_code,
          tool_type: "Lti::MessageHandler",
          context_type: t.tool_proxy.context_type
        )
      end
    end
  end
  protected :tool_settings_tools=

  def tool_settings_tools
    tool_settings_context_external_tools + tool_settings_message_handlers
  end
  protected :tool_settings_tools

  def tool_settings_message_handlers
    assignment_configuration_tool_lookups.where(tool_type: "Lti::MessageHandler").map(&:lti_tool)
  end
  private :tool_settings_message_handlers

  def associated_tool_proxy
    actl = assignment_configuration_tool_lookups.take
    actl&.associated_tool_proxy
  end

  def are_previous_versions_graded(submission)
    submission.versions.each do |versions|
      if versions.model.grade.present?
        return true
      end
    end
    false
  end

  def save_grade_to_submission(submission, original_student, group, opts)
    unless submission.grader_can_grade?
      error_details = submission.grading_error_message
      raise ::Assignment::GradeError.new("Cannot grade this submission at this time: #{error_details}", :forbidden)
    end

    submission.skip_grade_calc = opts[:skip_grade_calc]

    previously_graded = submission.grade.present? || submission.excused? || are_previous_versions_graded(submission)
    return if previously_graded && opts[:dont_overwrite_grade]
    return if submission.user != original_student && submission.excused?

    grader = opts[:grader]
    grade, score = compute_grade_and_score(opts[:grade], opts[:score], prefer_points_over_scheme: opts[:prefer_points_over_scheme])

    did_grade = false
    submission.attributes = opts.slice(:submission_type, :url, :body)

    # A moderated assignment cannot be assigned a score directly, but may be
    # (un)excused by a moderator or admin. Even though this isn't *really*
    # a grading action, it needs to be captured for auditing purposes.
    if !opts[:provisional] || permits_moderation?(grader)
      submission.grader = grader
      submission.excused = opts[:excused] && score.blank?
    end

    unless opts[:provisional]
      submission.grader = grader
      submission.grader_id = opts[:grader_id] if opts.key?(:grader_id)
      submission.grade = grade
      submission.graded_anonymously = opts[:graded_anonymously] if opts.key?(:graded_anonymously)
      submission.score = score

      changed_attributes = submission.changed_attributes
      # only mark excused changed if it was a changed attributes and did not go from nil -> false
      excused_changed = changed_attributes.key?(:excused) && !(changed_attributes[:excused].nil? && opts[:excused] == false)
      score_changed = changed_attributes.key?(:score)

      # return submission if excused did not change and score did not change
      if opts[:return_if_score_unchanged] && !excused_changed && !score_changed
        submission.score_unchanged = true
        return submission
      end

      did_grade = true if score.present? || submission.excused?
    end

    if did_grade
      submission.grade_matches_current_submission = true
      submission.regraded = true
      submission.graded_at = Time.zone.now
      submission.posted_at = submission.graded_at unless submission.posted_at.present? || post_manually?
    end
    submission.audit_grade_changes = did_grade || submission.excused_changed?

    if (submission.score_changed? ||
        submission.grade_matches_current_submission) &&
       ((submission.score && submission.grade) || submission.excused?)
      submission.workflow_state = "graded"
    end
    submission.group = group
    submission.grade_posting_in_progress = opts.fetch(:grade_posting_in_progress, false)
    previously_graded ? submission.with_versioning(explicit: true) { submission.save! } : submission.save!
    submission.audit_grade_changes = false

    if opts[:provisional]
      if !(score.present? || submission.excused) && opts[:grade] != ""
        raise ::Assignment::GradeError.new(error_code: ::Assignment::GradeError::PROVISIONAL_GRADE_INVALID_SCORE)
      end

      submission.find_or_create_provisional_grade!(
        grader,
        grade:,
        score:,
        force_save: true,
        final: opts[:final],
        graded_anonymously: opts[:graded_anonymously]
      )
    end

    submission
  end
  private :save_grade_to_submission

  def find_or_create_submission(user, skip_grader_check: false)
    Assignment.unique_constraint_retry do
      s = all_submissions.where(user_id: user).first
      unless s
        s = submissions.build
        user.is_a?(User) ? s.user = user : s.user_id = user
        s.skip_grader_check = true if skip_grader_check
        s.save!
      end
      s
    end
  end

  def find_or_create_submissions(students, relation = nil)
    submissions = all_submissions.where(user_id: students)
    submissions = submissions.merge(relation) if relation
    submissions_hash = submissions.to_a.index_by(&:user_id)
    submissions = []
    students.each do |student|
      submission = submissions_hash[student.id]
      if submission
        submission.assignment = self
        submission.user = student
        yield submission if block_given?
      else
        begin
          transaction(requires_new: true) do
            submission = self.submissions.build(user: student)
            submission.assignment = self
            yield submission if block_given?
            submission.without_versioning(&:save) if submission.changed?
          end
        rescue ActiveRecord::RecordNotUnique
          submission = all_submissions.where(user_id: student).first
          raise unless submission

          submission.assignment = self
          submission.user = student
          yield submission if block_given?
        end
      end
      submissions << submission
    end
    submissions
  end

  def find_asset_for_assessment(association, user_or_user_id, opts = {})
    user = user_or_user_id.is_a?(User) ? user_or_user_id : context.users.where(id: user_or_user_id).first
    if association.purpose == "grading"
      if user
        sub = find_or_create_submission(user)
        if opts[:provisional_grader]
          [sub.find_or_create_provisional_grade!(opts[:provisional_grader], final: opts[:final]), user]
        else
          [sub, user]
        end
      else
        [nil, nil]
      end
    else
      [self, user]
    end
  end

  def update_submission_runner(original_student, opts = {})
    raise "Student Required" unless original_student

    group, students = group_students(original_student)
    opts[:author] ||= opts[:commenter] || (opts[:user_id].present? && User.find_by(id: opts[:user_id]))
    res = {
      comments: [],
      submissions: []
    }

    if opts[:comment] && opts[:assessment_request] && !opts[:assessment_request].active_rubric_association?
      # if there is no rubric the peer review is complete with just a comment
      opts[:assessment_request].complete
    end

    # commenting on a student submission results in a teacher occupying a
    # grader slot for that assignment if it is moderated.
    ensure_grader_can_adjudicate(grader: opts[:author], provisional: opts[:provisional], occupy_slot: true) do
      if opts[:comment] && Canvas::Plugin.value_to_boolean(opts[:group_comment])
        uuid = CanvasSlug.generate_securish_uuid
        find_or_create_submissions(students) do |submission|
          res[:comments] << save_comment_to_submission(submission, group, opts, uuid)
          res[:submissions] << submission
        end
      else
        submission = find_or_create_submission(original_student)
        res[:comments] << save_comment_to_submission(submission, group, opts)
        res[:submissions] << submission
      end
    end
    res
  end
  private :update_submission_runner

  def add_submission_comment(original_student, opts = {})
    comments = update_submission_runner(original_student, opts)[:comments]
    comments.compact # Possible no comments were added depending on opts
  end

  # Update at this point is solely used for commenting on the submission
  def update_submission(original_student, opts = {})
    update_submission_runner(original_student, opts)[:submissions]
  end

  def save_comment_to_submission(submission, group, opts, uuid = nil)
    # Only teachers (those who can manage grades) can have hidden comments
    unless opts.key?(:hidden)
      opts[:hidden] = submission.hide_grade_from_student? && context.grants_right?(opts[:author], :manage_grades)
    end
    submission.group = group
    submission.save! if submission.changed?
    opts[:group_comment_id] = uuid if group && uuid
    comment = submission.add_comment(opts)
    submission.reload
    comment
  end
  private :save_comment_to_submission

  SUBMIT_HOMEWORK_ATTRS = %w[
    body url submission_type media_comment_id media_comment_type submitted_at
  ].freeze
  ALLOWABLE_SUBMIT_HOMEWORK_OPTS = (SUBMIT_HOMEWORK_ATTRS +
                                    %w[comment group_comment attachments require_submission_type_is_valid resource_link_lookup_uuid student_id]).to_set

  def submit_homework(original_student, opts = {})
    raise "Student Required" unless original_student

    eula_timestamp = opts[:eula_agreement_timestamp]
    webhook_info = assignment_configuration_tool_lookups.take&.webhook_info
    should_add_proxy = false

    if opts[:proxied_student]
      current_user = original_student
      original_student = opts[:proxied_student]
      should_add_proxy = true
    end

    if opts[:submission_type] == "student_annotation"
      raise "Invalid Attachment" if opts[:annotatable_attachment_id].blank?
      raise "Invalid submission type" unless annotated_document?
      # Prevent the case where a user clicks Submit on a stale tab, expecting
      # to submit one set of work, only for another set to be submitted
      # instead.
      raise "Invalid Attachment" if opts[:annotatable_attachment_id].to_i != annotatable_attachment_id
    end

    # Only allow a few fields to be submitted.  Cannot submit the grade of a
    # homework assignment, for instance.
    opts.each_key do |k|
      opts.delete(k) unless ALLOWABLE_SUBMIT_HOMEWORK_OPTS.include?(k.to_s)
    end

    comment = opts.delete(:comment)
    group_comment = opts.delete(:group_comment)
    group, students = group_students(original_student)
    homeworks = []
    primary_homework = nil

    homework_attributes = submission_attributes(opts, group)
    homework_submitted_at = opts[:submitted_at] || Time.zone.now

    # move the following 2 lines out of the trnx
    # make the trnx simpler. The trnx will have fewer locks and rollbacks.
    homework_lti_user_id_hash = students.to_h do |student|
      [student.global_id, Lti::Asset.opaque_identifier_for(student)]
    end
    submissions = find_or_create_submissions(students, Submission.preload(:grading_period)).sort_by(&:id)

    transaction do
      submissions.each do |homework|
        homework.require_submission_type_is_valid = opts[:require_submission_type_is_valid].present?

        # clear out attributes from prior submissions
        if opts[:submission_type].present?
          SUBMIT_HOMEWORK_ATTRS.each { |attr| homework[attr] = nil }
          homework.attachment_ids = nil
          homework.late_policy_status = nil
          homework.seconds_late_override = nil
          homework.proxy_submitter_id = nil
        end

        student_id = homework.user.global_id
        is_primary_student = student_id == original_student.global_id
        homework.grade_matches_current_submission = homework.score ? false : true
        homework.attributes = homework_attributes
        homework.submitted_at = homework_submitted_at
        homework.lti_user_id = homework_lti_user_id_hash[student_id]
        homework.turnitin_data[:eula_agreement_timestamp] = eula_timestamp if eula_timestamp.present?
        homework.resource_link_lookup_uuid = opts[:resource_link_lookup_uuid]
        homework.proxy_submitter = current_user if should_add_proxy

        if webhook_info
          homework.turnitin_data[:webhook_info] = webhook_info
        else
          homework.turnitin_data.delete(:webhook_info)
        end

        if annotated_document?
          annotation_context = homework.annotation_context(draft: true)
        end

        homework.with_versioning(explicit: (homework.submission_type != "discussion_topic")) do
          if group
            Submission.suspend_callbacks(:delete_submission_drafts!) do
              is_primary_student ? homework.broadcast_group_submission : homework.save_without_broadcasting!
            end
          else
            homework.save!
            annotation_context.update!(submission_attempt: homework.attempt) if annotation_context.present?
          end
        end
        homeworks << homework
        primary_homework = homework if is_primary_student
      end
    end
    homeworks.each do |homework|
      context_module_action(homework.student, homework.workflow_state.to_sym)
      next unless comment && (group_comment || homework == primary_homework)

      hash = { comment:, author: original_student }
      hash[:group_comment_id] = CanvasSlug.generate_securish_uuid if group_comment && group
      homework.add_comment(hash)
    end
    touch_context
    primary_homework
  end

  def submission_attributes(opts, group)
    submitted = case opts[:submission_type]
                when "online_text_entry"
                  opts[:body].present?
                when "online_url", "basic_lti_launch"
                  opts[:url].present?
                when "online_upload"
                  !opts[:attachments].empty?
                else
                  true
                end

    opts.merge({
                 attachment: nil,
                 processed: false,
                 workflow_state: submitted ? "submitted" : "unsubmitted",
                 group:
               })
  end

  def submissions_downloaded?
    submissions_downloads && submissions_downloads > 0
  end

  def serializable_hash(opts = {})
    super(opts.reverse_merge include_root: true)
  end

  def as_json(options = {})
    json = super(options)
    return json unless json

    if json["assignment"]
      # remove anything coming automatically from deprecated db column
      json["assignment"].delete("group_category")
      if group_category
        # put back version from association
        json["assignment"]["group_category"] = group_category.name
      end

      if json.dig("assignment", "rubric_association") && !active_rubric_association?
        json["assignment"].delete("rubric_association")
      end
    end

    if json["rubric_association"] && !active_rubric_association?
      json.delete("rubric_association")
    end

    json
  end

  def lti_safe_description
    description&.truncate(1000, omission: "... (truncated)")
  end

  def grades_published?
    !moderated_grading? || grades_published_at.present?
  end

  def sections_with_visibility(user)
    return context.active_course_sections unless differentiated_assignments_applies?

    visible_student_ids = visible_students_for_speed_grader(user:).map(&:id)
    context.active_course_sections.joins(:student_enrollments)
           .where(enrollments: { user_id: visible_student_ids, type: "StudentEnrollment" }).distinct.reorder("name")
  end

  # quiz submission versions are too expensive to de-serialize so we have to
  # cap the number we will do
  def too_many_qs_versions?(student_submissions)
    qs_ids = student_submissions.filter_map(&:quiz_submission_id)
    return false if qs_ids.empty?

    Version.shard(shard).from(Version
        .where(versionable_type: "Quizzes::QuizSubmission", versionable_id: qs_ids)
        .limit(QUIZ_SUBMISSION_VERSIONS_LIMIT)).count >= QUIZ_SUBMISSION_VERSIONS_LIMIT
  end

  # :including quiz submission versions won't work for records in the
  # database before namespace changes. This does a bulk pre-query to prevent
  # n+1 queries. replace this with an :include again after namespaced
  # polymorphic data is migrated
  def quiz_submission_versions(student_submissions, too_many_qs_versions)
    submissions_with_qs = student_submissions.select do |sub|
      quiz && sub.quiz_submission && !too_many_qs_versions
    end
    qs_versions = Version.where(versionable_type: "Quizzes::QuizSubmission",
                                versionable_id: submissions_with_qs.map(&:quiz_submission))
                         .order(:number)

    qs_versions.each_with_object({}) do |version, hash|
      hash[version.versionable_id] ||= []
      hash[version.versionable_id] << version
    end
  end

  def display_avatars?
    context.root_account.service_enabled?(:avatars) && !grade_as_group?
  end

  def grade_as_group?
    has_group_category? && !grade_group_students_individually?
  end

  # for group assignments, returns a single "student" for each
  # group's submission.  the students name will be changed to the group's
  # name.  for non-group assignments this just returns all visible users
  def representatives(user:, includes: [:inactive], group_id: nil, section_id: nil, ignore_student_visibility: false, &block)
    return visible_students_for_speed_grader(user:, includes:, group_id:, section_id:, ignore_student_visibility:) unless grade_as_group?

    submissions = self.submissions.to_a
    user_ids_with_submissions = submissions.select(&:has_submission?).to_set(&:user_id)
    user_ids_with_turnitin_data = if turnitin_enabled?
                                    submissions.reject { |s| s.turnitin_data.blank? }.to_set(&:user_id)
                                  else
                                    []
                                  end
    user_ids_with_vericite_data = if vericite_enabled?
                                    submissions
                                      .reject { |s| s.turnitin_data.blank? }
                                      .to_set(&:user_id)
                                  else
                                    []
                                  end
    # this only includes users with a submission who are unexcused
    user_ids_who_arent_excused = submissions.reject(&:excused?).to_set(&:user_id)

    enrollment_state =
      context.all_accepted_student_enrollments.pluck(:user_id, :workflow_state).to_h

    # prefer active over inactive, inactive over everything else
    enrollment_priority = { "active" => 1, "inactive" => 2 }
    enrollment_priority.default = 100

    visible_student_ids = visible_students_for_speed_grader(user:, includes:, ignore_student_visibility:).to_set(&:id)

    reps_and_others = groups_and_ungrouped(user, includes:).filter_map do |group_name, group_info|
      group_students = group_info[:users]
      visible_group_students = group_students.select { |u| visible_student_ids.include?(u.id) }

      candidate_students = visible_group_students.select { |u| user_ids_who_arent_excused.include?(u.id) }
      candidate_students = visible_group_students if candidate_students.empty?
      candidate_students.sort_by! { |s| [enrollment_priority[enrollment_state[s.id]], s.sortable_name, s.id] }

      representative   = candidate_students.detect { |u| user_ids_with_turnitin_data.include?(u.id) || user_ids_with_vericite_data.include?(u.id) }
      representative ||= candidate_students.detect { |u| user_ids_with_submissions.include?(u.id) }
      representative ||= candidate_students.first
      others = visible_group_students - [representative]
      next unless representative

      representative.readonly!
      representative.name = group_name
      representative.sortable_name = group_info[:sortable_name]
      representative.short_name = group_name

      [representative, others]
    end

    sorted_reps_with_others =
      Canvas::ICU.collate_by(reps_and_others) { |rep, _| rep.sortable_name }
    if block
      sorted_reps_with_others.each(&block)
    end
    sorted_reps_with_others.map(&:first)
  end

  def groups_and_ungrouped(user, includes: [])
    groups_and_users = group_category
                       .groups.active.preload(group_memberships: :user)
                       .map { |g| [g.name, { sortable_name: g.name, users: g.users }] }
    users_in_group = groups_and_users.flat_map { |_, group_info| group_info[:users] }
    groupless_users = visible_students_for_speed_grader(user:, includes:) - users_in_group
    phony_groups = groupless_users.map do |u|
      sortable_name = users_in_group.empty? ? u.sortable_name : u.name
      [u.name, { sortable_name:, users: [u] }]
    end
    groups_and_users + phony_groups
  end
  private :groups_and_ungrouped

  # using this method instead of students_with_visibility so we
  # can add the includes and students_visible_to/participating_students scopes.
  # group_id and section_id filters may optionally be supplied.
  def visible_students_for_speed_grader(user:, includes: [:inactive], group_id: nil, section_id: nil, ignore_student_visibility: false)
    @visible_students_for_speed_grader ||= {}
    @visible_students_for_speed_grader[[user.global_id, includes, group_id]] ||= begin
      student_scope = if user.present?
                        context.students_visible_to(user, include: includes)
                      else
                        context.participating_students
                      end

      student_scope = if ignore_student_visibility
                        student_scope.where(id: assigned_students)
                      else
                        students_with_visibility(student_scope)
                      end

      students = student_scope.order_by_sortable_name.distinct

      if group_id.present?
        students = students.joins(:group_memberships)
                           .where(group_memberships: { group_id:, workflow_state: :accepted })
      end

      if section_id.present?
        students = students.joins(:enrollments)
                           .where(enrollments: { course_section_id: section_id, workflow_state: includes + [:active] })
      end
      students.to_a
    end
  end
  private :visible_students_for_speed_grader

  def visible_rubric_assessments_for(user, opts = {})
    return [] unless user && active_rubric_association?

    scope = rubric_association.rubric_assessments.preload(:assessor)

    if opts[:provisional_grader]
      scope = scope.for_provisional_grades.where(assessor_id: user.id)
    elsif opts[:provisional_moderator]
      scope = scope.for_provisional_grades
    else
      scope = scope.for_submissions
      unless rubric_association.grants_any_right?(user, :manage, :view_rubric_assessments)
        scope = scope.where(assessor_id: user.id)
      end
    end
    scope.to_a.sort_by { |a| [(a.assessment_type == "grading") ? CanvasSort::First : CanvasSort::Last, Canvas::ICU.collation_key(a.assessor_name)] }
  end

  # Takes a zipped file full of assignment comments/annotated assignments
  # and generates comments on each assignment's submission.  Quietly
  # ignore (for now) files that don't make sense to us.  The convention
  # for file naming (how we're sending it down to the teacher) is
  # last_name_first_name_user_id_attachment_id.
  # extension
  def generate_comments_from_files_later(attachment_data, user, attachment_id = nil)
    progress = Progress.create!(context: self, tag: "submissions_reupload") do |p|
      p.user = user
    end

    if attachment_id.present?
      attachment = user.attachments.find_by(id: attachment_id)
    end

    attachment ||= user.attachments.create!(attachment_data)
    progress.process_job(self, :generate_comments_from_files, {}, attachment, user, progress)
    progress
  end

  def generate_comments_from_files(_, attachment, commenter, progress)
    file = attachment.open
    zip_extractor = ZipExtractor.new(file.path)
    # Creates a list of hashes, each one with a :user, :filename, and :submission entry.
    @ignored_files = []

    assignment_student_group_names = active_groups.pluck(:name).map { |group_name| sanitize_user_name(group_name) }

    file_map = zip_extractor.unzip_files.filter_map { |f| infer_comment_context_from_filename(f, assignment_student_group_names) }
    files_for_user = file_map.group_by { |f| f[:user] }

    comments = []

    files_for_user.each do |user, files|
      attachments = files.map do |g|
        FileInContext.attach(self, g[:filename], display_name: g[:display_name])
      end

      comment_attr = {
        comment: t(:comment_from_files, { one: "See attached file", other: "See attached files" }, count: files.size),
        author: commenter,
        attachments:,
      }

      group, students = group_students(user)
      comment_attr[:group_comment_id] = CanvasSlug.generate_securish_uuid if group

      find_or_create_submissions(students).each do |submission|
        hidden = submission.hide_grade_from_student?
        comments.push(submission.add_comment(comment_attr.merge(hidden:)))
      end
    end

    results = { comments: [], ignored_files: @ignored_files }

    comments.each do |comment|
      attachments = comment.attachments.map do |comment_attachment|
        {
          display_name: comment_attachment.display_name,
          filename: comment_attachment.filename,
          id: comment_attachment.id
        }
      end

      comment_submission = comment.submission
      submission = {
        user_id: comment_submission.user_id,
        user_name: comment_submission.user.name,
        anonymous_id: comment_submission.anonymous_id
      }

      results[:comments].push({
                                attachments:,
                                id: comment.id,
                                submission:
                              })
    end

    progress.set_results(results)
    attachment.destroy!
  end

  def submission_reupload_progress
    Progress.where(context_type: "Assignment", context_id: self, tag: "submissions_reupload").last
  end

  def has_group_category?
    group_category_id.present?
  end

  def assign_peer_review(reviewer, reviewee)
    reviewer_submission = find_or_create_submission(reviewer)
    reviewee_submission = find_or_create_submission(reviewee)
    reviewee_submission.assign_assessor(reviewer_submission)
  end

  def assign_peer_reviews
    return [] unless peer_review_count && peer_review_count > 0

    # there could be any conceivable configuration of peer reviews already
    # assigned when this method is called, since teachers can assign individual
    # reviews manually and change peer_review_count at any time. so we can't
    # make many assumptions. that's where most of the complexity here comes
    # from.
    peer_review_params = current_submissions_and_assessors
    res = []

    # for each submission that needs to do more assessments...
    # we sort the submissions randomly so that if there aren't enough
    # submissions still needing reviews, it's random who gets the duplicate
    # reviews.
    peer_review_params[:submissions].sort_by { rand }.each do |submission|
      existing = submission.assigned_assessments
      needed = peer_review_count - existing.size
      next if needed <= 0

      # candidate_set is all submissions for the assignment that this
      # submission isn't already assigned to review.
      candidate_set = current_candidate_set(peer_review_params, submission, existing)
      candidates = sorted_review_candidates(peer_review_params, submission, candidate_set)

      # pick the number needed
      assessees = candidates[0, needed]

      # if there aren't enough candidates, we'll just not assign as many as
      # peer_review_count would allow. this'll only happen if peer_review_count
      # >= the number of submissions.
      assessees.each do |to_assess|
        # make the assignment
        res << to_assess.assign_assessor(submission)
        peer_review_params[:assessor_id_map][to_assess.id] << submission.id
      end
    end

    # When all peer reviews have been assigned, indicate this on the assignment field.
    @next_auto_peer_review_date = next_auto_peer_review_date(Time.zone.now) if automatic_peer_reviews?
    unless @next_auto_peer_review_date
      self.peer_reviews_assigned = true
    end
    save
    res
  end

  def current_submissions_and_assessors
    # we track existing assessment requests, and the ones we create here, so
    # that we don't have to constantly re-query the db.
    student_ids = students_with_visibility(context.students.not_fake_student).pluck(:id)

    submissions = self.submissions.having_submission.include_assessment_requests
    submissions = submissions.due_in_past if automatic_peer_reviews? && peer_reviews_assign_at.blank?
    submissions = submissions.for_user(student_ids)

    { student_ids:,
      submissions:,
      submission_ids: Set.new(submissions.pluck(:id)),
      assessor_id_map: submissions.to_h { |s| [s.id, s.assessment_requests.map(&:assessor_asset_id)] } }
  end

  def sorted_review_candidates(peer_review_params, current_submission, candidate_set)
    assessor_id_map = peer_review_params[:assessor_id_map]
    candidates_for_review = peer_review_params[:submissions].select do |c|
      candidate_set.include?(c.id)
    end
    candidates_for_review.sort_by do |c|
      [
        # prefer those who need reviews done
        (assessor_id_map[c.id].count < peer_review_count) ? CanvasSort::First : CanvasSort::Last,
        # then prefer those who are not reviewing this submission
        assessor_id_map[current_submission.id].include?(c.id) ? CanvasSort::Last : CanvasSort::First,
        # then prefer those who need the most reviews done (that way we don't run the risk of
        # getting stuck with a submission needing more reviews than there are available reviewers left)
        assessor_id_map[c.id].count,
        # then prefer those who are assigned fewer reviews at this point --
        # this helps avoid loops where everybody is reviewing those who are
        # reviewing them, leaving the final assignee out in the cold.
        c.assigned_assessments.size,
        # random sort, all else being equal.
        rand,
      ]
    end
  end

  def current_candidate_set(peer_review_params, current_submission, existing)
    candidate_set = peer_review_params[:submission_ids] - existing.map(&:asset_id)
    # don't assign to ourselves
    candidate_set.delete(current_submission.id)

    if group_category_id && !intra_group_peer_reviews
      if current_submission.group_id
        # don't assign to our group partners (assuming we have a group)
        group_ids = peer_review_params[:submissions].select { |s| candidate_set.include?(s.id) && current_submission.group_id == s.group_id }.map(&:id)
        candidate_set -= group_ids
      end
    elsif discussion_topic? && discussion_topic.group_category_id
      child_topic = discussion_topic.child_topic_for(current_submission.user)
      if child_topic
        other_member_ids = child_topic.discussion_entries.except(:order).active.distinct.pluck(:user_id)
        candidate_set &= peer_review_params[:submissions].select { |s| other_member_ids.include?(s.user_id) }.map(&:id)
      end
      # only assign to other members in the group discussion
    end
    candidate_set
  end

  def next_auto_peer_review_date(current_auto_peer_review_date = nil)
    if current_auto_peer_review_date.present?
      auto_peer_review_dates.detect do |date|
        date > current_auto_peer_review_date
      end
    else
      auto_peer_review_dates.first
    end
  end

  def auto_peer_review_dates
    # When a date is specified for assigning peer reviews, that is the ONLY
    # date that should be used.
    return [peer_reviews_assign_at] if peer_reviews_assign_at.present?

    # When the `due_at` on the assignment applies to some assignees, it should
    # be used as one of the dates for automatic peer review assignment.
    dates = []
    dates.push(due_at) unless due_at.blank? || only_visible_to_overrides?

    # Each unique override date is likely a time at which peer reviews will
    # need to be assigned.
    override_dates = assignment_overrides
                     .active
                     .where(due_at_overridden: true)
                     .where.not(due_at: nil)
                     .distinct
                     .pluck(:due_at)

    # Return all of the unique dates from above in chronological order.
    (dates + override_dates).sort.uniq
  end

  # TODO: on a future deploy, rename the column peer_reviews_due_at
  # to peer_reviews_assign_at
  def peer_reviews_assign_at
    peer_reviews_due_at
  end

  def peer_reviews_assign_at=(val)
    write_attribute(:peer_reviews_due_at, val)
  end

  def has_peer_reviews?
    peer_reviews
  end

  scope :include_submitted_count, lambda {
                                    select(
                                      "assignments.*, (SELECT COUNT(*) FROM #{Submission.quoted_table_name}
    WHERE assignments.id = submissions.assignment_id
    AND submissions.submission_type IS NOT NULL
    AND submissions.workflow_state <> 'deleted') AS submitted_count"
                                    )
                                  }

  scope :include_graded_count, lambda {
                                 select(
                                   "assignments.*, (SELECT COUNT(*) FROM #{Submission.quoted_table_name}
    WHERE assignments.id = submissions.assignment_id
    AND submissions.grade IS NOT NULL
    AND submissions.workflow_state <> 'deleted') AS graded_count"
                                 )
                               }

  scope :include_submittables, -> { preload(:quiz, :discussion_topic, :wiki_page) }

  scope :submittable, -> { where.not(submission_types: [nil, *OFFLINE_SUBMISSION_TYPES]) }
  scope :no_submittables, -> { where.not(submission_types: SUBMITTABLE_TYPES) }

  scope :with_submissions, -> { preload(:submissions) }

  scope :not_hidden_in_gradebook, -> { where(hide_in_gradebook: false) }

  scope :with_submissions_for_user, lambda { |user|
    joins(:submissions).where(submissions: { user_id: user })
  }

  scope :starting_with_title, lambda { |title|
    where("title ILIKE ?", "#{title}%")
  }

  scope :having_submissions_for_user, lambda { |user|
    with_submissions_for_user(user).merge(Submission.having_submission)
  }

  scope :by_assignment_group_id, lambda { |group_id|
    where(assignment_group_id: group_id.to_s)
  }

  # assignments only ever belong to courses, so we can reduce this to just IDs to simplify the db query
  scope :for_context_codes, lambda { |codes|
    ids = codes.filter_map do |code|
      type, id = parse_asset_string(code)
      next unless type == "Course"

      id
    end
    next none if ids.empty?

    for_course(ids)
  }
  scope :for_course, ->(course_id) { where(context_type: "Course", context_id: course_id) }
  scope :for_group_category, ->(group_category_id) { where(group_category_id:) }

  scope :visible_to_students_in_course_with_da, lambda { |user_id, course_id|
    joins(:assignment_student_visibilities)
      .where(assignment_student_visibilities: { user_id:, course_id: })
  }

  # course_ids should be courses that restrict visibility based on overrides
  # ie: courses with differentiated assignments on or in which the user is not a teacher
  scope :filter_by_visibilities_in_given_courses, lambda { |user_ids, course_ids_that_have_da_enabled|
    if course_ids_that_have_da_enabled.blank?
      active
    else
      user_ids = Array.wrap(user_ids).join(",")
      course_ids = Array.wrap(course_ids_that_have_da_enabled).join(",")
      visibility_table = AssignmentStudentVisibility.table_name
      scope = joins(sanitize_sql([<<~SQL.squish, course_ids, user_ids]))
        LEFT OUTER JOIN #{AssignmentStudentVisibility.quoted_table_name} ON (
         #{visibility_table}.assignment_id = assignments.id
         AND #{visibility_table}.course_id IN (%s)
         AND #{visibility_table}.user_id IN (%s))
      SQL
      scope.where("(assignments.context_id NOT IN (?) AND assignments.workflow_state<>'deleted') OR (#{visibility_table}.assignment_id IS NOT NULL)", course_ids_that_have_da_enabled)
    end
  }

  scope :due_before, ->(date) { where("assignments.due_at<?", date) }

  scope :due_after, ->(date) { where("assignments.due_at>?", date) }
  scope :undated, -> { where(due_at: nil) }

  scope :with_just_calendar_attributes, lambda {
    select(((Assignment.column_names & CalendarEvent.column_names) + ["due_at", "assignment_group_id", "could_be_locked", "unlock_at", "lock_at", "submission_types", "(freeze_on_copy AND copied) AS frozen"] - ["cloned_item_id", "migration_id"]).join(", "))
  }

  scope :due_between, ->(start, ending) { where(due_at: start..ending) }

  # Return all assignments and their active overrides where either the
  # assignment or one of its overrides is due between start and ending.
  scope :due_between_with_overrides, lambda { |start, ending|
    overrides_subquery = AssignmentOverride.where("assignment_id=assignments.id")
                                           .where(due_at_overridden: true, due_at: start..ending)

    scope1 = where(due_at: start..ending)
    scope2 = where(overrides_subquery.arel.exists)
    if group_values.present?
      # subquery strategy doesn't work with GROUP BY
      scope1.or(scope2)
    else
      scope1.union(
        scope2.merge(unscoped.where.not(due_at: start..ending).or(unscoped.where(due_at: nil))),
        from: true
      )
    end
  }

  scope :due_between_for_user, lambda { |start, ending, user|
    with_user_due_date(user).where(user_due_date: start..ending)
  }

  scope :with_user_due_date, lambda { |user|
    from("(SELECT s.cached_due_date AS user_due_date, a.*
          FROM #{Assignment.quoted_table_name} a
          INNER JOIN #{Submission.quoted_table_name} AS s ON s.assignment_id = a.id
          WHERE s.user_id = #{User.connection.quote(user.id_for_database)} AND s.workflow_state <> 'deleted') AS assignments").select(arel.projections, "user_due_date")
  }

  scope :with_latest_due_date, lambda {
    from("(SELECT GREATEST(a.due_at, MAX(ao.due_at)) latest_due_date, a.*
          FROM #{Assignment.quoted_table_name} a
          LEFT JOIN #{AssignmentOverride.quoted_table_name} ao
          ON ao.assignment_id = a.id
          AND ao.due_at_overridden
          GROUP BY a.id) AS assignments").select(arel.projections, "latest_due_date")
  }

  scope :updated_after, lambda { |*args|
    if args.first
      where("assignments.updated_at IS NULL OR assignments.updated_at>?", args.first)
    else
      all
    end
  }

  scope :not_ignored_by, lambda { |user, purpose|
    where.not(Ignore.where(asset_type: "Assignment",
                           user_id: user,
                           purpose:).where("asset_id=assignments.id")
                       .arel.exists)
  }

  # This should only be used in the course drop down to show assignments needing a submission
  scope :need_submitting_info, lambda { |user_id, limit|
    chain = where("NOT EXISTS (SELECT 1 FROM #{Submission.quoted_table_name}
            WHERE assignment_id = assignments.id
            AND submissions.workflow_state <> 'deleted'
            AND (submission_type IS NOT NULL OR excused = ?)
            AND user_id = ?)",
                  true,
                  user_id)
            .limit(limit)
            .order("assignments.due_at")

    # select doesn't work with include() in rails3, and include(:context)
    # doesn't work because of the polymorphic association. So we'll preload
    # context for the assignments in a single query.
    chain.preload(:context)
  }

  scope :expecting_submission, lambda { |additional_excludes: []|
    where.not(submission_types: [nil, ""] + Array(additional_excludes) + %w[none not_graded on_paper wiki_page])
  }

  scope :gradeable, -> { where.not(submission_types: %w[not_graded wiki_page]) }

  scope :active, -> { where.not(workflow_state: "deleted") }
  scope :before, ->(date) { where("assignments.created_at<?", date) }

  scope :not_locked, lambda {
    where("(assignments.unlock_at IS NULL OR assignments.unlock_at<:now) AND (assignments.lock_at IS NULL OR assignments.lock_at>:now)",
          now: Time.zone.now)
  }

  scope :unpublished, -> { where(workflow_state: "unpublished") }
  scope :published, -> { where(workflow_state: "published") }

  scope :duplicating_for_too_long, lambda {
    where(
      "workflow_state = 'duplicating' AND duplication_started_at < ?",
      QUIZZES_NEXT_TIMEOUT.ago
    )
  }

  # Since we are sharing the duplication_started_at date field with the 'duplicating' workflow_state
  # we are adding twice the timeout to give it enough time to complete.
  scope :cloning_alignments_for_too_long, lambda {
    where(
      "workflow_state = 'outcome_alignment_cloning' AND duplication_started_at < ?",
      (Setting.get("quizzes_next_timeout_minutes", "15").to_i * 2).minutes.ago
    )
  }

  scope :importing_for_too_long, lambda {
    where(
      "workflow_state = 'importing' AND importing_started_at < ?",
      QUIZZES_NEXT_TIMEOUT.ago
    )
  }

  scope :migrating_for_too_long, lambda {
    where(
      "workflow_state = 'migrating' AND duplication_started_at < ?",
      QUIZZES_NEXT_TIMEOUT.ago
    )
  }

  scope :quiz_lti, lambda {
    type_quiz_lti.where(submission_types: "external_tool")
  }

  scope :with_important_dates, lambda {
    joins("LEFT JOIN #{AssignmentOverride.quoted_table_name} ON assignment_overrides.assignment_id=assignments.id")
      .where(important_dates: true)
      .where(
        "assignments.due_at IS NOT NULL OR (assignment_overrides.due_at IS NOT NULL AND assignment_overrides.due_at_overridden)"
      )
  }

  def overdue?
    due_at && due_at <= Time.zone.now
  end

  def readable_submission_types
    return nil unless expects_submission? || expects_external_submission?

    res = (self.submission_types || "").split(",").filter_map { |s| readable_submission_type(s) }
    res.to_sentence(:or)
  end

  def annotated_document?
    !!submission_types&.include?("student_annotation")
  end

  def readable_submission_type(submission_type)
    case submission_type
    when "online_quiz"
      t "submission_types.a_quiz", "a quiz"
    when "online_upload"
      t "submission_types.a_file_upload", "a file upload"
    when "online_text_entry"
      t "submission_types.a_text_entry_box", "a text entry box"
    when "online_url"
      t "submission_types.a_website_url", "a website url"
    when "student_annotation"
      t "student_annotation", "a student annotation"
    when "discussion_topic"
      t "submission_types.a_discussion_post", "a discussion post"
    when "wiki_page"
      t "submission_types.a_content_page", "a content page"
    when "media_recording"
      t "submission_types.a_media_recording", "a media recording"
    when "on_paper"
      t "submission_types.on_paper", "on paper"
    when "external_tool"
      t "submission_types.external_tool", "an external tool"
    else
      nil
    end
  end
  protected :readable_submission_type

  def expects_submission?
    submission_types.present? &&
      !expects_external_submission? &&
      !%w[none not_graded wiki_page].include?(submission_types)
  end

  def expects_external_submission?
    %w[on_paper external_tool].include?(submission_types)
  end

  def non_digital_submission?
    ["on_paper", "none", "not_graded", ""].include?(submission_types.strip)
  end

  def allow_google_docs_submission?
    submission_types&.include?("online_upload")
  end

  def <=>(comparable)
    sort_key <=> comparable.sort_key
  end

  def sort_key
    # undated assignments go last
    [due_at || CanvasSort::Last, Canvas::ICU.collation_key(title)]
  end

  def special_class
    nil
  end

  def submission_action_string
    if submission_types == "online_quiz"
      t(:submission_action_take_quiz, "Take %{title}", title:)
    elsif graded? && expects_submission?
      t(:submission_action_turn_in_assignment, "Turn in %{title}", title:)
    else
      t "Complete %{title}", title:
    end
  end

  # Infers the user, submission, and attachment from a filename
  def infer_comment_context_from_filename(fullpath, student_group_names = [])
    filename = File.basename(fullpath)
    # If the filename is like Richards_David_2_link.html, then there is no
    # useful attachment here.  The assignment was submitted as a URL and the
    # teacher commented directly with the gradebook.  Otherwise, grab that
    # last value and strip off everything after the first period.

    # remove group name from file name
    matched_group_name = student_group_names.find { |group_name| filename.match?(/^#{Regexp.quote(group_name)}_/) }
    if matched_group_name
      filename.sub!(/^#{Regexp.quote(matched_group_name)}_/, "")
    end

    split_filename = filename.split("_") - ["LATE"]

    attachment_id, user, submission = nil
    if split_filename.first == "anon"
      anon_id, attachment_id = split_filename[1, 2]
      submission = Submission.active.where(assignment_id: self, anonymous_id: anon_id).first
      user = submission&.user
    else
      # Expecting all context id from file name to be in the end not counting
      # uploaded_filename in case the file has number as name
      user_id, attachment_id = split_filename.grep(/^\d+$/).take(2)
      if user_id
        user = User.where(id: user_id).first
        submission = Submission.active.where(user_id:, assignment_id: self).first
      end
    end

    attachment_id = nil if split_filename.last =~ /^link/ || filename =~ /^\._/
    attachment = Attachment.where(id: attachment_id).first if attachment_id

    if !attachment || !submission ||
       !attachment.grants_right?(user, :read) ||
       !submission.attachments.where(id: attachment_id).exists?
      @ignored_files << fullpath
      return nil
    end

    {
      user:,
      submission:,
      filename: fullpath,
      display_name: attachment.display_name
    }
  end
  protected :infer_comment_context_from_filename

  FREEZABLE_ATTRIBUTES = %w[title
                            description
                            lock_at
                            points_possible
                            grading_type
                            submission_types
                            assignment_group_id
                            allowed_extensions
                            group_category_id
                            notify_of_update
                            peer_reviews
                            workflow_state].freeze
  def frozen?
    !!(freeze_on_copy && copied &&
       PluginSetting.settings_for_plugin(:assignment_freezer))
  end

  # indicates complete frozenness for an assignment.
  # if the user can edit at least one of the attributes, it is not frozen to
  # them
  def frozen_for_user?(user)
    return true if user.blank?

    frozen? && !context.grants_right?(user, :manage_frozen_assignments)
  end

  def frozen_attributes_for_user(user)
    FREEZABLE_ATTRIBUTES.select do |freezable_attribute|
      att_frozen? freezable_attribute, user
    end
  end

  def att_frozen?(att, user = nil)
    return false unless frozen?

    if (settings = PluginSetting.settings_for_plugin(:assignment_freezer)) && Canvas::Plugin.value_to_boolean(settings[att.to_s])
      if user
        return !context.grants_right?(user, :manage_frozen_assignments)
      else
        return true
      end
    end

    false
  end

  def can_copy?(user)
    !att_frozen?("no_copying", user)
  end

  def frozen_atts_not_altered
    return if copying

    FREEZABLE_ATTRIBUTES.each do |att|
      next unless changes[att] && att_frozen?(att, @updating_user)

      errors.add(att,
                 t("errors.cannot_save_att",
                   "You don't have permission to edit the locked attribute %{att_name}",
                   att_name: att))
    end
  end

  # Suspend any callbacks that could lead to SubmissionLifecycleManager running.  This means, for now, the
  # update_cached_due_dates callbacks on:
  # * Assignment
  # * AssignmentOverride and
  # * AssignmentOverrideStudent
  def self.suspend_due_date_caching(&)
    AbstractAssignment.suspend_callbacks(:update_cached_due_dates) do
      AssignmentOverride.suspend_callbacks(:update_cached_due_dates) do
        AssignmentOverrideStudent.suspend_callbacks(:update_cached_due_dates, &)
      end
    end
  end

  # Suspend callbacks that recalculate grading period grades
  def self.suspend_grading_period_grade_recalculation(&)
    AbstractAssignment.suspend_callbacks(:update_grading_period_grades) do
      AssignmentOverride.suspend_callbacks(:update_grading_period_grades, &)
    end
  end

  def self.suspend_due_date_caching_and_score_recalculation(&)
    suspend_due_date_caching do
      suspend_grading_period_grade_recalculation(&)
    end
  end

  def update_cached_due_dates
    return unless update_cached_due_dates?

    clear_cache_key(:availability)
    quiz.clear_cache_key(:availability) if quiz?

    unless saved_by == :migration
      saved_changes.slice(:due_at, :workflow_state, :only_visible_to_overrides, :anonymous_grading).inspect
      SubmissionLifecycleManager.recompute(self, update_grades: true)
    end
  end

  def update_cached_due_dates?
    new_record? || just_created ||
      will_save_change_to_due_at? || saved_change_to_due_at? ||
      will_save_change_to_workflow_state? || saved_change_to_workflow_state? ||
      will_save_change_to_only_visible_to_overrides? ||
      saved_change_to_only_visible_to_overrides? ||
      will_save_change_to_moderated_grading? || saved_change_to_moderated_grading? ||
      will_save_change_to_anonymous_grading? || saved_change_to_anonymous_grading?
  end

  def update_due_date_smart_alerts
    unless saved_by == :migration
      if due_at.nil? || due_at < Time.zone.now
        ScheduledSmartAlert.find_by(context_type: self.class.name, context_id: id, alert_type: :due_date_reminder)&.destroy
      else
        ScheduledSmartAlert.upsert(
          context_type: self.class.name,
          context_id: id,
          alert_type: :due_date_reminder,
          due_at:,
          root_account_id: root_account.id
        )
      end
    end
  end

  def apply_late_policy
    return if update_cached_due_dates? # SubmissionLifecycleManager already re-applies late policy so we shouldn't
    return unless saved_change_to_grading_type?

    LatePolicyApplicator.for_assignment(self)
  end

  def gradeable?
    submission_types != "not_graded" && submission_types != "wiki_page"
  end
  alias_method :graded?, :gradeable?

  def gradeable_was?
    submission_types_was != "not_graded" && submission_types_was != "wiki_page"
  end

  def active?
    workflow_state != "deleted"
  end

  def available?
    if Rails.env.production?
      published?
    else
      raise "Assignment#available? is deprecated. Use #published?"
    end
  end

  def has_student_submissions?
    if !@has_student_submissions.nil?
      @has_student_submissions
    elsif attribute_present? :student_submission_count
      student_submission_count.to_i > 0
    else
      submissions.having_submission.where.not(user_id: nil).exists?
    end
  end
  attr_writer :has_student_submissions

  def group_category_deleted_with_submissions?
    group_category.try(:deleted_at?) && has_student_submissions?
  end

  def self.with_student_submission_count
    # need to make sure that Submission's table name is relative to the shard
    # this query will execute on
    all.primary_shard.activate do
      joins("LEFT OUTER JOIN #{Submission.quoted_table_name} s ON
             s.assignment_id = assignments.id AND
             s.submission_type IS NOT NULL AND
             s.workflow_state <> 'deleted'")
        .group("assignments.id")
        .select("assignments.*, count(s.assignment_id) AS student_submission_count")
    end
  end

  def needs_grading_count
    Assignments::NeedsGradingCountQuery.new(self).manual_count
  end

  def can_publish?
    return true if new_record?

    ["unpublished", "published"].include?(workflow_state)
  end

  def can_unpublish?
    return true if new_record?
    return @can_unpublish unless @can_unpublish.nil?

    @can_unpublish = !has_student_submissions?
  end
  attr_writer :can_unpublish

  def self.preload_can_unpublish(assignments, assmnt_ids_with_subs = nil)
    return unless assignments.any?

    assmnt_ids_with_subs ||= assignment_ids_with_submissions(assignments.map(&:id))
    assignments.each { |a| a.can_unpublish = !assmnt_ids_with_subs.include?(a.id) }
  end

  def self.assignment_ids_with_submissions(assignment_ids)
    Submission.from(sanitize_sql(["unnest('{?}'::int8[]) as subs (assignment_id)", assignment_ids]))
              .where(Submission.active.having_submission.where("submissions.assignment_id=subs.assignment_id").arel.exists)
              .distinct.pluck("subs.assignment_id")
  end

  # override so validations are called
  def publish
    self.workflow_state = "published"
    save
  end

  # override so validations are called
  def unpublish
    self.workflow_state = "unpublished"
    save
  end

  def unmute!
    return unless muted?
    return super unless !grades_published? && anonymous_grading?

    errors.add :muted, I18n.t("Anonymous moderated assignments cannot be unmuted until grades are posted")
    false
  end

  def excused_for?(user)
    s = submissions.where(user_id: user.id).first_or_initialize
    s.excused?
  end

  def in_closed_grading_period?
    return @in_closed_grading_period unless @in_closed_grading_period.nil?

    @in_closed_grading_period = if !context.grading_periods?
                                  false
                                elsif submissions.loaded?
                                  # no need to check grading_periods are loaded because of
                                  # submissions association preload(:grading_period)

                                  submissions_in_closed_gp = submissions.select do |submission|
                                    submission.grading_period.present? &&
                                      submission.grading_period.workflow_state == "active" &&
                                      submission.grading_period.closed?
                                  end

                                  return false if submissions_in_closed_gp.blank?

                                  # Only submissions from currently-enrolled students count when determining
                                  # whether this assignment has submissions in a closed grading period
                                  # (the student_enrollments scope returns only active students)
                                  course.student_enrollments
                                        .where(user_id: submissions_in_closed_gp.map(&:user_id))
                                        .exists?
                                else
                                  submissions.active
                                             .joins(:grading_period, { user: :enrollments })
                                             .merge(GradingPeriod.active.closed)
                                             .where(users: { enrollments: { course:, type: "StudentEnrollment" } })
                                             .merge(Enrollment.active_or_pending)
                                             .exists?
                                end
  end

  # simply versioned models are always marked new_record, but for our purposes
  # they are not new. this ensures that assignment override caching works as
  # intended for versioned assignments
  def cache_key(*)
    new_record = @new_record
    @new_record = false if @simply_versioned_version_model
    super
  ensure
    @new_record = new_record if @simply_versioned_version_model
  end

  def supports_grade_by_question?
    return true if quiz.present?

    Account.site_admin.feature_enabled?(:new_quizzes_grade_by_question_in_speedgrader) && quiz_lti?
  end

  def quiz?
    submission_types == "online_quiz" && quiz.present?
  end

  def quiz_lti?
    external_tool? && !!external_tool_tag&.content&.try(:quiz_lti?)
  end

  def quiz_lti!
    setup_valid_quiz_lti_settings!
    tool = context.present? && context.quiz_lti_tool
    return unless tool

    self.submission_types = "external_tool"
    self.external_tool_tag_attributes = { content: tool, url: tool.url }
  end

  def discussion_topic?
    submission_types == "discussion_topic" && discussion_topic.present?
  end

  def wiki_page?
    submission_types == "wiki_page" && wiki_page.present?
  end

  def self.sis_grade_export_enabled?(context)
    context.feature_enabled?(:post_grades) ||
      Lti::AppLaunchCollator.any?(context, [:post_grades])
  end

  def run_if_overrides_changed!(student_ids = nil, updating_user = nil)
    relocked_modules = []
    relock_modules!(relocked_modules, student_ids)
    each_submission_type { |submission| submission&.relock_modules!(relocked_modules, student_ids) }

    update_grades = only_visible_to_overrides?

    SubmissionLifecycleManager.recompute(self, update_grades:, executing_user: updating_user)
  end

  def run_if_overrides_changed_later!(student_ids: nil, updating_user: nil)
    return if self.class.suspended_callback?(:update_cached_due_dates, :save)

    clear_cache_key(:availability)
    quiz.clear_cache_key(:availability) if quiz?

    enqueuing_args = if student_ids
                       { strand: "assignment_overrides_changed_for_students_#{global_id}" }
                     else
                       { singleton: "assignment_overrides_changed_#{global_id}" }
                     end

    delay_if_production(**enqueuing_args).run_if_overrides_changed!(student_ids, updating_user)
  end

  def validate_overrides_for_sis(overrides)
    unless AssignmentUtil.sis_integration_settings_enabled?(context) && AssignmentUtil.due_date_required_for_account?(context)
      @skip_sis_due_date_validation = true
      return
    end
    raise ActiveRecord::RecordInvalid unless assignment_overrides_due_date_ok?(overrides)

    @skip_sis_due_date_validation = true
  end

  def lti_resource_link_id
    return nil if external_tool_tag.blank?

    ContextExternalTool.opaque_identifier_for(external_tool_tag, shard)
  end

  def permits_moderation?(user)
    return false unless user

    final_grader_id == user.id || context.account_membership_allows(user, :select_final_grade)
  end

  def available_moderators
    moderators = course.moderators
    return moderators if final_grader_id.blank?

    # This captures scenarios where a user is selected as the final grader
    # for an assignment, and then afterwards they are deactivated or concluded,
    # or their 'Select Final Grade' permission is revoked. In these cases, we
    # still want to keep that user as the moderator for the assignment (even
    # though that user will not be included in the course.moderators list)
    # because a workflow state (excluding a change to 'deleted') or permission
    # change should have no bearing on their moderator status (this is a
    # product decision).
    moderators << final_grader if moderators.exclude?(final_grader)
    moderators
  end

  def provisional_moderation_graders
    if final_grader_id.present?
      moderation_graders.with_slot_taken.where.not(user_id: final_grader_id)
    else
      moderation_graders.with_slot_taken
    end
  end

  def ordered_moderation_graders_with_slot_taken
    moderation_graders.with_slot_taken.order(:anonymous_id)
  end

  def moderation_grader_users_with_slot_taken
    User.joins(
      "INNER JOIN #{ModerationGrader.quoted_table_name} ON moderation_graders.user_id = users.id"
    ).merge(moderation_graders.with_slot_taken)
  end

  def anonymous_grader_identities_by_user_id
    # Response looks like: { user_id => { id: anonymous_id, name: anonymous_name } }
    @anonymous_grader_identities_by_user_id ||= anonymous_grader_identities(index_by: :user_id)
  end

  def anonymous_grader_identities_by_anonymous_id
    # Response looks like: { anonymous_id => { id: anonymous_id, name: anonymous_name } }
    @anonymous_grader_identities_by_anonymous_id ||= anonymous_grader_identities(index_by: :anonymous_id)
  end

  def instructor_selectable_states_by_provisional_grade_id
    @instructor_selectable_states_by_provisional_grade_id ||= instructor_selectable_states
  end

  def moderated_grader_limit_reached?
    moderated_grading? && provisional_moderation_graders.count >= grader_count
  end

  def can_be_moderated_grader?(user)
    return false unless context.grants_any_right?(user, :manage_grades, :view_all_grades)
    return true unless moderated_grader_limit_reached?

    # Final grader can always be a moderated grader, and existing moderated graders can re-grade
    final_grader_id == user.id || provisional_moderation_graders.where(user:).exists?
  end

  def can_view_speed_grader?(user)
    context.allows_speed_grader? && context.grants_any_right?(user, :manage_grades, :view_all_grades)
  end

  def can_view_audit_trail?(user)
    auditable? && !muted? && grades_published? && context.grants_right?(user, :view_audit_trail)
  end

  def can_view_other_grader_identities?(user)
    return false unless context.grants_any_right?(user, :manage_grades, :view_all_grades)
    return true unless moderated_grading? && !grades_published?

    return grader_names_visible_to_final_grader? if final_grader_id == user.id
    return true if context.account_membership_allows(user, :select_final_grade)
    return false unless grader_comments_visible_to_graders?

    !graders_anonymous_to_graders?
  end

  def can_view_other_grader_comments?(user)
    return false unless context.grants_any_right?(user, :manage_grades, :view_all_grades)
    return true unless moderated_grading?

    return true if final_grader_id == user.id || context.account_membership_allows(user, :select_final_grade)

    grader_comments_visible_to_graders?
  end

  # This only checks whether this assignment allows score statistics to be shown.
  # You must also check submission.eligible_for_showing_score_statistics
  def can_view_score_statistics?(user)
    # The assignment must have points_possible > 0,
    return false unless points_possible.present? && points_possible > 0

    # Students can only see statistics when count >= 5 and not disabled by the instructor
    # Instructor can see statistics at any time.
    count = score_statistic&.count || 0
    context.grants_right?(user, :read_as_admin) || (count >= 5 && !context.hide_distribution_graphs)
  end

  def grader_ids_to_anonymous_ids
    @grader_ids_to_anonymous_ids ||= moderation_graders.each_with_object({}) do |grader, map|
      map[grader.user_id.to_s] = grader.anonymous_id
    end
  end

  # If you're going to be checking this for multiple assignments, you may want
  # to call .preload_unposted_anonymous_submissions on the lot of them first
  def anonymize_students?
    return false unless anonymous_grading?

    # Only anonymize students for moderated assignments if grades have not been published.
    return !grades_published? if moderated_grading?

    # Otherwise, only anonymize students if there's at least one active student with
    # an unposted submission.
    unposted_anonymous_submissions?
  end
  alias_method :anonymize_students, :anonymize_students?

  def unposted_anonymous_submissions?
    Assignment.preload_unposted_anonymous_submissions([self]) unless defined? @unposted_anonymous_submissions
    @unposted_anonymous_submissions
  end

  def can_view_student_names?(user)
    return false if anonymize_students?

    context.grants_any_right?(user, :manage_grades, :view_all_grades)
  end

  def create_moderation_grader(user, occupy_slot:)
    ensure_moderation_grader_slot_available(user) if occupy_slot

    existing_anonymous_ids = moderation_graders.pluck(:anonymous_id)
    new_anonymous_id = Anonymity.generate_id(existing_ids: existing_anonymous_ids)
    moderation_graders.create!(user:, anonymous_id: new_anonymous_id, slot_taken: occupy_slot)
  end

  def user_is_moderation_grader?(user)
    moderation_grader_users.where(id: user).exists?
  end

  # This is a helper method intended to ensure the number of provisional graders
  # for a moderated assignment doesn't exceed the prescribed maximum. Currently,
  # it is used for submitting grades, comments, and rubrics via SpeedGrader.
  # If the assignment is not moderated or the item is not provisional, this
  # method will simply execute the provided block without any additional checks.
  def ensure_grader_can_adjudicate(grader:, provisional: false, occupy_slot:)
    unless provisional && moderated_grading?
      yield if block_given?
      return
    end

    Assignment.transaction do
      # If we can't add a new grader, this will raise an error and abort
      # the transaction.
      moderation_grader = moderation_graders.find_by(user: grader)
      if moderation_grader.nil?
        create_moderation_grader(grader, occupy_slot:)
        filled_available_slot = occupy_slot
      elsif moderation_grader.slot_taken != occupy_slot
        if occupy_slot
          ensure_moderation_grader_slot_available(grader)
          filled_available_slot = true
        end
        moderation_grader.update!(slot_taken: occupy_slot)
      end

      yield if block_given?

      # If we added a grader, attempt to handle a potential race condition:
      # multiple new graders could have tried to add themselves simultaneously
      # when there weren't enough slots open for all of them. If we ended up
      # with too many provisional graders, throw an error to roll things back.
      if filled_available_slot && provisional_moderation_graders.count > grader_count
        raise ::Assignment::MaxGradersReachedError
      end
    end
  end

  def effective_post_policy
    post_policy || course.default_post_policy
  end

  def post_manually?
    !!effective_post_policy&.post_manually?
  end

  def post_submissions(progress: nil, submission_ids: nil, skip_updating_timestamp: false, posting_params: nil, skip_muted_changed: false, skip_content_participation_refresh: true)
    submissions = if submission_ids.nil?
                    self.submissions.active
                  else
                    self.submissions.active.where(id: submission_ids)
                  end
    return if submissions.blank?

    submission_and_user_ids = submissions.pluck(:id, :user_id)
    submission_ids = submission_and_user_ids.map(&:first)
    user_ids = submission_and_user_ids.map(&:second)

    User.clear_cache_keys(user_ids, :submissions)
    unless skip_updating_timestamp
      update_time = Time.zone.now
      # broadcast_notifications will reload each submission individually; this
      # cuts down on unneeded work when possible. This makes the assumption
      # that only unposted submissions need notifications.
      previously_unposted_submissions = submissions.unposted.to_a
      submissions.update_all(posted_at: update_time, updated_at: update_time)

      previously_unposted_submissions.each do |submission|
        submission.grade_posting_in_progress = true
        submission.broadcast_notifications
        submission.grade_posting_in_progress = false
      end
    end

    submissions.in_workflow_state("graded").each(&:assignment_muted_changed) unless skip_muted_changed

    show_stream_items(submissions:)
    course.recompute_student_scores(submissions.pluck(:user_id))
    update_muted_status!
    delay_if_production.recalculate_module_progressions(submission_ids)

    unless skip_content_participation_refresh
      previously_unposted_submission_ids = previously_unposted_submissions.map(&:id)
      previously_unposted_submission_ids.each_slice(1000) do |submission_id_slice|
        ContentParticipation
          .where(content_type: "Submission", content_id: submission_id_slice, content_item: "grade", workflow_state: "read")
          .update_all(workflow_state: "unread")
      end
      course.refresh_content_participation_counts_for_users(user_ids)
    end

    progress.set_results(assignment_id: id, posted_at: update_time, user_ids:) if progress.present?
    broadcast_submissions_posted(posting_params) if posting_params.present?
  end

  def hide_submissions(progress: nil, submission_ids: nil, skip_updating_timestamp: false, skip_muted_changed: false, skip_content_participation_refresh: true)
    submissions = if submission_ids.nil?
                    self.submissions.active
                  else
                    self.submissions.active.where(id: submission_ids)
                  end
    return if submissions.blank?

    user_ids = submissions.pluck(:user_id)

    User.clear_cache_keys(user_ids, :submissions)
    submissions.update_all(posted_at: nil, updated_at: Time.zone.now) unless skip_updating_timestamp
    submissions.in_workflow_state("graded").each(&:assignment_muted_changed) unless skip_muted_changed
    course.refresh_content_participation_counts_for_users(user_ids) unless skip_content_participation_refresh
    hide_stream_items(submissions:)
    course.recompute_student_scores(submissions.pluck(:user_id))
    update_muted_status!
    progress.set_results(assignment_id: id, posted_at: nil, user_ids:) if progress.present?
  end

  def broadcast_submissions_posted(posting_params)
    @posting_params_for_notifications = posting_params
    broadcast_notifications
    @posting_params_for_notifications = nil
  end

  def ensure_post_policy(post_manually:)
    # Anonymous assignments can never be set to automatically posted
    return if anonymous_grading? && !post_manually

    build_post_policy(course:) if post_policy.blank?
    post_policy.update!(post_manually:)
  end

  def a2_enabled?
    return false unless course.feature_enabled?(:assignments_2_student)
    return false if quiz? || discussion_topic? || wiki_page?
    return false if peer_reviews? && !course.feature_enabled?(:peer_reviews_for_a2)
    return false if external_tool? && !Account.site_admin.feature_enabled?(:external_tools_for_a2)

    true
  end

  def self.disable_post_to_sis_if_grading_period_closed
    eligible_root_accounts = Account.root_accounts.active.select do |account|
      account.feature_enabled?(:disable_post_to_sis_when_grading_period_closed) &&
        account.feature_enabled?(:new_sis_integrations) &&
        account.disable_post_to_sis_when_grading_period_closed?
    end
    return unless eligible_root_accounts.any?

    # This method is currently set to be called every 5 minutes, but check for
    # grading periods that have closed within a somewhat larger interval to
    # avoid "missing" a given period if the periodic job doesn't run for a while.
    now = Time.zone.now
    GradingPeriod.active.joins(:grading_period_group)
                 .where(close_date: 1.hour.ago(now)..now)
                 .where(grading_period_groups: { root_account: eligible_root_accounts }).find_each do |gp|
      gp.delay(
        singleton: "disable_post_to_sis_on_grading_period_#{gp.global_id}",
        n_strand: ["Assignment#disable_post_to_sis_if_grading_period_closed", Shard.global_id_for(gp.root_account_id)]
      ).disable_post_to_sis
    end
  end

  def self.from_secure_lti_params(secure_params)
    lti_context_id = Lti::Security.decoded_lti_assignment_id(secure_params)
    return nil if lti_context_id.blank?

    find_by(lti_context_id:)
  end

  def active_rubric_association?
    !!rubric_association&.active?
  end

  def can_reassign?(grader)
    (final_grader_id.nil? || final_grader_id == grader.id) && context.grants_right?(grader, :manage_grades)
  end

  def accepts_submission_type?(submission_type)
    if submission_type == "basic_lti_launch"
      submission_types =~ /online|external_tool/
    else
      submission_types_array.include?(submission_type)
    end
  end

  def anonymous_student_identities
    @anonymous_student_identities ||= all_submissions.active.order(Arel.sql('anonymous_id COLLATE "C" ASC')).order("md5(id::text) ASC").each_with_object({}).with_index(1) do |(identity, identities), student_number|
      identities[identity["user_id"]] = {
        name: I18n.t("Student %{student_number}", { student_number: }),
        position: student_number
      }
    end
  end

  def hide_on_modules_view?
    %w[duplicating failed_to_duplicate outcome_alignment_cloning failed_to_clone_outcome_alignment].include?(workflow_state)
  end

  private

  def grading_type_requires_points?
    POINTED_GRADING_TYPES.include? grading_type
  end

  def set_muted
    self.muted = true
  end

  def anonymous_grader_identities(index_by:)
    return {} unless moderated_grading?

    ordered_moderation_graders_with_slot_taken.each_with_object({}).with_index(1) do |(moderation_grader, anonymous_identities), grader_number|
      anonymous_identities[moderation_grader.public_send(index_by)] = {
        name: I18n.t("Grader %{grader_number}", { grader_number: }),
        id: moderation_grader.anonymous_id
      }
    end
  end

  def ensure_moderation_grader_slot_available(user)
    if moderated_grader_limit_reached? && user.id != final_grader_id
      raise ::Assignment::MaxGradersReachedError
    end
  end

  def mute_if_changed_to_anonymous
    return unless anonymous_grading_changed?

    self.muted = true if anonymous_grading?
  end

  def mute_if_changed_to_moderated
    return unless moderated_grading_changed?

    self.muted = true if moderated_grading?
  end

  def ensure_manual_posting_if_anonymous
    ensure_post_policy(post_manually: true) if saved_change_to_anonymous_grading?(from: false, to: true)
  end

  def ensure_manual_posting_if_moderated
    ensure_post_policy(post_manually: true) if saved_change_to_moderated_grading?(from: false, to: true)
  end

  def create_default_post_policy
    return if post_policy.present?

    post_manually = if course.default_post_policy.present?
                      course.default_post_policy.post_manually
                    else
                      false
                    end

    create_post_policy!(course:, post_manually:)
  end

  def due_date_ok?
    # lock_at OR unlock_at can be empty
    if (unlock_at || lock_at) && due_at && !AssignmentUtil.in_date_range?(due_at, unlock_at, lock_at)
      errors.add(:due_at, I18n.t("must be between availability dates"))
      return false
    end
    unless @skip_sis_due_date_validation || AssignmentUtil.due_date_ok?(self)
      errors.add(:due_at, I18n.t("due_at", "cannot be blank when Post to Sis is checked"))
    end
  end

  def assignment_overrides_due_date_ok?(overrides = {})
    return true if @skip_sis_due_date_validation

    if AssignmentUtil.due_date_required?(self)
      overrides = gather_override_data(overrides)
      if overrides.count { |o| !!o[:due_at_overridden] && o[:due_at].blank? && o[:workflow_state] != "deleted" } > 0
        errors.add(:due_at, I18n.t("cannot be blank for any assignees when Post to Sis is checked"))
        return false
      end
    end
    true
  end

  def gather_override_data(overrides)
    overrides = overrides.values.reject(&:empty?).flatten if overrides.is_a?(Hash)
    overrides = overrides.map do |o|
      o = o.to_unsafe_h if o.is_a?(ActionController::Parameters)
      if o.is_a?(Hash) && o.key?(:due_at) && !o.key?(:due_at_overridden)
        o = o.merge(due_at_overridden: true) # default to true if provided by api
      end
      o
    end
    override_ids = overrides.pluck(:id).to_set
    assignment_overrides.reject { |o| override_ids.include? o[:id] } + overrides
  end

  def active_assignment_overrides?
    assignment_overrides.exists?
  end

  def assignment_name_length_ok?
    name_length = max_name_length

    # Due to the removal of the multiple `validates_length_of :title` validations we need this nil check
    # here to act as those validations so we can reduce the number of validations for this attribute
    # to just one single check
    return false if nil? || self.title.nil?

    if self.title.to_s.length > name_length && self.grading_type != "not_graded"
      errors.add(:title, I18n.t("The title cannot be longer than %{length} characters", length: name_length))
    end
  end

  def annotatable_and_group_exclusivity_ok?
    return false unless has_group_category? && annotated_document?

    errors.add(:annotatable_attachment_id, "must be blank when group_category_id is present")
    errors.add(:group_category_id, "must be blank when annotatable_attachment_id is present")
  end

  def grader_section_ok?
    return false if grader_section.blank?

    if grader_section.workflow_state != "active" || grader_section.course_id != course.id
      errors.add(:grader_section, "must be active and in same course as assignment")
    end
  end

  def final_grader_ok?
    return false unless final_grader_id_changed?
    return false if final_grader_id.blank?

    if grader_section_id.present? && grader_section.instructor_enrollments.where(user_id: final_grader_id, workflow_state: "active").empty?
      errors.add(:final_grader, "must be enrolled in selected section")
    elsif course.participating_instructors.where(id: final_grader_id).empty?
      errors.add(:final_grader, "must be an instructor in this course")
    end
  end

  def allowed_extensions_length_ok?
    if allowed_extensions.present? && allowed_extensions.to_yaml.length > Assignment.maximum_string_length
      errors.add(:allowed_extensions, I18n.t("Value too long, allowed length is %{length}", length: Assignment.maximum_string_length))
    end
  end

  def clear_moderated_grading_attributes(assignment)
    return if assignment.frozen?

    assignment.final_grader_id = nil
    assignment.grader_count = 0
    assignment.grader_names_visible_to_final_grader = true
    assignment.grader_comments_visible_to_graders = true
    assignment.graders_anonymous_to_graders = false
  end

  def set_root_account_id
    self.root_account_id = root_account&.id
  end

  def setup_valid_quiz_lti_settings!
    self.peer_reviews = false
    self.peer_review_count = 0
    self.peer_reviews_due_at = nil
    self.peer_reviews_assigned = false
    self.automatic_peer_reviews = false
    self.anonymous_peer_reviews = false
    self.intra_group_peer_reviews = false
  end

  def instructor_selectable_states
    return {} unless moderated_grading?

    states = %w[inactive completed deleted invited]
    active_user_ids = course.instructors.where.not(enrollments: { workflow_state: states }).pluck(:id)
    provisional_grades.each_with_object({}) do |provisional_grade, hash|
      hash[provisional_grade.id] = active_user_ids.include?(provisional_grade.scorer_id)
    end
  end

  def sanitize_user_name(user_name)
    # necessary because we use /_\d+_/ to infer the user/attachment
    # ids when teachers upload graded submissions
    user_name.gsub!(/_(\d+)_/, '\1')
    user_name.gsub!(/^(\d+)$/, '\1')
    user_name.gsub!(/[^[[:word:]]]/, "")
    user_name.downcase
  end

  def mark_module_progressions_outdated
    progressions = ContextModuleProgression.for_course(context).where(current: true)
    progressions.in_batches(of: 10_000).update_all(current: false)
    User.where(id: progressions.pluck(:user_id)).touch_all
  end
end

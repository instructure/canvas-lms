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

class SubmissionComment < ActiveRecord::Base
  include SendToStream
  include HtmlTextHelper
  include Workflow

  AUDITABLE_ATTRIBUTES = %w[
    comment
    author_id
    provisional_grade_id
    assessment_request_id
    group_comment_id
    attachment_ids
    media_comment_id
    media_comment_type
    anonymous
  ].freeze
  private_constant :AUDITABLE_ATTRIBUTES

  alias_attribute :body, :comment

  attr_writer :updating_user
  attr_accessor :grade_posting_in_progress

  belongs_to :root_account, class_name: "Account"
  belongs_to :submission
  belongs_to :author, class_name: "User"
  belongs_to :assessment_request
  belongs_to :context, polymorphic: [:course]
  belongs_to :provisional_grade, class_name: "ModeratedGrading::ProvisionalGrade"
  has_many :messages, as: :context, inverse_of: :context, dependent: :destroy
  has_many :viewed_submission_comments, dependent: :destroy

  validates :comment, length: { maximum: maximum_text_length, allow_blank: true }
  validates :comment, length: { minimum: 1, allow_blank: true }
  validates_each :attempt do |record, attr, value|
    next if value.nil?

    submission_attempt = record.submission.attempt || 0
    submission_attempt = 1 if submission_attempt == 0
    if value > submission_attempt
      record.errors.add(attr, "attempt must not be larger than number of submission attempts")
    end
  end
  validates :workflow_state, inclusion: { in: ["active"] }, allow_nil: true

  after_destroy :refresh_submission_comment_read_state
  before_save :infer_details
  before_save :set_root_account_id
  before_save :set_edited_at
  after_save :update_participation
  after_save :check_for_media_object
  after_update :publish_other_comments_in_this_group
  after_update :post_submission_for_finalized_draft, if: -> { saved_change_to_draft?(from: true, to: false) }
  after_destroy :delete_other_comments_in_this_group
  after_commit :update_submission

  with_options if: -> { auditable? && updating_user_present? } do
    after_save :record_save_audit_event
    after_destroy :record_deletion_audit_event
  end

  serialize :cached_attachments

  scope :visible, -> { where(hidden: false) }
  scope :draft, -> { where(draft: true) }
  scope :published, -> { where(draft: false) }
  scope :after, ->(date) { where("submission_comments.created_at>?", date) }
  scope :for_final_grade, -> { where(provisional_grade_id: nil) }
  scope :for_provisional_grade, ->(id) { where(provisional_grade_id: id) }
  scope :for_provisional_grades, -> { where.not(provisional_grade_id: nil) }
  scope :for_assignment_id, ->(assignment_id) { where(submissions: { assignment_id: }).joins(:submission) }
  scope :for_groups, -> { where.not(group_comment_id: nil) }
  scope :not_for_groups, -> { where(group_comment_id: nil) }

  workflow do
    state :active
  end

  def refresh_submission_comment_read_state
    submission.refresh_comment_read_state
  end

  def delete_other_comments_in_this_group
    update_other_comments_in_this_group(&:destroy)
  end

  def publish_other_comments_in_this_group
    return unless saved_change_to_draft?

    update_other_comments_in_this_group do |comment|
      comment.update(draft:)
    end
  end

  def update_other_comments_in_this_group
    return if !group_comment_id || skip_group_callbacks?

    # grab comment ids first because the objects built off
    # readonly attributes/objects are marked as readonly and
    # therefore cannot be destroyed
    comment_ids = SubmissionComment
                  .for_assignment_id(submission.assignment_id)
                  .where(group_comment_id:)
                  .where.not(id:)
                  .pluck(:id)

    SubmissionComment.find(comment_ids).each do |comment|
      comment.skip_group_callbacks!
      yield comment
    end
  end

  def post_submission_for_finalized_draft
    return if author_id.blank? || submission.posted? || submission.assignment.post_manually?

    course = submission.assignment.course
    if course.instructor_ids.include?(author.id) || course.account_membership_allows(author)
      submission.update!(posted_at: Time.zone.now)
    end
  end

  has_a_broadcast_policy

  def provisional
    !!provisional_grade_id
  end

  def read?(current_user)
    submission.read?(current_user) || viewed_submission_comments.where(user: current_user).exists?
  end

  def mark_read!(current_user)
    ViewedSubmissionComment.unique_constraint_retry do
      viewed_submission_comments.where(user: current_user).first_or_create!
    end
  end

  def media_comment?
    media_comment_id && media_comment_type
  end

  def self.serialize_media_comment(media_comment_id)
    media_object = MediaObject.by_media_id(media_comment_id).first
    return nil unless media_object.present?

    media_tracks = media_object&.media_tracks&.map { |media_track| media_track.as_json(only: %i[id locale content kind], include_root: false) }
    media_sources = media_object.media_sources
    {
      id: media_object.media_id,
      media_tracks:,
      media_sources:,
      title: media_object.title,
    }
  end

  def check_for_media_object
    if media_comment? && saved_change_to_media_comment_id?
      MediaObject.ensure_media_object(media_comment_id,
                                      user: author,
                                      context: author)
    end
  end

  on_create_send_to_streams do
    if submission && provisional_grade_id.nil?
      if author_id == submission.user_id
        submission.context.instructors_in_charge_of(author_id)
      else
        # self.submission.context.instructors.map(&:id) + [self.submission.user_id] - [self.author_id]
        submission.user_id
      end
    end
  end

  set_policy do
    given { |user, session| can_view_comment?(user, session) }
    can :read

    given { |user| author_id == user.id && draft? }
    can :delete and can :update

    given { |user, session| author_id == user.id && can_grader_modify_comment?(user, session) }
    can :update

    given { |user, session| can_grader_modify_comment?(user, session) }
    can :delete

    given do |user, session|
      can_read_author?(user, session)
    end
    can :read_author
  end

  def course_broadcast_data
    submission.context&.broadcast_data
  end

  set_broadcast_policy do |p|
    p.dispatch :submission_comment
    p.to do
      active_participant =
        Enrollment.where(user_id: submission.user.id, course_id: submission.course_id).active_by_date.exists?
      if active_participant
        ([submission.user] + User.observing_students_in_course(submission.user, submission.assignment.context)) - [author]
      end
    end
    p.whenever do |record|
      # allows broadcasting when this record is initially saved (assuming draft == false) and also when it gets updated
      # from draft to final
      (!record.draft? && (record.just_created || record.saved_change_to_draft?)) &&
        record.provisional_grade_id.nil? &&
        record.submission.assignment &&
        record.submission.assignment.context.available? &&
        record.submission.posted? &&
        record.submission.assignment.context.grants_right?(record.submission.user, :read) &&
        (!record.submission.assignment.context.instructors.include?(author) || record.submission.assignment.published?)
    end
    p.data { course_broadcast_data }

    p.dispatch :submission_comment_for_teacher
    p.to { submission.assignment.context.instructors_in_charge_of(author_id) - [author] }
    p.whenever do |record|
      (!record.draft? && (record.just_created || record.saved_change_to_draft?)) &&
        record.provisional_grade_id.nil? &&
        record.submission.user_id == record.author_id
    end
    p.data { course_broadcast_data }
  end

  def can_grader_modify_comment?(user, session)
    return false unless submission.assignment.context.grants_right?(user, session, :manage_grades)

    true
  end

  def can_view_comment?(user, session)
    # Users can always view their own comments
    return true if author_id == user.id

    # A user with the power to moderate the assignment can see all comments.
    # For moderated assignments, this is the final grader or an admin;
    # for non-moderated assignments, it's all teachers.
    assignment = submission.assignment
    if assignment.moderated_grading?
      return true if assignment.permits_moderation?(user)
    elsif assignment.user_can_update?(user, session)
      return true
    end

    # Students on the receiving end of an assessment can view assessors' comments
    if assessment_request.present?
      return true if assessment_request.user_id == user.id

      # Peer-review comments that belong to a group should be viewable by the
      # rest of the group.
      if group_comment_id.present?
        group_user_ids = submission.group&.user_ids || []
        return true if assessment_request.assessor_id == author_id && group_user_ids.include?(user.id)
      end
    end

    # The student who owns the submission can't see draft or hidden comments (or,
    # generally, any instructor comments if the assignment is muted); the same
    # holds for anyone observing the student
    if submission.user_id == user.id || User.observing_students_in_course(submission.user, assignment.context).include?(user)
      return false if draft? || hidden? || !submission.posted?

      # Generally the student should see only non-provisional comments--but they should
      # also see provisional comments from the final grader if grades are published
      return !provisional || (assignment.grades_published? && author_id == assignment.final_grader_id)
    end

    # For non-moderated assignments, check whether the user can view grades
    return submission.user_can_read_grade?(user, session) unless assignment.moderated_grading?

    # If we made it here, the current user is a provisional grader viewing a
    # moderated assignment, and the comment is by someone else.
    return true if assignment.grader_comments_visible_to_graders?

    if assignment.grades_published?
      # If grades are published, show comments from the student, the final grader,
      # and the chosen grader (and--as checked above--the current user)
      [submission.user_id, assignment.final_grader_id, submission.grader_id].include?(author_id)
    else
      # If not, show comments from the student (and--as checked above--the current user)
      author_id == submission.user_id
    end
  end

  def can_read_author?(user, session)
    RequestCache.cache("user_can_read_author", self, user, session) do
      return false if user.nil? || (author_id != user.id && submission.assignment.anonymize_students?)

      author_id == user.id ||
        (!anonymous? && !submission.assignment.anonymous_peer_reviews?) ||
        submission.assignment.context.grants_right?(user, session, :view_all_grades) ||
        submission.assignment.context.grants_right?(author, session, :view_all_grades)
    end
  end

  def reply_from(opts)
    raise IncomingMail::Errors::UnknownAddress if context.root_account.deleted?

    user = opts[:user]
    message = opts[:text].strip
    user = nil unless user && submission.grants_right?(user, :comment)
    if user
      shard.activate do
        submission.add_comment(
          author: user,
          comment: message,
          provisional: provisional_grade_id.present?
        )
      end
    else
      raise IncomingMail::Errors::InvalidParticipant
    end
  end

  def context
    read_attribute(:context) || submission.assignment.context rescue nil
  end

  def parse_attachment_ids
    (attachment_ids || "").split(",").map(&:to_i)
  end

  def attachment_ids=(ids)
    # raise "Cannot set attachment id's directly"
  end

  def attachments=(attachments)
    # Accept attachments that were already approved, just created, or approved
    # elsewhere.  This is all to prevent one student from sneakily getting
    # access to files in another user's comments, since they're all being held
    # on the assignment for now.
    attachments ||= []
    old_ids = parse_attachment_ids
    write_attribute(:attachment_ids, attachments.select do |a|
      old_ids.include?(a.id) ||
      a.recently_created ||
      a.ok_for_submission_comment
    end.map(&:id).join(","))
  end

  def infer_details
    self.anonymous = submission.assignment.anonymous_peer_reviews
    self.author_name ||= author.short_name rescue t(:unknown_author, "Someone")
    self.cached_attachments = attachments.map { |a| OpenObject.build("attachment", a.attributes) }
    self.context = read_attribute(:context) || submission.assignment.context rescue nil

    self.workflow_state ||= "active"
  end

  def set_root_account_id
    self.root_account_id ||= context.root_account_id
  end

  def force_reload_cached_attachments
    self.cached_attachments = attachments.map { |a| OpenObject.build("attachment", a.attributes) }
    save
  end

  def attachments
    return Attachment.none unless attachment_ids.present?

    ids = parse_attachment_ids
    submission.assignment.attachments.where(id: ids)
  end

  def self.preload_attachments(comments)
    ActiveRecord::Associations.preload(comments, [:submission])
    submissions = comments.map(&:submission).uniq
    ActiveRecord::Associations.preload(submissions, assignment: :attachments)
  end

  def update_submission
    return nil if hidden? || provisional_grade_id.present?

    relevant_comments = SubmissionComment.published
                                         .where(submission_id:)
                                         .where(hidden: false)
                                         .where(provisional_grade_id:)

    comments_count = relevant_comments.count
    Submission.where(id: submission_id).update_all(submission_comments_count: comments_count)
  end

  def formatted_body(truncate = nil)
    # stream items pre-serialize the return value of this method
    if (formatted_body = read_attribute(:formatted_body))
      return formatted_body
    end

    res = format_message(comment).first
    res = truncate_html(res, max_length: truncate, words: true) if truncate
    res
  end

  def context_code
    "#{context_type.downcase}_#{context_id}"
  end

  def avatar_path
    "/images/users/#{User.avatar_key(author_id)}"
  end

  def serialization_methods
    methods = []
    methods << :avatar_path if context.root_account.service_enabled?(:avatars)
    methods
  end

  def publishable_for?(user)
    draft? && author_id == user.id
  end

  def update_participation
    # id_changed? because new_record? is false in after_save callbacks
    if saved_change_to_id? || (saved_change_to_hidden? && !hidden?)
      return if draft? || submission.user_id == author_id || submission.assignment.deleted? || provisional_grade_id.present?

      self.class.connection.after_transaction_commit do
        submission.user.clear_cache_key(:potential_unread_submission_ids)
        submission.mark_item_unread("comment")
      end
    end
  end

  def recipient
    submission.user
  end

  def auditable?
    !draft? && submission.assignment.auditable? && !grade_posting_in_progress
  end

  def allows_posting_submission?
    hidden? && !draft?
  end

  protected

  def skip_group_callbacks!
    @skip_group_callbacks = true
  end

  private

  def updating_user_present?
    # For newly-created comments, the updating user is always the commenter
    updating_user = saved_change_to_id? ? author : @updating_user
    updating_user.present?
  end

  def skip_group_callbacks?
    !!@skip_group_callbacks
  end

  def set_edited_at
    if comment_changed? && comment_was.present?
      self.edited_at = Time.zone.now
    end
  end

  def record_save_audit_event
    updating_user = saved_change_to_id? ? author : @updating_user
    event_type = event_type_for_save
    changes_to_save = auditable_changes(event_type:)
    return if changes_to_save.empty?

    AnonymousOrModerationEvent.create!(
      assignment: submission.assignment,
      submission:,
      user: updating_user,
      event_type:,
      payload: changes_to_save.merge({ id: })
    )
  end

  def event_type_for_save
    # We don't track draft comments, so publishing a draft comment is
    # considered to be a "creation" event.
    publishing_draft = saved_change_to_draft? && !draft?
    treat_as_created = saved_change_to_id? || publishing_draft
    if treat_as_created
      :submission_comment_created
    else
      :submission_comment_updated
    end
  end

  def auditable_changes(event_type:)
    if event_type == :submission_comment_created
      AUDITABLE_ATTRIBUTES.each_with_object({}) do |attribute, map|
        map[attribute] = attributes[attribute] unless attributes[attribute].nil?
      end
    else
      saved_changes.slice(*AUDITABLE_ATTRIBUTES)
    end
  end

  def record_deletion_audit_event
    AnonymousOrModerationEvent.create!(
      assignment: submission.assignment,
      submission:,
      user: @updating_user,
      event_type: :submission_comment_deleted,
      payload: { id: }
    )
  end
end

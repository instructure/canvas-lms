#
# Copyright (C) 2011 Instructure, Inc.
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

  belongs_to :submission #, :touch => true
  belongs_to :author, :class_name => 'User'
  belongs_to :recipient, :class_name => 'User'
  belongs_to :assessment_request
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course']
  has_many :associated_attachments, :class_name => 'Attachment', :as => :context
  has_many :submission_comment_participants, :dependent => :destroy
  has_many :messages, :as => :context, :dependent => :destroy

  EXPORTABLE_ATTRIBUTES = [
    :id, :comment, :submission_id, :recipient_id, :author_id, :author_name, :group_comment_id, :created_at, :updated_at, :attachment_ids, :assessment_request_id, :media_comment_id,
    :media_comment_type, :context_id, :context_type, :cached_attachments, :anonymous, :teacher_only_comment, :hidden
  ]
  EXPORTABLE_ASSOCIATIONS = [:submission, :author, :recipient, :assessment_request, :context, :associated_attachments, :submission_comment_participants]

  validates_length_of :comment, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  validates_length_of :comment, :minimum => 1, :allow_nil => true, :allow_blank => true

  attr_accessible :comment, :submission, :submission_id, :recipient, :recipient_id, :author, :context_id, :context_type, :media_comment_id, :media_comment_type, :group_comment_id, :assessment_request, :attachments, :anonymous, :hidden

  before_save :infer_details
  after_save :update_submission
  after_save :update_participation
  after_save :check_for_media_object
  after_destroy :delete_other_comments_in_this_group
  after_create :update_participants

  serialize :cached_attachments

  scope :for_assignment_id, lambda { |assignment_id| where(:submissions => { :assignment_id => assignment_id }).joins(:submission) }

  def delete_other_comments_in_this_group
    return if !self.group_comment_id || @skip_destroy_callbacks
    SubmissionComment.for_assignment_id(submission.assignment_id).where(group_comment_id: self.group_comment_id).select{|c| c != self }.each do |comment|
      comment.skip_destroy_callbacks!
      comment.destroy
    end
  end

  def skip_destroy_callbacks!
    @skip_destroy_callbacks = true
  end

  has_a_broadcast_policy

  def media_comment?
    self.media_comment_id && self.media_comment_type
  end

  def check_for_media_object
    if self.media_comment? && self.media_comment_id_changed?
      MediaObject.ensure_media_object(self.media_comment_id, {
        :user => self.author,
        :context => self.author,
      })
    end
  end

  on_create_send_to_streams do
    if self.submission
      if self.author_id == self.submission.user_id
        self.submission.context.instructors_in_charge_of(self.author_id)
      else
        # self.submission.context.instructors.map(&:id) + [self.submission.user_id] - [self.author_id]
        self.submission.user_id
      end
    end
  end

  set_policy do
    given {|user,session| !self.teacher_only_comment && self.submission.grants_right?(user, session, :read_grade) && !self.hidden? }
    can :read

    given {|user| self.author == user}
    can :read and can :delete

    given {|user, session| self.submission.grants_right?(user, session, :grade) }
    can :read and can :delete
  end

  set_broadcast_policy do |p|
    p.dispatch :submission_comment
    p.to { [submission.user] - [author] }
    p.whenever {|record|
      record.just_created &&
      record.submission.assignment &&
      !record.submission.assignment.muted? &&
      (!record.submission.assignment.context.instructors.include?(author) || record.submission.assignment.published?)
    }

    p.dispatch :submission_comment_for_teacher
    p.to { submission.assignment.context.instructors_in_charge_of(author_id) - [author] }
    p.whenever {|record|
      record.just_created &&
      record.submission.user_id == record.author_id
    }
  end

  def update_participants
    self.submission_comment_participants.where(user_id: self.submission.user_id, participation_type: 'submitter').first_or_create
    self.submission_comment_participants.where(user_id: self.author_id, participation_type: 'author').first_or_create
    (submission.assignment.context.participating_instructors - [author]).each do |user|
      self.submission_comment_participants.where(user_id: user.id, participation_type: 'admin').first_or_create
    end
  end

  def reply_from(opts)
    raise IncomingMail::Errors::UnknownAddress if self.context.root_account.deleted?
    user = opts[:user]
    message = opts[:text].strip
    user = nil unless user && self.context.users.include?(user)
    if !user
      raise "Only comment participants may reply to messages"
    elsif !message || message.empty?
      raise "Message body cannot be blank"
    else
      SubmissionComment.create!({
        :comment => message,
        :submission_id => self.submission_id,
        :recipient_id => self.recipient_id,
        :author => user,
        :context_id => self.context_id,
        :context_type => self.context_type
      })
    end
  end

  def context
    read_attribute(:context) || self.submission.assignment.context rescue nil
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
    old_ids = (self.attachment_ids || "").split(",").map{|id| id.to_i}
    write_attribute(:attachment_ids, attachments.select { |a|
      old_ids.include?(a.id) ||
      a.recently_created ||
      a.ok_for_submission_comment
    }.map{|a| a.id}.join(","))
  end

  def infer_details
    self.author_name ||= self.author.short_name rescue t(:unknown_author, "Someone")
    self.cached_attachments = self.attachments.map{|a| OpenObject.build('attachment', a.attributes) }
    self.context = self.read_attribute(:context) || self.submission.assignment.context rescue nil
  end

  def force_reload_cached_attachments
    self.cached_attachments = self.attachments.map{|a| OpenObject.build('attachment', a.attributes) }
    self.save
  end


  def attachments
    ids = Set.new((attachment_ids || "").split(",").map { |id| id.to_i})
    attachments = associated_attachments
    attachments += submission.assignment.attachments rescue []
    attachments.select { |a| ids.include?(a.id) }
  end

  def self.preload_attachments(comments)
    ActiveRecord::Associations::Preloader.new(comments, [:associated_attachments, :submission]).run
    submissions = comments.map(&:submission).uniq
    ActiveRecord::Associations::Preloader.new(submissions, :assignment => :attachments).run
  end

  def update_submission
    return nil if hidden?
    comments_count = SubmissionComment.where(:submission_id => submission_id, :hidden => false).count
    Submission.where(:id => submission_id).update_all(:submission_comments_count => comments_count) rescue nil
  end

  def formatted_body(truncate=nil)
    # stream items pre-serialize the return value of this method
    if formatted_body = read_attribute(:formatted_body)
      return formatted_body
    end
    res = format_message(comment).first
    res = truncate_html(res, :max_length => truncate, :words => true) if truncate
    res
  end

  def context_code
    "#{self.context_type.downcase}_#{self.context_id}"
  end
  
  def avatar_path
    "/images/users/#{User.avatar_key(self.author_id)}"
  end

  def serialization_methods
    context.root_account.service_enabled?(:avatars) ? [:avatar_path] : []
  end

  scope :visible, -> { where(:hidden => false) }

  scope :after, lambda { |date| where("submission_comments.created_at>?", date) }
  scope :for_context, lambda { |context| where(:context_id => context, :context_type => context.class.to_s) }

  def update_participation
    # id_changed? because new_record? is false in after_save callbacks
    if id_changed? || (hidden_changed? && !hidden?)
      return if submission.user_id == author_id
      return if submission.assignment.deleted? || submission.assignment.muted?

      ContentParticipation.create_or_update({
        :content => submission,
        :user => submission.user,
        :workflow_state => "unread",
      })
    end
  end
end

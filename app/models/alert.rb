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

class Alert < ActiveRecord::Base
  belongs_to :context, :polymorphic => true # Account or Course
  has_many :criteria, :class_name => 'AlertCriterion', :dependent => :destroy, :autosave => true

  serialize :recipients

  attr_accessible :context, :repetition, :criteria, :recipients

  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_presence_of :criteria
  validates_associated :criteria
  validates_presence_of :recipients

  before_save :infer_defaults

  def infer_defaults
    self.repetition = nil if self.repetition.blank?
  end

  def as_json(*args)
    {
      :id => id,
      :criteria => criteria.map { |c| c.as_json(:include_root => false) },
      :recipients => recipients.try(:map) { |r| (r.is_a?(Symbol) ? ":#{r}" : r) },
      :repetition => repetition
    }.with_indifferent_access
  end

  def recipients=(recipients)
    write_attribute(:recipients, recipients.map { |r| (r.is_a?(String) && r[0..0] == ':' ? r[1..-1].to_sym : r) })
  end

  def criteria=(values)
    if values[0].is_a? Hash
      values = values.map do |params|
        if(params[:id].present?)
          id = params.delete(:id).to_i
          criterion = self.criteria.to_ary.find { |c| c.id == id }
          criterion.attributes = params
        else
          criterion = self.criteria.build(params)
        end
        criterion
      end
    end
    self.criteria.replace(values)
  end

  def resolve_recipients(student_id, teachers = nil)
    include_student = false
    include_teacher = false
    include_teachers = false
    admin_roles = []
    self.recipients.try(:each) do |recipient|
      case
      when recipient == :student
        include_student = true
      when recipient == :teachers
        include_teachers = true
      when recipient.is_a?(String)
        admin_roles << recipient
      else
        raise "Unsupported recipient type!"
      end
    end

    recipients = []

    recipients << student_id if include_student
    recipients.concat(Array(teachers)) if teachers.present? && include_teachers
    recipients.concat context.account_users.where(:membership_type => admin_roles).uniq.pluck(:user_id) if context_type == 'Account' && !admin_roles.empty?
    recipients.uniq
  end

  def self.process
    Account.root_accounts.active.find_each do |account|
      next unless account.settings[:enable_alerts]
      self.send_later_if_production_enqueue_args(:evaluate_for_root_account, { :priority => Delayed::LOW_PRIORITY }, account)
    end
  end

  def self.evaluate_for_root_account(account)
    return unless account.settings[:enable_alerts]
    alerts_cache = {}
    account.associated_courses.where(:workflow_state => 'available').find_each do |course|
      alerts_cache[course.account_id] ||= course.account.account_chain.map { |a| a.alerts.all }.flatten
      self.evaluate_for_course(course, alerts_cache[course.account_id], account.enable_user_notes?)
    end
  end

  def self.evaluate_for_course(course, account_alerts = nil, include_user_notes = nil)
    return unless course.available?

    alerts = Array.new(account_alerts || [])
    alerts.concat course.alerts.all
    return if alerts.empty?

    student_enrollments = course.student_enrollments.active
    student_ids = student_enrollments.map(&:user_id)
    return if student_ids.empty?
    student_ids_to_section_ids = {}
    student_enrollments.each do |enrollment|
      student_ids_to_section_ids[enrollment.user_id] ||= []
      student_ids_to_section_ids[enrollment.user_id] << enrollment.course_section_id
    end

    teacher_enrollments = course.instructor_enrollments.active
    teacher_ids = teacher_enrollments.map(&:user_id)
    return if teacher_ids.empty?
    section_ids_to_teachers_list = {}
    teacher_enrollments.each do |enrollment|
      section_id = enrollment.limit_privileges_to_course_section ? enrollment.course_section_id : nil
      section_ids_to_teachers_list[section_id] ||= []
      section_ids_to_teachers_list[section_id] << enrollment.user_id
    end

    criterion_types = alerts.map(&:criteria).flatten.map(&:criterion_type).uniq
    data = {}
    student_enrollments.each { |e| data[e.user_id] = {} }

    # Bulk data gathering
    if criterion_types.include? 'Interaction'
      scope = SubmissionComment.for_context(course).
          where(:author_id => teacher_ids, :recipient_id => student_ids)
      last_comment_dates = CANVAS_RAILS2 ?
          scope.maximum(:created_at, :group => [:recipient_id, :author_id]) :
          scope.group(:recipient_id, :author_id).maximum(:created_at)
      last_comment_dates.each do |key, date|
        student = data[key.first]
        (student[:last_interaction] ||= {})[key.last] = date
      end
      scope = ConversationMessage.
          joins('INNER JOIN conversation_participants ON conversation_participants.conversation_id=conversation_messages.conversation_id').
          where(:conversation_messages => { :author_id => teacher_ids, :generated => false }, :conversation_participants => { :user_id => student_ids })
      last_message_dates = CANVAS_RAILS2 ?
          scope.maximum(:created_at, :group => ['conversation_participants.user_id', 'conversation_messages.author_id']) :
          scope.group('conversation_participants.user_id', 'conversation_messages.author_id').maximum(:created_at)
      last_message_dates.each do |key, date|
        student = data[key.first.to_i]
        last_interaction = (student[:last_interaction] ||= {})
        last_interaction[key.last] = [last_interaction[key.last], date].compact.max
      end

      data.each do |student_id, user_data|
        user_data[:last_interaction] ||= {}
        user_data[:last_interaction][:all] = user_data[:last_interaction].values.max
      end
    end
    if criterion_types.include? 'UngradedCount'
      ungraded_counts = course.submissions.
          group("submissions.user_id").
          where(:user_id => student_ids).
          where(Submission.needs_grading_conditions).
          except(:order).
          count
      ungraded_counts.each do |user_id, count|
        student = data[user_id]
        student[:ungraded_count] = count
      end
    end
    if criterion_types.include? 'UngradedTimespan'
      ungraded_timespans = course.submissions.
          group("submissions.user_id").
          where(:user_id => student_ids).
          where(Submission.needs_grading_conditions).
          except(:order).
          minimum(:submitted_at)
      ungraded_timespans.each do |user_id, timespan|
        student = data[user_id]
        student[:ungraded_timespan] = timespan
      end
    end
    include_user_notes = course.root_account.enable_user_notes? if include_user_notes.nil?
    if criterion_types.include?('UserNote') && include_user_notes
      scope = UserNote.active.
          where(:created_by_id => teacher_ids, :user_id => student_ids)
      note_dates = CANVAS_RAILS2 ?
          scope.maximum(:created_at, :group => [:user_id, :created_by_id]) :
          scope.group(:user_id, :created_by_id).maximum(:created_at)
      note_dates.each do |key, date|
        student = data[key.first]
        (student[:last_user_note] ||= {})[key.last] = date
      end
      data.each do |student_id, user_data|
        user_data[:last_user_note] ||= {}
        user_data[:last_user_note][:all] = user_data[:last_user_note].values.max
      end
    end

    # Evaluate all the criteria for each user for each alert
    today = Time.now.beginning_of_day
    start_at = course.start_at || course.created_at

    alerts.each do |alert|
      data.each do |user_id, user_data|
        matches = true
        alert.criteria.each do |criterion|
          case criterion.criterion_type
          when 'Interaction'
            if (user_data[:last_interaction][:all] || start_at) + criterion.threshold.days > today
              matches = false
              break
            end
          when 'UngradedCount'
            if (user_data[:ungraded_count].to_i < criterion.threshold.to_i)
              matches = false
              break
            end
          when 'UngradedTimespan'
            if (!user_data[:ungraded_timespan] || user_data[:ungraded_timespan] + criterion.threshold.days > today)
              matches = false
              break
            end
          when 'UserNote'
            if include_user_notes && (user_data[:last_user_note][:all] || start_at) + criterion.threshold.days > today
              matches = false
              break
            end
          end
        end
        cache_key = [alert, user_id].cache_key
        if matches
          last_sent = Rails.cache.fetch(cache_key)
          if last_sent.blank?
          elsif alert.repetition.blank?
            matches = false
          else
            matches = last_sent + alert.repetition.days <= today
          end
        end
        if matches
          Rails.cache.write(cache_key, today)

          teachers = []
          teachers.concat(section_ids_to_teachers_list[nil]) if section_ids_to_teachers_list[nil]
          student_ids_to_section_ids[user_id].each do |section_id|
            teachers.concat(section_ids_to_teachers_list[section_id]) if section_ids_to_teachers_list[section_id]
          end
          send_alert(alert, alert.resolve_recipients(user_id, teachers), student_enrollments.to_ary.find { |enrollment| enrollment.user_id == user_id } )
        end
      end
    end
  end

  def self.send_alert(alert, user_ids, student_enrollment)
    notification = Notification.by_name("Alert")
    notification.create_message(alert, user_ids, {:asset_context => student_enrollment})
  end
end

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

  def self.evaluate_for_course(course, account_alerts, include_user_notes)
    return unless course.available?

    alerts = Array.new(account_alerts || [])
    alerts.concat course.alerts.all
    return if alerts.empty?

    student_enrollments = course.student_enrollments.active
    student_ids = student_enrollments.map(&:user_id)
    return if student_ids.empty?

    teacher_enrollments = course.instructor_enrollments.active
    teacher_ids = teacher_enrollments.map(&:user_id)
    return if teacher_ids.empty?

    teacher_student_mapper = Courses::TeacherStudentMapper.new(student_enrollments, teacher_enrollments)

    criterion_types = alerts.map(&:criteria).flatten.map(&:criterion_type).uniq
    data = {}
    student_enrollments.each { |e| data[e.user_id] = {} }

    # Bulk data gathering
    if criterion_types.include? 'Interaction'
      interaction_alert = Alerts::Interaction.new(course, student_ids, teacher_ids)
    end
    if criterion_types.include? 'UngradedCount'
      ungraded_count_alert = Alerts::UngradedCount.new(course, student_ids)
    end
    if criterion_types.include? 'UngradedTimespan'
      ungraded_timespan_alert = Alerts::UngradedTimespan.new(course, student_ids)
    end
    include_user_notes = course.root_account.enable_user_notes? if include_user_notes.nil?
    if criterion_types.include?('UserNote') && include_user_notes
      user_note_alert = Alerts::UserNote.new(course, student_ids, teacher_ids)
    end

    # Evaluate all the criteria for each user for each alert
    today = Time.now.beginning_of_day

    alerts.each do |alert|
      data.each do |user_id, user_data|
        matches = true
        alert.criteria.each do |criterion|
          case criterion.criterion_type
          when 'Interaction'
            if interaction_alert.should_not_receive_message?(user_id, criterion.threshold.to_i)
              matches = false
              break
            end
          when 'UngradedCount'
            if ungraded_count_alert.should_not_receive_message?(user_id, criterion.threshold.to_i)
              matches = false
              break
            end
          when 'UngradedTimespan'
            if ungraded_timespan_alert.should_not_receive_message?(user_id, criterion.threshold.to_i)
              matches = false
              break
            end
          when 'UserNote'
            if include_user_notes && user_note_alert.should_not_receive_message?(user_id, criterion.threshold.to_i)
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

          send_alert(alert, alert.resolve_recipients(user_id, teacher_student_mapper.teachers_for_student(user_id)), student_enrollments.to_ary.find { |enrollment| enrollment.user_id == user_id } )
        end
      end
    end
  end

  def self.send_alert(alert, user_ids, student_enrollment)
    notification = Notification.by_name("Alert")
    notification.create_message(alert, user_ids, {:asset_context => student_enrollment})
  end
end

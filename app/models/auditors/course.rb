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

class Auditors::Course
  class Record < Auditors::Record
    attributes :course_id,
               :user_id,
               :event_source,
               :sis_batch_id,
               :account_id

    def self.generate(course, user, event_type, event_data = {}, opts = {})
      event_source = opts[:source] || :manual
      sis_batch_id = opts[:sis_batch_id]
      event = new(
        "course" => course,
        "user" => user,
        "event_type" => event_type,
        "event_data" => event_data,
        "event_source" => event_source.to_s,
        "sis_batch_id" => sis_batch_id
      )
      event.sis_batch = opts[:sis_batch] if opts[:sis_batch]
      event
    end

    def initialize(*args)
      super(*args)

      if attributes["course"]
        self.course = attributes.delete("course")
      end

      if attributes["user"]
        self.user = attributes.delete("user")
      end

      if attributes["event_data"]
        self.event_data = attributes.delete("event_data")
      end

      if attributes["sis_batch"]
        self.sis_batch = attributes.delete("sis_batch")
      end
    end

    def event_source
      attributes["event_source"]&.to_sym
    end

    def user
      @user ||= User.find(user_id) if user_id
    end

    def user=(user)
      @user = user

      attributes["user_id"] = Shard.global_id_for(@user)
    end

    def sis_batch
      @sis_batch ||= SisBatch.find(sis_batch_id)
    end

    def sis_batch=(batch)
      @sis_batch = batch

      attributes["sis_batch_id"] = Shard.global_id_for(batch)
    end

    def course
      @course ||= Course.find(course_id)
    end

    def course=(course)
      @course = course

      attributes["course_id"] = Shard.global_id_for(@course)
      attributes["account_id"] = Shard.global_id_for(@course.account_id)
    end

    def event_data
      @event_data ||= JSON.parse(attributes["data"]) if attributes["data"]
    end

    def event_data=(value)
      @event_data = value

      attributes["data"] = @event_data.to_json
    end

    delegate :account, to: :course
  end

  Stream = Auditors.stream do
    course_ar_type = Auditors::ActiveRecord::CourseRecord
    active_record_type course_ar_type
    record_type Auditors::Course::Record

    add_index :course do
      table :courses_by_course
      entry_proc ->(record) { record.course }
      key_proc ->(course) { course.global_id }
      ar_scope_proc ->(course) { course_ar_type.where(course_id: course.id) }
    end

    add_index :account do
      table :courses_by_account
      entry_proc ->(record) { record.account }
      key_proc ->(account) { account.global_id }
      ar_scope_proc ->(account) { course_ar_type.where(account_id: account.id) }
    end
  end

  def self.remove_empty_changes(changes)
    # courses may instantiate an empty hash for serialized attributes
    changes.reject { |_k, change| change.is_a?(Array) && change.all?(&:blank?) }
  end

  def self.record_created(course, user, changes, opts = {})
    return unless course && changes

    changes = remove_empty_changes(changes)
    return if changes.empty?

    record(course, user, "created", changes, opts)
  end

  def self.record_updated(course, user, changes, opts = {})
    return unless course && changes

    changes = remove_empty_changes(changes)
    return if changes.empty?

    record(course, user, "updated", changes, opts)
  end

  def self.record_concluded(course, user, opts = {})
    return unless course

    record(course, user, "concluded", {}, opts)
  end

  def self.record_unconcluded(course, user, opts = {})
    return unless course

    record(course, user, "unconcluded", {}, opts)
  end

  def self.record_deleted(course, user, opts = {})
    return unless course

    record(course, user, "deleted", {}, opts)
  end

  def self.record_restored(course, user, opts = {})
    return unless course

    record(course, user, "restored", {}, opts)
  end

  def self.record_published(course, user, opts = {})
    return unless course

    record(course, user, "published", {}, opts)
  end

  def self.record_claimed(course, user, opts = {})
    return unless course

    record(course, user, "claimed", {}, opts)
  end

  def self.record_copied(course, copy, user, opts = {})
    return unless course && copy

    copied_from = record(copy, user, "copied_from", { copied_from: Shard.global_id_for(course) }, opts)
    copied_to = record(course, user, "copied_to", { copied_to: Shard.global_id_for(copy) }, opts)
    [copied_from, copied_to]
  end

  def self.record_reset(course, new_course, user, opts = {})
    return unless course && new_course

    reset_from = record(new_course, user, "reset_from", { reset_from: Shard.global_id_for(course) }, opts)
    reset_to = record(course, user, "reset_to", { reset_to: Shard.global_id_for(new_course) }, opts)
    [reset_from, reset_to]
  end

  def self.record(course, user, event_type, data = {}, opts = {})
    return unless course

    data.each do |k, change|
      if change.is_a?(Array) && change.any? { |v| v.is_a?(String) && v.length > 1000 }
        data[k] = change.map { |v| v.is_a?(String) ? CanvasTextHelper.truncate_text(v, max_length: 1000) : v }
      end
    end
    event_record = nil
    course.shard.activate do
      event_record = Auditors::Course::Record.generate(course, user, event_type, data, opts)
      Auditors::Course::Stream.insert(event_record)
    end
    event_record
  end

  def self.for_course(course, options = {})
    course.shard.activate do
      Auditors::Course::Stream.for_course(course, options)
    end
  end

  def self.for_account(account, options = {})
    account.shard.activate do
      Auditors::Course::Stream.for_account(account, options)
    end
  end
end

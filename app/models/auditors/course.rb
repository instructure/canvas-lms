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

module Auditors; end

class Auditors::Course
  class Record < Auditors::Record
    attributes :course_id,
               :user_id,
               :event_source,
               :sis_batch_id

    def self.generate(course, user, event_type, event_data = {}, opts = {})
      event_source = opts[:source] || :manual
      sis_batch_id = opts[:sis_batch_id]
      event = new(
        'course' => course,
        'user' => user,
        'event_type' => event_type,
        'event_data' => event_data,
        'event_source' => event_source.to_s,
        'sis_batch_id' => sis_batch_id
      )
      event.sis_batch = opts[:sis_batch] if opts[:sis_batch]
      event
    end

    def initialize(*args)
      super(*args)

      if attributes['course']
        self.course = attributes.delete('course')
      end

      if attributes['user']
        self.user = attributes.delete('user')
      end

      if attributes['event_data']
        self.event_data = attributes.delete('event_data')
      end

      if attributes['sis_batch']
        self.sis_batch = attributes.delete('sis_batch')
      end
    end

    def event_source
      attributes['event_source'].to_sym if attributes['event_source']
    end

    def user
      @user ||= User.find(user_id)
    end

    def user=(user)
      @user = user

      attributes['user_id'] = Shard.global_id_for(@user)
    end

    def sis_batch
      @sis_batch ||= SisBatch.find(sis_batch_id)
    end

    def sis_batch=(batch)
      @sis_batch = batch

      attributes['sis_batch_id'] = Shard.global_id_for(batch)
    end

    def course
      @course ||= Course.find(course_id)
    end

    def course=(course)
      @course = course

      attributes['course_id'] = Shard.global_id_for(@course)
    end

    def event_data
      @event_data ||= JSON.parse(attributes['data']) if attributes['data']
    end

    def event_data=(value)
      @event_data = value

      attributes['data'] = @event_data.to_json
    end
  end

  Stream = EventStream::Stream.new do
    database -> { Canvas::Cassandra::DatabaseBuilder.from_config(:auditors) }
    table :courses
    record_type Auditors::Course::Record
    read_consistency_level -> { Canvas::Cassandra::DatabaseBuilder.read_consistency_setting(:auditors) }

    add_index :course do
      table :courses_by_course
      entry_proc lambda{ |record| record.course }
      key_proc lambda{ |course| course.global_id }
    end
  end

  def self.record_created(course, user, changes, opts = {})
    return unless course && changes
    return if changes.empty?
    self.record(course, user, "created", changes, opts)
  end

  def self.record_updated(course, user, changes, opts = {})
    return unless course && changes
    return if changes.empty?
    self.record(course, user, 'updated', changes, opts)
  end

  def self.record_concluded(course, user, opts = {})
    return unless course
    self.record(course, user, 'concluded', {}, opts)
  end

  def self.record_unconcluded(course, user, opts = {})
    return unless course
    self.record(course, user, 'unconcluded', {}, opts)
  end

  def self.record_deleted(course, user, opts = {})
    return unless course
    self.record(course, user, 'deleted', {}, opts)
  end

  def self.record_restored(course, user, opts = {})
    return unless course
    self.record(course, user, 'restored', {}, opts)
  end

  def self.record_published(course, user, opts = {})
    return unless course
    self.record(course, user, 'published', {}, opts)
  end

  def self.record_claimed(course, user, opts = {})
    return unless course
    self.record(course, user, 'claimed', {}, opts)
  end

  def self.record_copied(course, copy, user, opts = {})
    return unless course && copy
    copied_from = self.record(copy, user, 'copied_from', { copied_from: Shard.global_id_for(course) }, opts)
    copied_to = self.record(course, user, 'copied_to', { copied_to: Shard.global_id_for(copy) }, opts)
    return copied_from, copied_to
  end

  def self.record_reset(course, new_course, user, opts = {})
    return unless course && new_course
    reset_from = self.record(new_course, user, 'reset_from', { reset_from: Shard.global_id_for(course) }, opts)
    reset_to = self.record(course, user, 'reset_to', { reset_to: Shard.global_id_for(new_course) }, opts)
    return reset_from, reset_to
  end

  def self.record(course, user, event_type, data={}, opts = {})
    return unless course
    course.shard.activate do
      record = Auditors::Course::Record.generate(course, user, event_type, data, opts)
      Auditors::Course::Stream.insert(record)
    end
  end

  def self.for_course(course, options={})
    course.shard.activate do
      Auditors::Course::Stream.for_course(course, options)
    end
  end
end

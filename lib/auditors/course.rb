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
  class Record < ::EventStream::Record
    attributes :course_id,
               :user_id

    def self.generate(course, user, event_type, event_data)
      new(
        'course' => course,
        'user' => user,
        'event_type' => event_type,
        'event_data' => event_data
      )
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
    end

    def user
      @user ||= User.find(user_id)
    end

    def user=(user)
      @user = user

      attributes['user_id'] = Shard.global_id_for(@user)
    end

    def course
      @course ||= Course.find(course_id)
    end

    def course=(course)
      @course = course

      attributes['course_id'] = Shard.global_id_for(@course)
    end

    def event_data
      @event_data ||= JSON.parse(attributes['data'])
    end

    def event_data=(value)
      @event_data = value

      attributes['data'] = @event_data.to_json
    end
  end

  Stream = ::EventStream.new do
    database_name :auditors
    table :courses
    record_type Auditors::Course::Record

    add_index :course do
      table :courses_by_course
      entry_proc lambda{ |record| record.course }
      key_proc lambda{ |course| course.global_id }
    end
  end

  def self.record_created(course, user, changes)
    return unless course && changes
    return if changes.empty?
    self.record(course, user, 'created', changes)
  end

  def self.record_updated(course, user, changes)
    return unless course && changes
    return if changes.empty?
    self.record(course, user, 'updated', changes)
  end

  def self.record_concluded(course, user)
    return unless course
    self.record(course, user, 'concluded')
  end

  def self.record(course, user, event_type, data={})
    return unless course
    course.shard.activate do
      record = Auditors::Course::Record.generate(course, user, event_type, data)
      Auditors::Course::Stream.insert(record)
    end
  end

  def self.for_course(course, options={})
    course.shard.activate do
      Auditors::Course::Stream.for_course(course, options)
    end
  end
end

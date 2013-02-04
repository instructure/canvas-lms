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

class MessageableUser < User
  COLUMNS = ['id', 'short_name', 'name', 'avatar_image_url', 'avatar_image_source'].map{ |col| "users.#{col}" }
  SELECT = COLUMNS.join(", ")
  AVAILABLE_CONDITIONS = "users.workflow_state IN ('registered', 'pre_registered')"

  def self.build_select(options={})
    common_course_column = options[:common_course_column] || 'NULL'
    common_group_column = options[:common_group_column] || 'NULL'
    common_roles_column = options[:common_role_column] ?
      connection.func(:group_concat, options[:common_role_column].to_sym) :
      'NULL'
    "#{SELECT}, #{common_course_column} AS common_course_id, #{common_group_column} AS common_group_id, #{common_roles_column} AS common_roles"
  end

  named_scope :prepped, lambda{ |options|
    select = MessageableUser.build_select(options)
    if options.has_key?(:strict_checks) && !options[:strict_checks]
      { :select => select }
    else
      { :select => select, :conditions => AVAILABLE_CONDITIONS }
    end
  }

  def self.unfiltered(options={})
    prepped(options.merge(:strict_checks => false))
  end

  def self.available(options={})
    prepped(options.merge(:strict_checks => true))
  end

  def self.context_recipients(recipients)
    recipients.grep(Calculator::CONTEXT_RECIPIENT)
  end

  def self.individual_recipients(recipients)
    recipients.grep(Calculator::INDIVIDUAL_RECIPIENT).map(&:to_i)
  end

  def common_groups
    common_contexts_on_current_shard(global_common_groups)
  end

  def common_courses
    common_contexts_on_current_shard(global_common_courses)
  end

  # only MessageableUser::Calculator should access these directly. if you're
  # outside the calculator, you almost certainly want the versions above that
  # transpose to the current shard. additionally, any time you access these,
  # make sure you're still on the same shard where common_course_id and/or
  # common_group_id were queried
  attr_writer :global_common_courses, :global_common_groups

  def global_common_courses
    unless @global_common_courses
      @global_common_courses = {}
      if global_common_course_id
        @global_common_courses[global_common_course_id] = common_roles.to_s.split(',')
      end
    end
    @global_common_courses
  end

  def global_common_groups
    unless @global_common_groups
      @global_common_groups = {}
      if global_common_group_id
        @global_common_groups[global_common_group_id.to_i] = ['Member']
      end
    end
    @global_common_groups
  end

  private

  def global_common_course_id
    if common_course_id.nil?
      nil
    elsif common_course_id.to_i == 0
      0
    else
      Shard.global_id_for(common_course_id.to_i)
    end
  end

  def global_common_group_id
    if common_group_id.nil?
      nil
    else
      Shard.global_id_for(common_group_id.to_i)
    end
  end

  def common_contexts_on_current_shard(common_contexts)
    local_common_contexts = {}
    target_shard = Shard.current
    return local_common_contexts if common_contexts.empty?
    Shard.partition_by_shard(common_contexts.keys) do |sharded_ids|
      sharded_ids.each do |id|
        global_id = Shard.global_id_for(id)
        id = global_id unless Shard.current == target_shard
        local_common_contexts[id] = common_contexts[global_id]
      end
    end
    local_common_contexts
  end
end

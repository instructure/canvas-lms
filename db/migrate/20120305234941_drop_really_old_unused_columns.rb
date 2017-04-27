#
# Copyright (C) 2012 - present Instructure, Inc.
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

class DropReallyOldUnusedColumns < ActiveRecord::Migration[4.2]
  tag :postdeploy

  disable_ddl_transaction!

  # cleanup for some legacy database schema that may not even exist for databases created post-OSS release
  def self.maybe_drop(table, column)
    remove_column(table, column) if self.connection.columns(table).map(&:name).include?(column.to_s)
  end

  def self.up
   maybe_drop :accounts, :account_code
   maybe_drop :accounts, :authentication_type
   maybe_drop :accounts, :ldap_host
   maybe_drop :accounts, :ldap_domain

   maybe_drop :account_authorization_configs, :auth_uid

   maybe_drop :assignments, :sequence_position

   maybe_drop :content_tags, :sequence_position

   maybe_drop :course_sections, :students_can_participate_before_start_at

   maybe_drop :discussion_topics, :authorization_list_id

   maybe_drop :enrollments, :can_participate_before_start_at

   maybe_drop :pseudonyms, :crypted_webdav_access_code

   maybe_drop :quizzes, :root_quiz_id
  end

  def self.down
  end
end

#
# Copyright (C) 2014 - present Instructure, Inc.
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

class AddForeignKeys14 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :assignment_override_students, :quizzes, delay_validation: true
    add_foreign_key_if_not_exists :assignment_overrides, :quizzes, delay_validation: true
    add_foreign_key_if_not_exists :collaborators, :groups, delay_validation: true
    add_foreign_key_if_not_exists :content_participations, :users, delay_validation: true
    add_foreign_key_if_not_exists :content_tags, :learning_outcomes, delay_validation: true
    add_foreign_key_if_not_exists :context_module_progressions, :context_modules, delay_validation: true
    add_foreign_key_if_not_exists :course_sections, :courses, delay_validation: true
    add_foreign_key_if_not_exists :delayed_messages, :communication_channels, delay_validation: true
    add_foreign_key_if_not_exists :discussion_topic_materialized_views, :discussion_topics, delay_validation: true
    add_foreign_key_if_not_exists :migration_issues, :content_migrations, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :assignment_override_students, :quizzes
    remove_foreign_key_if_exists :assignment_overrides, :quizzes
    remove_foreign_key_if_exists :collaborators, :groups
    remove_foreign_key_if_exists :content_participations, :users
    remove_foreign_key_if_exists :content_tags, :learning_outcomes
    remove_foreign_key_if_exists :context_module_progressions, :context_modules
    remove_foreign_key_if_exists :course_sections, :courses
    remove_foreign_key_if_exists :delayed_messages, :communication_channels
    remove_foreign_key_if_exists :discussion_topic_materialized_views, :discussion_topics
    remove_foreign_key_if_exists :migration_issues, :content_migrations
  end
end

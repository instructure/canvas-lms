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

config = ConfigFile.load("marginalia") || {}

if config[:components].present?
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::QueryLogs.taggings = ActiveRecord::QueryLogs.taggings.merge(
      controller: ->(context) { context[:controller]&.controller_name },
      action: ->(context) { context[:controller]&.action_name },
      hostname: -> { Socket.gethostname },

      context_id: -> { RequestContext::Generator.request_id },
      job_tag: -> { Delayed::Worker.current_job&.[]("tag") }
    )
  end

  Rails.application.config.active_record.query_log_tags_enabled = true
  Rails.application.config.action_controller.log_query_tags_around_actions = true
  Rails.application.config.active_record.query_log_tags = config[:components].map(&:to_sym)
  ActiveRecord::QueryLogs.prepend_comment = true

  module ActiveRecord::QueryLogs::Migrator
    def execute_migration_in_transaction(migration)
      old_migration_name, ActiveRecord::QueryLogs.taggings[:migration] = ActiveRecord::QueryLogs.taggings[:migration], migration.name
      super
    ensure
      ActiveRecord::QueryLogs.taggings[:migration] = old_migration_name
    end
  end

  ActiveRecord::Migrator.prepend(ActiveRecord::QueryLogs::Migrator)

  module ActiveRecord::QueryLogs::RakeTask
    def execute(args = nil)
      previous, ActiveRecord::QueryLogs.taggings[:rake_task] = ActiveRecord::QueryLogs.taggings[:rake_task], name
      super
    ensure
      ActiveRecord::QueryLogs.taggings[:rake_task] = previous
    end
  end

  Rake::Task.prepend(ActiveRecord::QueryLogs::RakeTask)
end

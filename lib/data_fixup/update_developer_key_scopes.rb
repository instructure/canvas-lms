# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module DataFixup
  module UpdateDeveloperKeyScopes
    SCOPE_CHANGES = {
      "url:POST|/api/v1/courses/:course_id/pages/:url/duplicate" => "url:POST|/api/v1/courses/:course_id/pages/:url_or_id/duplicate",
      "url:GET|/api/v1/courses/:course_id/pages/:url" => "url:GET|/api/v1/courses/:course_id/pages/:url_or_id",
      "url:GET|/api/v1/groups/:group_id/pages/:url" => "url:GET|/api/v1/groups/:group_id/pages/:url_or_id",
      "url:GET|/api/v1/courses/:course_id/pages/:url/revisions" => "url:GET|/api/v1/courses/:course_id/pages/:url_or_id/revisions",
      "url:GET|/api/v1/groups/:group_id/pages/:url/revisions" => "url:GET|/api/v1/groups/:group_id/pages/:url_or_id/revisions",
      "url:GET|/api/v1/courses/:course_id/pages/:url/revisions/latest" => "url:GET|/api/v1/courses/:course_id/pages/:url_or_id/revisions/latest",
      "url:GET|/api/v1/groups/:group_id/pages/:url/revisions/latest" => "url:GET|/api/v1/groups/:group_id/pages/:url_or_id/revisions/latest",
      "url:GET|/api/v1/courses/:course_id/pages/:url/revisions/:revision_id" => "url:GET|/api/v1/courses/:course_id/pages/:url_or_id/revisions/:revision_id",
      "url:GET|/api/v1/groups/:group_id/pages/:url/revisions/:revision_id" => "url:GET|/api/v1/groups/:group_id/pages/:url_or_id/revisions/:revision_id",
      "url:POST|/api/v1/courses/:course_id/pages/:url/revisions/:revision_id" => "url:POST|/api/v1/courses/:course_id/pages/:url_or_id/revisions/:revision_id",
      "url:POST|/api/v1/groups/:group_id/pages/:url/revisions/:revision_id" => "url:POST|/api/v1/groups/:group_id/pages/:url_or_id/revisions/:revision_id",
      "url:PUT|/api/v1/courses/:course_id/pages/:url" => "url:PUT|/api/v1/courses/:course_id/pages/:url_or_id",
      "url:PUT|/api/v1/groups/:group_id/pages/:url" => "url:PUT|/api/v1/groups/:group_id/pages/:url_or_id",
      "url:DELETE|/api/v1/courses/:course_id/pages/:url" => "url:DELETE|/api/v1/courses/:course_id/pages/:url_or_id",
      "url:DELETE|/api/v1/groups/:group_id/pages/:url" => "url:DELETE|/api/v1/groups/:group_id/pages/:url_or_id",
      "url:GET|/api/v1/courses/:course_id/tool_proxies/:tool_proxy_id/recreate_subscriptions" => "DELETED",
      "url:GET|/api/v1/accounts/:account_id/tool_proxies/:tool_proxy_id/recreate_subscriptions" => "DELETED",
      "url:POST|/api/v1/courses/:course_id/outcome_imports" => "url:POST|/api/v1/courses/:course_id/outcome_imports(/group/:learning_outcome_group_id)",
      "url:POST|/api/v1/accounts/:account_id/outcome_imports" => "url:POST|/api/v1/accounts/:account_id/outcome_imports(/group/:learning_outcome_group_id)",
    }.freeze

    def self.create_scope_query(old_route)
      DeveloperKey.where("scopes LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(old_route)}%")
    end

    def self.scope_changes
      SCOPE_CHANGES
    end

    def self.run
      return unless scope_changes.any?

      DeveloperKey.find_ids_in_ranges(batch_size: 1000) do |start_at, end_at|
        delay_if_production(
          priority: Delayed::LOW_PRIORITY,
          n_strand: ["DataFixup::UpdateDeveloperKeyScopes", Shard.current.database_server.id]
        ).run_on_range(start_at, end_at)
      end
    end

    def self.run_on_range(start_at, end_at)
      or_conditions = scope_changes.keys.map { |old_scope| create_scope_query(old_scope) }.inject(&:or)

      DeveloperKey.where(id: start_at..end_at).and(or_conditions).find_in_batches do |dk_batch|
        dk_batch.each do |dk|
          dk.scopes = dk.scopes.map { |scope| scope_changes[scope] || scope }.reject { |scope| scope == "DELETED" }
          begin
            dk.save!
          rescue ActiveRecord::RecordInvalid => e
            Rails.logger.info("Developer #{dk.global_id} key scope fixup threw #{e}")
          end
        end
      end
    end
  end
end

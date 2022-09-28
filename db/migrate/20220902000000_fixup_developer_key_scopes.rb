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

class FixupDeveloperKeyScopes < ActiveRecord::Migration[6.1]
  tag :postdeploy
  disable_ddl_transaction!

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
    "url:DELETE|/api/v1/groups/:group_id/pages/:url" => "url:DELETE|/api/v1/groups/:group_id/pages/:url_or_id"
  }.freeze

  def up
    DeveloperKey.find_ids_in_ranges(batch_size: 1000) do |start_at, end_at|
      DataFixup::UpdateDeveloperKeyScopes.delay_if_production(
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::UpdateDeveloperKeyScopes", Shard.current.database_server.id]
      ).run(start_at, end_at, SCOPE_CHANGES)
    end
  end
end

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

# @API Content Migrations
#
# API for accessing content migrations and migration issues
# @object ContentMigration
#   {
#       // the unique identifier for the migration
#       id: 370663,
#
#       // API url to the content migration's issues
#       migration_issues_url: "https://example.com/api/v1/courses/1/content_migrations/1/migration_issues"
#
#       // url to download the file uploaded for this migration
#       // may not be present for all migrations
#       content_archive_download_url: "https://example.com/api/v1/courses/1/content_migrations/1/download_archive"
#
#       // The user who started the migration
#       user_id: 4
#
#       // Current state of the issue: created pre_processing pre_processed pre_process_error converting converted importing imported failed
#       workflow_state: "exporting"
#
#       // timestamps
#       started_at: "2012-06-01T00:00:00-06:00",
#       finished_at: "2012-06-01T00:00:00-06:00",
#
#   }
class ContentMigrationsController < ApplicationController
  include Api::V1::ContentMigration

  before_filter :require_context

  # @API List content migrations
  #
  # Returns paginated content migrations
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/content_migrations \ 
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns [ContentMigration]
  def index
    return unless authorized_action(@context, @current_user, :manage_content)

    @migrations = Api.paginate(@context.content_migrations.order("id DESC"), self, api_v1_course_content_migration_list_url(@context))
    render :json => content_migrations_json(@migrations, @current_user, session)
  end

  # @API Get a content migration
  #
  # Returns data on an individual content migration
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/content_migrations/<id> \ 
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns ContentMigration
  def show
    return unless require_content_migration
    render :json => content_migration_json(@content_migration, @current_user, session)
  end

  def download_archive
    return unless require_content_migration

    if @content_migration.attachment
      if Attachment.s3_storage?
        redirect_to @content_migration.attachment.cacheable_s3_download_url
      else
        cancel_cache_buster
        send_file(@content_migration.attachment.full_filename, :type => @content_migration.attachment.content_type, :disposition => 'attachment')
      end
    else
      render :status => 404, :json => {:message => t('no_archive', "There is no archive for this content migration")}
    end
  end

  protected

  def require_content_migration
    @content_migration = @context.content_migrations.find(params[:id])
    return authorized_action(@context, @current_user, :manage_content)
  end

end

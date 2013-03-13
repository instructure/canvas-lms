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
# @subtopic Migration Issues
#
# @object MigrationIssue
#   {
#       // the unique identifier for the issue
#       id: 370663
#
#       // API url to the content migration
#       content_migration_url: "https://example.com/api/v1/courses/1/content_migrations/1"
#
#       // Description of the issue for the end-user
#       description:  "Questions in this quiz couldn't be converted"
#
#       // Current state of the issue: active, resolved
#       workflow_state: "active"
#
#       // HTML Url to the Canvas page to investigate the issue
#       fix_issue_html_url "https://example.com/courses/1/quizzes/2"
#
#       // Severity of the issue: todo, warning, error
#       issue_type: "warning"
#
#       // Link to a Canvas error report if present (If the requesting user has permissions)
#       error_report_html_url: "https://example.com/error_reports/3"
#
#       // Site administrator error message (If the requesting user has permissions)
#       error_message: "admin only message"
#
#       // timestamps
#       created_at: "2012-06-01T00:00:00-06:00",
#       updated_at: "2012-06-01T00:00:00-06:00",
#
#   }
class MigrationIssuesController < ApplicationController
  include Api::V1::ContentMigration

  before_filter :require_context
  before_filter :require_content_migration

  # @API List migration issues
  #
  # Returns paginated migration issues
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/content_migrations/<content_migration_id>/migration_issues \ 
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns [MigrationIssue]
  def index
    @issues = Api.paginate(@content_migration.migration_issues.by_created_at, self, api_v1_course_content_migration_migration_issue_list_url(@context, @content_migration))
    render :json => migration_issues_json(@issues, @content_migration, @current_user, session)
  end

  # @API Get a migration issue
  #
  # Returns data on an individual migration issue
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/content_migrations/<content_migration_id>/migration_issues/<id> \ 
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns MigrationIssue
  def show
    issue = @content_migration.migration_issues.find(params[:id])
    render :json => migration_issue_json(issue, @content_migration, @current_user, session)
  end

  # @API Update a migration issue
  # Update the workflow_state of a migration issue
  #
  # @argument workflow_state Set the workflow_state of the issue, only 'active' and 'resolved' accepted
  #
  # @example_request
  #
  #   curl -X PUT https://<canvas>/api/v1/courses/<course_id>/content_migrations/<content_migration_id>/migration_issues/<id> \ 
  #        -H 'Authorization: Bearer <token>' \ 
  #        -F 'workflow_state=resolved'
  #
  # @returns MigrationIssue
  def update
    issue = @content_migration.migration_issues.find(params[:id])

    if ['active', 'resolved'].member? params[:workflow_state]
      issue.workflow_state = params[:workflow_state]
      if issue.save
        render :json => migration_issue_json(issue, @content_migration, @current_user, session)
      else
        render :json => issue.errors, :status => :bad_request
      end
    else
      render(:json => { :message => t('errors.valid_workflow_state', "Must send a valid workflow state") }, :status => 403)
    end
  end

  protected

  def require_content_migration
    @content_migration = @context.content_migrations.find(params[:content_migration_id])
    return authorized_action(@context, @current_user, :manage_content)
  end

end

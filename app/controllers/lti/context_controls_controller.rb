# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

module Lti
  # @API LTI ContextControls
  #
  # @beta
  # @internal
  #
  # Configure the availability of an LTI Registration in a specific context.
  # Used by the Canvas Apps page UI.
  #
  # @model Lti::ContextControl
  #   {
  #     "id": "Lti::ContextControl",
  #     "description": "Represent availability of an LTI registration in a specific context",
  #     "properties": {
  #         "id": {
  #           "description": "the Canvas ID of the Lti::ContextControl object",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "course_id": {
  #           "description": "the Canvas ID of the Course that owns this. one of this or account_id will always be present",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "account_id": {
  #           "description": "the Canvas ID of the Account that owns this. one of this or course_id will always be present",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "deployment_id": {
  #           "description": "the Canvas ID of the ContextExternalTool that owns this, representing an LTI deployment",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "available": {
  #           "description": "The state of this tool in this context. `true` means the tool is available in this context and in all contexts below it.",
  #           "example": true,
  #           "type": "boolean"
  #         },
  #         "path": {
  #           "description": "A representation of the account hierarchy for the context that owns this object. Used for checking availability during LTI operations.",
  #           "example": "a1.a2.c3.",
  #           "type": "string"
  #         },
  #         "display_path": {
  #           "description": "For UI display. Names of the accounts in the context's hierarchy. Excludes the root, and the current account if context is an account.",
  #           "example": ["Sub Account", "Other Account"],
  #           "type": "array",
  #           "items": {
  #             "type": "string"
  #           }
  #         },
  #         "context_name": {
  #           "description": "For UI display. The name of the context this object is associated with",
  #           "example": "My Course",
  #           "type": "string"
  #         },
  #         "depth": {
  #           "description": "For UI display. The depth of ContextControls for this particular deployment account chain, which can be different from the number of accounts in the chain.",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "course_count": {
  #           "description": "For UI display. The number of courses in this account and all nested subaccounts. 0 when context is a Course.",
  #           "example": 402,
  #           "type": "integer"
  #         },
  #         "child_control_count": {
  #           "description": "For UI display. The number of controls for accounts below this one, including all nested subaccounts. 0 when context is a Course.",
  #           "example": 42,
  #           "type": "integer"
  #         },
  #         "subaccount_count": {
  #           "description": "For UI display. The number of subaccounts for this account. Includes all nested subaccounts. 0 when context is a Course.",
  #           "example": 42,
  #           "type": "integer"
  #         },
  #         "workflow_state": {
  #           "description": "The state of the object",
  #           "example": "active",
  #           "type": "string",
  #           "enum": ["active", "deleted"]
  #         },
  #         "created_at": {
  #           "description": "Timestamp of the object's creation",
  #           "example": "2024-01-01T00:00:00Z",
  #           "type": "string"
  #         },
  #         "updated_at": {
  #           "description": "Timestamp of the object's last update",
  #           "example": "2024-01-01T00:00:00Z",
  #           "type": "string"
  #         },
  #         "created_by": {
  #           "description": "The user that created this object. Not always present.",
  #           "example": { "type": "User" },
  #           "type": "User",
  #           "$ref": "User"
  #         },
  #         "updated_by": {
  #           "description": "The user that last updated this object. Not always present.",
  #           "example": { "type": "User" },
  #           "type": "User",
  #           "$ref": "User"
  #         }
  #     }
  #   }
  #
  class ContextControlsController < ApplicationController
    include Api::V1::Lti::Deployment
    include Api::V1::Lti::ContextControl

    module ContextControlsBookmarker
      def self.bookmark_for(context_controls)
        [context_controls.deployment_id, context_controls.path]
      end

      def self.validate(bookmark)
        return false unless bookmark.is_a?(Array) && bookmark.length == 2

        bookmark.first.is_a?(Integer) && bookmark.second.is_a?(String)
      end

      def self.restrict_scope(scope, pager)
        if pager.current_bookmark
          comparison = (pager.include_bookmark ? ">=" : ">")
          deployment_id, path = pager.current_bookmark
          scope = scope.where(
            "(deployment_id > ?) OR (deployment_id = ? AND path #{comparison} ?)",
            deployment_id,
            deployment_id,
            path
          )
        end
        scope.order(:deployment_id, :path)
      end
    end

    before_action :require_user
    before_action :require_feature_flag
    before_action :require_manage_lti_registrations
    before_action :validate_bulk_params, only: [:create_many]

    MAX_BULK_CREATE = 100

    CONTROLS_DEFAULT_LIST_PAGE_SIZE = 20
    CONTROLS_MAX_LIST_PAGE_SIZE = 100

    # @API List All Context Controls
    #
    # List all LTI ContextControls for the given LTI Registration.
    # These controls are partitioned by LTI Deployment, and have added
    # calculated fields for display in the Canvas UI.
    #
    # This endpoint is used to populate the Availability page for an LTI Registration
    # and may not be useful for general API Usage. For listing all ContextControls
    # for a given Deployment, see the LTI Deployments - List Controls for Deployment endpoint.
    #
    # @returns [Lti::Deployment]
    #
    # @example_request
    #
    #   curl -X GET 'https://<canvas>/api/v1/lti_registrations/<registration_id>/controls' \
    #        -H "Authorization: Bearer <token>"
    def index
      bookmarked = BookmarkedCollection.wrap(
        ContextControlsBookmarker,
        Lti::ContextControl
               .eager_load(:deployment)
               .where(registration:)
               .where.not(context_external_tools: { workflow_state: ["deleted", "disabled"] })
               .order(:deployment_id, :path)
      )

      paginated = Api.paginate(bookmarked, self, api_v1_lti_context_controls_index_url, per_page: controls_page_size)

      render json: (
        paginated
        .group_by(&:deployment)
        .map do |deployment, context_controls|
          context_controls_calculated_attrs = Lti::ContextControlService.preload_calculated_attrs(context_controls)
          lti_deployment_json(deployment, @current_user, session, context, context_controls:, context_controls_calculated_attrs:)
        end
      )
    rescue => e
      report_error(e)
      raise e
    end

    def controls_page_size
      per_page = params[:per_page].to_i
      if per_page <= 0
        CONTROLS_DEFAULT_LIST_PAGE_SIZE
      else
        [per_page, CONTROLS_MAX_LIST_PAGE_SIZE].min
      end
    end

    # @API Show LTI Context Control
    #
    # Display details of the specified LTI ContextControl for the specified LTI registration in this context.
    #
    # @returns Lti::ContextControl
    #
    # @example_request
    #
    #   curl -X GET 'https://<canvas>/api/v1/lti_registrations/<registration_id>/controls/<control_id>' \
    #        -H "Authorization: Bearer <token>"
    def show
      render json: lti_context_control_json(control, @current_user, session, context, include_users: true)
    rescue => e
      report_error(e)
      raise e
    end

    # @API Create LTI Context Control
    #
    # Create a new LTI ContextControl for the specified LTI registration in this context.
    # @argument account_id [integer] The Canvas ID of the Account that owns this. One of account_id or course_id must be present. Can also be a string.
    # @argument course_id [integer] The Canvas ID of the Course that owns this. One of account_id or course_id must be present. Can also be a string.
    # @argument deployment_id [integer] The Canvas ID of the ContextExternalTool that owns this, representing an LTI deployment.
    #   If absent, this ContextControl will be associated with the Deployment of this Registration at the Root Account level.
    #   If that is not present, this request will fail.
    # @argument available [boolean] The state of this tool in this context. `true` shows the tool in this context and all contexts
    #   below it. `false` disables the tool for this context and all contexts below it. Defaults to true.
    #
    # @returns Lti::ContextControl
    #
    # @example_request
    #
    #   curl -X POST 'https://<canvas>/api/v1/lti_registrations/<registration_id>/controls' \
    #        -H "Authorization: Bearer <token>" \
    #        -d '{
    #               "account_id": 1,
    #               "deployment_id": 1,
    #               "available": true
    #            }'
    #
    def create
      control_params = params_for_control(params)

      if control_params[:deployment_id].blank?
        return render_errors("No active deployment found for the root account.")
      end

      if control_params[:account_id].blank? && control_params[:course_id].blank?
        return render_errors("Either account_id or course_id must be present.")
      end

      unique_checks = control_params.slice(*Lti::ContextControlService.unique_check_attrs).compact
      if registration.context_controls.active.exists?(unique_checks)
        return render_errors("A context control for this deployment and context already exists.")
      end

      control = Lti::ContextControlService.create_or_update(control_params)

      render json: lti_context_control_json(control, @current_user, session, context, include_users: true), status: :created
    rescue Lti::ContextControlErrors => e
      render_errors(e.errors.full_messages)
    rescue => e
      report_error(e)
      raise e
    end

    # @API Bulk Create LTI Context Controls
    #
    # Create up to 100 new LTI ContextControls for the specified LTI registration in this context.
    # Control parameters are sent as a JSON array of objects, each with the same parameters as the Create LTI Context Control endpoint.
    # Note that if a control already exists for the specified context and deployment, it will be updated instead of created.
    #
    # @argument []account_id [integer] The Canvas ID of the Account that owns this. One of account_id or course_id must be present. Can also be a string.
    # @argument []course_id [integer] The Canvas ID of the Course that owns this. One of account_id or course_id must be present. Can also be a string.
    # @argument []deployment_id [integer] The Canvas ID of the ContextExternalTool that owns this, representing an LTI deployment.
    #   If absent, this ContextControl will be associated with the Deployment of this Registration at the Root Account level.
    #   If that is not present, this request will fail.
    # @argument []available [boolean] The state of this tool in this context. `true` shows the tool in this context and all contexts
    #   below it. `false` disables the tool for this context and all contexts below it. Defaults to true.
    #
    # @returns Lti::ContextControl
    #
    # @example_request
    #
    #   curl -X POST 'https://<canvas>/api/v1/lti_registrations/<registration_id>/controls' \
    #        -H "Authorization: Bearer <token>" \
    #        --json '[ \
    #                  { "account_id": 1, "available": false }, \
    #                  { "course_id": 1, "deployment_id": 1 }, \
    #                  { "account_id": 1, "deployment_id": 2 } \
    #                ]'
    #
    def create_many
      accounts = Account.find(create_many_params.pluck(:account_id).compact.uniq)
      courses = Course.find(create_many_params.pluck(:course_id).compact.uniq)
      cached_paths = {}
      cached_root_account_ids = (accounts + courses).to_h do |context|
        key = if context.is_a?(Account)
                "a#{context.id}"
              else
                "c#{context.id}"
              end
        [key, context.root_account_id]
      end

      chains = Account.account_chain_ids_for_multiple_accounts(accounts.pluck(:id) + courses.pluck(:account_id).uniq)
      chains.each do |account_id, chain|
        cached_paths["a#{account_id}"] = Lti::ContextControl.calculate_path_for_account_ids(chain)
      end
      courses.each do |course|
        cached_paths["c#{course.id}"] = Lti::ContextControl
                                        .calculate_path_for_course_id(course.id, chains[course.account_id])
      end

      controls = create_many_params.map do |control_params|
        key = if control_params[:account_id]
                "a#{control_params[:account_id]}"
              else
                "c#{control_params[:course_id]}"
              end
        control_params.permit(:account_id, :course_id, :deployment_id, :available).to_h.tap do |p|
          # insert_all requires that all hashes have the same keys
          p[:account_id] = nil unless p.key?(:account_id)
          p[:course_id] = nil unless p.key?(:course_id)
          p[:deployment_id] ||= root_account_deployment&.id
          p[:available] = true unless p.key?(:available)
          p[:registration_id] = registration.id
          p[:workflow_state] = :active
          p[:created_by_id] = @current_user.id
          p[:updated_by_id] = @current_user.id
          p[:root_account_id] = if p[:account_id].nil?
                                  cached_root_account_ids["c#{p[:course_id]}"]
                                else
                                  cached_root_account_ids["a#{p[:account_id]}"]
                                end
          p[:path] = cached_paths[key]
          p[:workflow_state] = :active
        end
      end

      ids = Lti::ContextControl.transaction do
        # Postgres's ON CONFLICT <conflict_target> can only handle a single unique index at a time,
        # hence the split
        control_ids = Lti::ContextControl.upsert_all(controls.filter { |c| c[:course_id].present? }, unique_by: [:course_id, :deployment_id], returning: :id).rows.flatten
        control_ids + Lti::ContextControl.upsert_all(controls.filter { |c| c[:account_id].present? }, unique_by: [:account_id, :deployment_id], returning: :id).rows.flatten
      end

      controls = Lti::ContextControl.where(id: ids).preload(:account, :course, :created_by, :updated_by).order(id: :asc)
      calculated_attrs = Lti::ContextControlService.preload_calculated_attrs(controls)

      json = controls.map do |control|
        lti_context_control_json(control, @current_user, session, context, include_users: true, calculated_attrs: calculated_attrs[control.id])
      end

      render json:, status: :created
    end

    # @API Modify a Context Control
    #
    # Changes the availability of a context control. This endpoint can only be used
    # to change the availability of a context control; no other attributes about the
    # control (such as which course or account it belongs to) can be changed here.
    # To change those values, the control should be deleted and a new one created
    # instead.
    #
    # Returns the context control with its new availability value applied.
    #
    # @argument available [Required, boolean] the new value for this control's availability
    # @returns Lti::ContextControl
    #
    # @example_request
    #
    #   curl "https://<canvas>/api/v1/lti_registrations/<registration_id>/controls/<id>" \
    #        -X PUT \
    #        -F "available=true" \
    #        -H "Authorization: Bearer <token>"
    def update
      available = value_to_boolean(params.require(:available))
      control.update!(available:)

      render json: lti_context_control_json(control, @current_user, session, context, include_users: true)
    rescue => e
      report_error(e)
      raise e
    end

    # @API Delete a Context Control
    #
    # Deletes a context control. Returns the control that is now deleted.
    #
    # @returns Lti::ContextControl
    #
    # @example_request
    #
    #   curl "https://<canvas>/api/v1/lti_registrations/<registration_id>/controls/<id>" \
    #        -X DELETE \
    #        -H "Authorization: Bearer <token>"
    def delete
      control.destroy

      render json: lti_context_control_json(control, @current_user, session, context, include_users: true)
    rescue => e
      report_error(e)
      raise e
    end

    private

    def render_errors(errors, status: :unprocessable_entity)
      errors = [errors] unless errors.is_a?(Array)
      render json: { errors: }, status:
    end

    def error_message_for_control(control, index)
      { value: params[:_json][index].to_unsafe_h, errors: control.errors.full_messages }
    end

    def params_for_control(params)
      params.permit(:account_id, :course_id, :deployment_id, :available).to_h.tap do |p|
        p[:deployment_id] ||= root_account_deployment&.id
        p[:available] = true unless p.key?(:available)
        p[:workflow_state] = :active
        p[:created_by] = @current_user
        p[:updated_by] = @current_user
        p[:registration_id] = registration.id
      end
    end

    def root_account_deployment
      @root_account_deployment ||= registration.deployments.active.find_by(context: registration.root_account)
    end

    def control
      @control ||= Lti::ContextControl.active.find_by(id: params[:id], registration:)
      raise ActiveRecord::RecordNotFound unless @control

      @control
    end

    def registration
      @registration ||= Lti::Registration.active.find(params[:registration_id])
    end

    def context
      registration.account
    end

    def report_error(exception, code = nil)
      code ||= response_code_for_rescue(exception) if exception
      InstStatsd::Statsd.increment("canvas.lti_context_controls_controller.request_error", tags: { action: action_name, code: })
    end

    def create_many_params
      @create_many_params ||= params[:_json]
    end

    def validate_bulk_params
      if !create_many_params.is_a?(Array) || create_many_params.empty?
        return render_errors("Invalid parameters. Expected an array of context control parameters.")
      end

      if create_many_params.size > MAX_BULK_CREATE
        return render_errors("Cannot create more than #{MAX_BULK_CREATE} context controls at once")
      end

      if create_many_params.any? { |p| p[:account_id].blank? && p[:course_id].blank? }
        return render_errors("Either account_id or course_id must be present for each context control.")
      end

      if create_many_params.any? { |p| p[:account_id].present? && p[:course_id].present? }
        return render_errors("Either account_id or course_id must be present for each context control, but not both.")
      end

      if create_many_params.any? { |p| p[:deployment_id].blank? } && root_account_deployment.blank?
        render_errors("No active deployment found for the root account. Please specify a deployment_id for each control.")
      end

      if create_many_params.pluck(:account_id, :course_id).uniq.size != create_many_params.size
        render_errors("Cannot create multiple context controls for the same context. Please specify unique account_id or course_id for each context control.")
      end
    end

    def require_manage_lti_registrations
      require_context_with_permission(context, :manage_lti_registrations)
    end

    def require_feature_flag
      unless context.root_account.feature_enabled?(:lti_registrations_next)
        render json: { error: "The specified resource does not exist." }, status: :not_found
      end
    end
  end
end

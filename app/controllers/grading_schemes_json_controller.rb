# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class GradingSchemesJsonController < ApplicationController
  extend GradingSchemeSerializer

  GRADING_SCHEMES_LIMIT = 100
  USED_LOCATIONS_PER_PAGE = 100
  before_action :require_context
  before_action :require_user
  before_action :validate_read_permission, only: %i[grouped_list detail_list summary_list show]

  def grouped_list
    standards = grading_standards_for_context.sorted.limit(GRADING_SCHEMES_LIMIT)
    render json: {
      archived: standards.select(&:archived?).map do |grading_standard|
        GradingSchemesJsonController.to_grading_scheme_json(grading_standard, @current_user)
      end,
      active: standards.select(&:active?).map do |grading_standard|
        GradingSchemesJsonController.to_grading_scheme_json(grading_standard, @current_user)
      end
    }
  end

  def detail_list
    grading_standards = grading_standards_for_context.sorted.limit(GRADING_SCHEMES_LIMIT)
    respond_to do |format|
      format.json do
        render json: grading_standards.map { |grading_standard|
          GradingSchemesJsonController.to_grading_scheme_json(grading_standard, @current_user)
        }
      end
    end
  end

  def summary_list
    grading_standards = grading_standards_for_context.sorted.limit(GRADING_SCHEMES_LIMIT)
    respond_to do |format|
      format.json do
        render json: grading_standards.map { |grading_standard|
          GradingSchemesJsonController.to_grading_scheme_summary_json(grading_standard)
        }
      end
    end
  end

  def show
    grading_standard = grading_standards_for_context.find(params[:id])
    respond_to do |format|
      format.json { render json: GradingSchemesJsonController.to_grading_scheme_json(grading_standard, @current_user) }
    end
  end

  def show_default_grading_scheme
    respond_to do |format|
      format.json do
        render json: GradingSchemesJsonController.default_to_json(
          @current_user,
          @context
        )
      end
    end
  end

  def create
    if authorized_action(@context, @current_user, :manage_grades)
      grading_standard = @context.grading_standards.build(grading_scheme_payload)

      respond_to do |format|
        if grading_standard.save
          track_create_metrics(grading_standard)
          format.json { render json: GradingSchemesJsonController.to_grading_scheme_json(grading_standard, @current_user) }
        else
          format.json { render json: grading_standard.errors, status: :bad_request }
        end
      end
    end
  end

  def update
    grading_standard = grading_standards_for_context.find(params[:id])
    if authorized_action(grading_standard, @current_user, :manage)
      grading_standard.user = @current_user

      respond_to do |format|
        if grading_standard.update(grading_scheme_payload)
          track_update_metrics(grading_standard)
          format.json { render json: GradingSchemesJsonController.to_grading_scheme_json(grading_standard, @current_user) }
        else
          format.json { render json: grading_standard.errors, status: :bad_request }
        end
      end
    end
  end

  def used_locations
    grading_standard = grading_standards_for_context.find(params[:id])
    return unless authorized_action(grading_standard, @current_user, :manage)

    render json: used_locations_for(grading_standard)
  end

  def archive
    grading_standard = grading_standards_for_context.find(params[:id])
    if authorized_action(grading_standard, @current_user, :manage)
      respond_to do |format|
        if grading_standard.archive!
          track_update_metrics(grading_standard)
          format.json { render json: GradingSchemesJsonController.to_grading_scheme_json(grading_standard, @current_user) }
        else
          if grading_standard.halted_because
            grading_standard.errors.add(:workflow_state, grading_standard.halted_because)
          end

          format.json { render json: grading_standard.errors, status: :bad_request }
        end
      end
    end
  end

  def unarchive
    grading_standard = GradingStandard.archived.for_context(@context).find(params[:id])
    if authorized_action(grading_standard, @current_user, :manage)
      respond_to do |format|
        if grading_standard.unarchive!
          track_update_metrics(grading_standard)
          format.json { render json: GradingSchemesJsonController.to_grading_scheme_json(grading_standard, @current_user) }
        else
          if grading_standard.halted_because
            grading_standard.errors.add(:workflow_state, grading_standard.halted_because)
          end

          format.json { render json: grading_standard.errors, status: :bad_request }
        end
      end
    end
  end

  def destroy
    grading_standard = grading_standards_for_context.find(params[:id])
    if authorized_action(grading_standard, @current_user, :manage)
      respond_to do |format|
        if grading_standard.destroy
          format.json { render json: {} }
        else
          format.json { render json: grading_standard.errors, status: :bad_request }
        end
      end
    end
  end

  def used_locations_for(grading_standard)
    GuardRail.activate(:secondary) do
      scope = grading_standard.used_locations
                              .joins("INNER JOIN #{Course.quoted_table_name} ON assignments.context_type = 'Course' AND assignments.context_id = courses.id")
                              .order("courses.name ASC, title ASC")

      used_locations = Api.paginate(
        scope,
        self,
        account_grading_schemes_used_locations_path(
          account_id: @context.id, id: grading_standard.id
        ),
        per_page: USED_LOCATIONS_PER_PAGE
      )

      used_locations_to_json(used_locations)
    end
  end

  def used_locations_to_json(used_locations)
    used_locations.group_by(&:context).map do |course, assignments|
      course_json = course.as_json(only: [:id, :name], methods: [:concluded?], include_root: false)
      course_json[:assignments] = assignments.as_json(only: [:id, :title], include_root: false)
      course_json
    end
  end

  def self.to_grading_standard_data(grading_scheme_json_data)
    # converts a GradingScheme UI model's data field format from:
    # [{"name": "A", "value": .94}, {"name": "B", "value": .84}, ]
    # to the GradingStandard ActiveRecord's data field format:
    # { "A" => 0.94, "B" => .84, }
    grading_standard_data = {}
    grading_scheme_json_data.map do |grading_scheme_data_row|
      grading_standard_data[grading_scheme_data_row["name"]] = grading_scheme_data_row["value"]
    end
    grading_standard_data
  end

  def self.json_serialized_fields
    %w[id title scaling_factor points_based context_type context_id workflow_state]
  end

  def grading_standards_for_context
    include_archived = params[:include_archived] == "true"
    if params[:assignment_id]
      @assignment = @context.assignments.find(params[:assignment_id])
      return GradingStandard.for(@assignment, include_archived:)
    end
    GradingStandard.for(@context, include_archived:)
  end

  def self.default_canvas_grading_standard(context)
    grading_standard_data = GradingStandard.default_grading_standard
    props = {}
    props["title"] = I18n.t("Default Canvas Grading Scheme")
    props["data"] = grading_standard_data
    props["scaling_factor"] = 1.0
    props["points_based"] = false
    context.grading_standards.build(props)
  end

  private

  def grading_scheme_payload
    { title: params[:title],
      data: GradingSchemesJsonController.to_grading_standard_data(params[:data]),
      points_based: params[:points_based],
      scaling_factor: params[:scaling_factor] }
  end

  def track_update_metrics(grading_standard)
    if grading_standard.changed.include?("points_based")
      InstStatsd::Statsd.increment("grading_scheme.update.points_based") if grading_standard.points_based
      InstStatsd::Statsd.increment("grading_scheme.update.percentage_based") unless grading_standard.points_based
    end
    if grading_standard.changed.include?("workflow_state")
      InstStatsd::Statsd.increment("grading_scheme.update.workflow_archived") if grading_standard.archived
      InstStatsd::Statsd.increment("grading_scheme.update.workflow_active") if grading_standard.active
      InstStatsd::Statsd.increment("grading_scheme.update.workflow_deleted") if grading_standard.deleted
    end
  end

  def track_create_metrics(grading_standard)
    InstStatsd::Statsd.increment("grading_scheme.create.points_based") if grading_standard.points_based
    InstStatsd::Statsd.increment("grading_scheme.create.percentage_based") unless grading_standard.points_based
  end

  def validate_read_permission
    authorized_action(@context, @current_user, @context.grading_standard_read_permission)
  end
end

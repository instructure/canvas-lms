#
# Copyright (C) 2012 Instructure, Inc.
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

class OutcomesImportApiController < ApplicationController
  include Api::V1::Outcome
  include Api::V1::ContentMigration

  before_action :require_user, :can_manage_global_outcomes, :has_api_config

  def available
    render json: AcademicBenchmark.list_of_available_guids
  end

  def create
    return render json: { error: "must specify a guid to import" } unless params[:guid]
    begin
      err_msg = "Invalid parameters"
      options = valid_options(params)
      valid_guid(params[:guid])

      err_msg = "Import failed to queue"

      # AcademicBenchmark.queue_migration_for_guid can raise Canvas::Migration::Error
      migration = AcademicBenchmark.import(params[:guid], options)

      if migration
        render json: { migration_id: migration.id, guid: params[:guid] }
      else
        render json: { error: err_msg }
      end
    rescue StandardError => e
      render json: { error: "#{err_msg}: #{e.message}" }
    end
  end

  def migration_status
    return render json: { error: "must specify a migration id" } unless params[:migration_id]

    begin
      cm = ContentMigration.find(params[:migration_id])
      cm_issues = cm.migration_issues
      cmj = content_migration_json(cm, @current_user, session)
      cmj[:migration_issues] = migration_issues_json(cm_issues, cm, @current_user, session)
      render json: cmj
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "no content migration matching id #{params[:migration_id]}" }
    end
  end

  protected

  def can_manage_global_outcomes
    authorized_action(Account.site_admin, @current_user, :manage_global_outcomes)
  end

  def has_api_config
    err = AcademicBenchmark.check_config
    if err.nil?
      true
    else
      render json: { error: "The AcademicBenchmark API is not configured #{err}" }
      false
    end
  end

  ##
  # valid guids can only contain hex digits (letters all upper case),
  # and must be separated between a '-' [8-4-4-4-12]
  #
  #   example:  A833C528-901A-11DF-A622-0C319DFF4B22
  ##
  def valid_guid(guid)
    unless guid =~ /[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}/i
      raise "GUID is invalid: #{guid}"
    end
  end

  def parse_int(value)
    Integer value
  rescue
    raise "invalid value, must be integer: #{value}"
  end

  def valid_options(hash)
    options = {}
    if hash.key? :calculation_method
      options[:calculation_method] = parse_calculation_method hash[:calculation_method]
      options[:calculation_int] = parse_calculation_int options[:calculation_method], hash[:calculation_int]
    end
    options[:mastery_points] = parse_int hash[:mastery_points] if hash.key? :mastery_points
    options[:points_possible] = parse_int hash[:points_possible] if hash.key? :points_possible
    unless hash[:ratings].nil?
      raise "ratings expected to be an array" unless hash[:ratings].is_a?(Array)
      options[:ratings] = hash[:ratings].map {|r| parse_rating(r)}
    end
    options
  end

  def parse_calculation_method(value)
    unless LearningOutcome.valid_calculation_method?(value)
      raise "invalid calculation_method: #{value}"
    end
    value
  end

  def parse_calculation_int(calc_method, value)
    int = value.nil? ? nil : parse_int(value)
    unless LearningOutcome.valid_calculation_int?(int, calc_method)
      raise "invalid calculation_int: #{value}"
    end
    int
  end

  def parse_rating(rating)
    if rating.nil? || !rating.is_a?(ActionController::Parameters)
      raise "invalid ratings value: #{rating}"
    end
    if rating[:description].nil? || !rating[:description].is_a?(String)
      raise "invalid description value: #{rating[:description]}"
    end
    { :description => rating[:description], :points => parse_int(rating[:points]) }
  end
end

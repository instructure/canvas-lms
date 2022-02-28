# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module ContentExportApiHelper
  def create_content_export_from_api(params, context, current_user)
    export = context.content_exports.build
    export.user = current_user
    export.workflow_state = "created"
    export.settings[:skip_notifications] = true if value_to_boolean(params[:skip_notifications])

    # ZipExporter accepts unhashed asset strings, to avoid having to instantiate all the files and folders
    if params[:select]
      selected_content = ContentMigration.process_copy_params(params[:select]&.to_unsafe_h,
                                                              for_content_export: true,
                                                              return_asset_strings: params[:export_type] == ContentExport::ZIP,
                                                              global_identifiers: export.can_use_global_identifiers?)
    end

    case params[:export_type]
    when "qti"
      export.export_type = ContentExport::QTI
      export.selected_content = selected_content || { all_quizzes: true }
    when "zip"
      export.export_type = ContentExport::ZIP
      export.selected_content = selected_content || { all_attachments: true }
    when "quizzes2"
      if params[:quiz_id].nil? || params[:quiz_id] !~ Api::ID_REGEX
        return render json: { message: "quiz_id required and must be a valid ID" },
                      status: :bad_request
      elsif !context.quizzes.exists?(params[:quiz_id])
        return render json: { message: "Quiz could not be found" }, status: :bad_request
      else
        export.export_type = ContentExport::QUIZZES2
        # we pass the quiz_id of the quiz we want to clone here
        export.selected_content = params[:quiz_id]
      end
    else
      export.export_type = ContentExport::COMMON_CARTRIDGE
      export.selected_content = selected_content || { everything: true }
    end
    # recheck, since the export type influences permissions (e.g., students can download zips of non-locked files, but not common cartridges)
    return unless authorized_action(export, current_user, :create)

    opts = params.permit(:version, :failed_assignment_id).to_unsafe_h
    export.progress = 0

    # Need the time zone identifier name and NOT the friendly name
    tz_identifier = ActiveSupport::TimeZone::MAPPING[Time.zone.name]
    export.settings[:user_time_zone] = tz_identifier if tz_identifier.present?
    if export.save
      export.queue_api_job(opts)
    end
    export
  end
end

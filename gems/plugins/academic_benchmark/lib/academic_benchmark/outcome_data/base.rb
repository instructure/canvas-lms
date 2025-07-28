# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module AcademicBenchmark::OutcomeData
  class Base
    # This used to be an OpenStruct
    # Many of these options are likely not relevant to AcademicBenchmark,
    # but were added to this list from a review of the surrounding codebase,
    # and determining what things might possibly get added to the settings
    # hash passed to this point, including from the AcademicBenchmark plugin's
    # settings, ContentMigration controller (both keys referenced in code, and
    # documented API parameters), methods in ContentMigration, and more.
    # Ideally this struct would only contain options relevant to AcademicBenchmark,
    # and the initializer would slice the incoming hash to those options, but
    # given the apparent lack of specs in this area of the code, it seems safer
    # to just try and allow more possible options, instead of trying to find
    # everything that might be used.
    Options = Struct.new(
      :api_key,
      :api_url,
      :archive_file,
      :attachment_id,
      :attachment_path_id_lookup,
      :authority,
      :base_download_dir,
      :common_core_guid,
      :content_export_id,
      :content_migration_id,
      :content_migration,
      :converter_class,
      :copy_options,
      :course_archive_download_url,
      :date_shift_options,
      :document,
      :domain_substitution_map,
      :export_archive_path,
      :file_url,
      :folder_id,
      :id_prepender,
      :import_blueprint_settings,
      :import_immediately,
      :import_in_progress_notice,
      :import_quizzes_next,
      :imported_assets,
      :importer_skips,
      :initiated_source,
      :insert_into_module_id,
      :insert_into_module_position,
      :insert_into_module_type,
      :is_discussion_checkpoints_enabled,
      :job_ids,
      :last_error,
      :master_course_export_id,
      :master_migration_id,
      :migration_ids_to_import,
      :migration_options,
      :migration_type,
      :move_to_assignment_group_id,
      :no_archive_file,
      :no_selective_import,
      :overwrite_questions,
      :overwrite_quizzes,
      :partner_id,
      :partner_key,
      :prefer_existing_tools,
      :provides,
      :publication,
      :question_bank_id,
      :question_bank_name,
      :required_options_validator,
      :requires_file_upload,
      :skip_import_notification,
      :skip_job_progress,
      :source_course_id,
      :strand,
      :unzipped_file_path,
      :user_id,
      :valid_contexts,
      :worker_class,
      :worker,
      keyword_init: true
    )

    def initialize(options = {})
      @options = Options.new(**options)
    end
  end
end

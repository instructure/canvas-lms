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
    Options = Struct.new(:authority,
                         :publication,
                         :partner_id,
                         :partner_key,
                         :converter_class,
                         :document,
                         :import_immediately,
                         :migration_type,
                         :archive_file,
                         :no_archive_file,
                         :skip_import_notification,
                         :skip_job_progress,
                         :content_migration,
                         :content_migration_id,
                         :user_id,
                         :migration_options,
                         keyword_init: true)

    def initialize(options = {})
      @options = Options.new(**options)
    end
  end
end

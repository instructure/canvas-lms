# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Importers
  class AccountContentImporter < Importer
    self.item_class = Account

    def self.import_content(account, data, _params, migration)
      Importers::ContentImporterHelper.add_assessment_id_prepend(account, data, migration)

      Importers::AssessmentQuestionImporter.process_migration(data, migration)
      Importers::LearningOutcomeImporter.process_migration(data, migration)

      migration.resolve_content_links!

      migration.progress = 100
      migration.workflow_state = :imported
      migration.save
    end
  end
end

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

module QuizzesNext::Importers
  class CourseContentImporter
    def initialize(data, migration)
      @migration = migration
      @data = data
    end

    def import_content(params)
      context = @migration.context
      return unless context.instance_of?(Course)
      ::Importers::CourseContentImporter.
        import_content(context, @data, params, @migration)

      migration_lti!
      mark_completion!
    end

    private

    def migration_lti!
      lti_assignment_quiz_set = []
      @migration.imported_migration_items_by_class(Assignment).each do |assignment|
        next unless assignment.quiz?
        quiz = assignment.quiz
        lti_assignment_quiz_set << [assignment.global_id, quiz.global_id]
        assignment.workflow_state = 'importing'
        assignment.importing_started_at = Time.zone.now
        assignment.quiz_lti! && assignment.save!

        # Quizzes will be created in Quizzes.Next app
        # assignment.quiz_lti! breaks relation to quiz. Destroying Quizzes:Quiz wouldn't
        # mark assginment to be deleted.
        quiz.destroy
      end
      setup_assets_imported(lti_assignment_quiz_set)
    end

    def setup_assets_imported(lti_assignment_quiz_set)
      imported_asset_hash = @migration.migration_settings[:imported_assets] || {}
      imported_asset_hash[:lti_assignment_quiz_set] = lti_assignment_quiz_set
      @migration.migration_settings[:imported_assets] = imported_asset_hash
    end

    def mark_completion!
      @migration.workflow_state = :imported
      @migration.save!
    end
  end
end

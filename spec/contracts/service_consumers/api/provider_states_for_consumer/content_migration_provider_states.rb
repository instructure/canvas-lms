#
# Copyright (C) 2018 - present Instructure, Inc.
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

# require_relative '../../pact_config'
# require_relative '../pact_setup'

PactConfig::Consumers::ALL.each do |consumer|
  Pact.provider_states_for consumer do

    provider_state 'content migration data' do
      set_up do
        course = Pact::Canvas.base_state.course
        content_migration_item = ContentMigration.create(
          context: course,
          workflow_state: 'imported',
          migration_settings: {
            imported_assets: {
              lti_assignment_quiz_set: [[ 11, 111]]
            },
            import_quizzes_next: true,
            import_immediately: true,
            copy_options: {
              everything: true
            },
            migration_ids_to_import: {
              copy: {
                everything: true,
                assignment_groups: {}
              }
            }
          },
          migration_type: 'common_cartridge_importer',
          progress: 100
        )
        content_migration_item.save!
        content_migration_item.attachment = Attachment.create!(
          context: content_migration_item,
          filename: 'text.txt',
          uploaded_data: StringIO.new("test file"),
          content_type: 'binary/octet-stream'
        )
        content_migration_item.save!
      end
    end
  end
end

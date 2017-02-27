# Copyright (C) 2016 Instructure, Inc.
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

require 'spec_helper'
require_relative '../../lti_spec_helper'

RSpec.describe Lti::ContentMigrationService do
  include WebMock::API
  include LtiSpecHelper

  describe '.begin_exports(course, options = {})' do
    before do
      # creates @course :-(
      course_model
      @root_account = @course.root_account
      @root_account.ensure_defaults
      @root_account.save!
      @tool = @course.context_external_tools.build({
        name:          'a',
        domain:        'lti.example.com',
        consumer_key:  '12345',
        shared_secret: 'secret',
      })
      @tool.settings = Importers::ContextExternalToolImporter.create_tool_settings({
        settings: {
          'custom_fields' => {
            'course_id'=>'$Canvas.course.id',
          },
          'content_migration' => {
            'export_start_url'=>'https://lti.example.com/begin_export',
            'import_start_url'=>'https://lti.example.com/begin_import'
          },
        }
      })
      @tool.save!

      response_body = {
        status_url: 'https://lti.example.com/export/42/status',
        fetch_url: 'https://lti.example.com/export/42',
      }.to_json
      stub_request(:post, 'https://lti.example.com/begin_export').
        to_return(:status => 200, :body => response_body, :headers => {})
      @return_value = Lti::ContentMigrationService.begin_exports(@course)
    end

    it 'must return a hash with the data returned by the tool for the next steps in the process' do
      expect(@return_value).to include "lti_#{@tool.id}" => an_instance_of(Lti::ContentMigrationService::Exporter)
    end
  end

  describe '.importer_for(key)' do
    it 'must return an Importer with the original_tool_id set when the key is valid' do
      importer = Lti::ContentMigrationService.importer_for('lti_42')
      expect(importer).to be_an(Lti::ContentMigrationService::Importer)
      expect(importer.original_tool_id).to eq 42
    end

    it "must return nil when the key doesn't include an id" do
      importer = Lti::ContentMigrationService.importer_for('lti_')
      expect(importer).to be_nil
    end

    it 'must return nil when the key has extra stuff at the end' do
      importer = Lti::ContentMigrationService.importer_for('lti_23_foobar')
      expect(importer).to be_nil
    end
  end
end

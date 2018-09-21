#
# Copyright (C) 2016 - present Instructure, Inc.
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
require_relative '../../../lti_spec_helper'

RSpec.describe Lti::ContentMigrationService::Importer do
  include WebMock::API
  include LtiSpecHelper

  let(:course) { course_model }
  let(:content_migration) { ContentMigration.new }
  let(:tool) { course.context_external_tools.create!({
    name:          'a',
    domain:        'lti.example.com',
    consumer_key:  '12345',
    shared_secret: 'sekret',
  }) }
  let(:importer) { Lti::ContentMigrationService::Importer.new(tool.id) }
  let(:replacement_tool) { course.context_external_tools.create!({
    name:          'b',
    domain:        'lti.example.com',
    consumer_key:  '12345',
    shared_secret: 'sekret',
  }) }
  let(:content) { {foo: 'bar', baz: 'qux'} }
  let(:root_account) { course.root_account }
  let(:import_url) { 'https://lti.example.com/begin_import' }

  describe '#send_imported_content(course, content)' do
    it 'must raise an error when the tool has been deleted and not replaced by another with the same domain' do
      tool.workflow_state = 'deleted'
      tool.save!
      expect { importer.send_imported_content(course, content_migration, content) }.
        to raise_error "Unable to find external tool to import content."
    end

    it 'must return nil when the tool has been deleted and the replacement is not configured for content migrations' do
      tool.workflow_state = 'deleted'
      tool.save!
      replacement_tool
      expect { importer.send_imported_content(course, content_migration, content) }.
        to raise_error "Unable to find external tool to import content."
    end


    context 'using the original configuration' do
      before do
        tool.settings = Importers::ContextExternalToolImporter.create_tool_settings({
          settings: {
            'custom_fields' => {
              'course_id'=>'$Canvas.course.id',
            },
            'content_migration' => {
              'export_start_url' => 'https://lti.example.com/begin_export',
              'import_start_url' => import_url
            },
          }
        })
        tool.save!

        response_body = {
          status_url: 'https://lti.example.com/imports/42/status',
        }.to_json
        stub_request(:post, import_url).
          to_return(:status => 200, :body => response_body, :headers => {})

        @response = importer.send_imported_content(course, content_migration, content)
      end

      it 'must return the importer' do
        expect(@response).to eq importer
      end

      it 'must retain the import status url' do
        status_url = importer.instance_variable_get("@status_url")
        expect(status_url).to eq 'https://lti.example.com/imports/42/status'
      end

      it 'must post the context_id to the tool' do
        assert_requested(:post, import_url, {
          body: hash_including(context_id: Lti::Asset.opaque_identifier_for(course))
        })
      end

      it 'must post the tool_consumer_instance_guid to the tool' do
        assert_requested(:post, import_url, {
          body: hash_including(tool_consumer_instance_guid: root_account.lti_guid)
        })
      end

      it 'must include any variable expansions requested by the tool' do
        assert_requested(:post, import_url, {
          body: hash_including('custom_course_id' => @course.id.to_s)
        })
      end

      it 'must include a JWT as the Authorization header for each request' do
        assert_requested(:post, import_url, {
          headers: {'Authorization' => /^Bearer [a-zA-Z0-9\-_]{36,}\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]{43}$/}
        })
      end

      it 'must include the supplied import data as the "data" key in the body' do
        assert_requested(:post, import_url, {
          body: hash_including(data: content)
        })
      end
    end

    it 'must start the import using the replacement tool when it is active and fully configured' do
        tool.settings = Importers::ContextExternalToolImporter.create_tool_settings({
          settings: {
            'custom_fields' => {
              'course_id'=>'$Canvas.course.id',
            },
            'content_migration' => {
              'export_start_url' => 'https://lti.example.com/begin_export',
              'import_start_url' => import_url
            },
          }
        })
        tool.workflow_state = 'deleted'
        tool.save!
        replacement_tool.settings = Importers::ContextExternalToolImporter.create_tool_settings({
          settings: {
            'custom_fields' => {
              'course_id'=>'$Canvas.course.id',
            },
            'content_migration' => {
              'export_start_url' => 'https://lti.example.com/begin_export',
              'import_start_url' => 'https://lti.example.com/begin_import_again'
            },
          }
        })
        replacement_tool.save!

        response_body = {
          status_url: 'https://lti.example.com/imports/42/status',
        }.to_json
        stub_request(:post, 'https://lti.example.com/begin_import_again').
          to_return(:status => 200, :body => response_body, :headers => {})
        importer.send_imported_content(course, content_migration, content)
        assert_requested(:post, 'https://lti.example.com/begin_import_again', {
          body: hash_including(context_id: Lti::Asset.opaque_identifier_for(course))
        })
    end
  end

  describe '#import_completed?' do
    before do
      tool.settings = Importers::ContextExternalToolImporter.create_tool_settings({
        settings: {
          'custom_fields' => {
            'course_id'=>'$Canvas.course.id',
          },
          'content_migration' => {
            'export_start_url' => 'https://lti.example.com/begin_export',
            'import_start_url' => import_url
          },
        }
      })
      tool.save!
      importer.instance_variable_set("@tool", tool)
      importer.instance_variable_set("@status_url", 'https://lti.example.com/imports/42/status')
    end

    it 'must return false when the remote end returns a status other than "completed"' do
      response_body = {
        status: 'processing',
      }.to_json
      stub_request(:get, 'https://lti.example.com/imports/42/status').
        to_return(:status => 200, :body => response_body, :headers => {})
      expect(importer).not_to be_import_completed
    end

    it 'must return true when the remote end returns a status of "completed"' do
      response_body = {
        status: 'completed',
      }.to_json
      stub_request(:get, 'https://lti.example.com/imports/42/status').
        to_return(:status => 200, :body => response_body, :headers => {})
      expect(importer).to be_import_completed
    end
  end
end

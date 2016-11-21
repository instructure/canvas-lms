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

RSpec.describe Lti::ContentMigrationService::Migrator do
  include WebMock::API
  include LtiSpecHelper

  describe '#export_completed?' do
    let(:course) { course_model }
    let(:tool) { course.context_external_tools.create!({
      name:          'a',
      domain:        'lti.example.com',
      consumer_key:  '12345',
      shared_secret: 'sekret',
    }) }
    let(:migrator) { Lti::ContentMigrationService::Migrator.new(course, tool) }
    let(:status_url) { 'https://lti.example.com/export/42/status' }

    before do
      migrator.instance_variable_set(:@status_url, status_url)
    end

    it 'must return true when the remote service indicates the export status is completed' do
      stub_request(:get, status_url).
        to_return(status: 200, body: {status: 'completed'}.to_json)
      expect(migrator).to be_export_completed
    end

    it 'must raise an exception with the response message when the export has failed' do
      stub_request(:get, status_url).
        to_return(status: 200, body: {status: 'failed', message: 'Oh, noes!'}.to_json)
      expect { migrator.export_completed? }.
        to raise_error RuntimeError, 'Oh, noes!'
    end

    it 'must return false when the remote service indicates the export status neither completed or failed' do
      stub_request(:get, status_url).
        to_return(status: 200, body: {status: 'foobar'}.to_json)
      expect(migrator).to_not be_export_completed
    end
  end

  describe '#retrieve_export' do
    let(:course) { course_model }
    let(:tool) { course.context_external_tools.create!({
      name:          'a',
      domain:        'lti.example.com',
      consumer_key:  '12345',
      shared_secret: 'sekret',
    }) }
    let(:migrator) { Lti::ContentMigrationService::Migrator.new(course, tool) }
    let(:fetch_url) { 'https://lti.example.com/export/42' }

    before do
      migrator.instance_variable_set(:@fetch_url, fetch_url)
    end

    it 'must return nil when the export status has indicated failure' do
      migrator.instance_variable_set(:@export_status, 'failed')
      expect(migrator.retrieve_export).to be_nil
    end

    it 'must return the parsed response body when the export status indicated completion' do
      response_body = {foo: 'bar', baz: 'qux'}.to_json
      stub_request(:get, fetch_url).
        to_return(:status => 200, :body => response_body, :headers => {})
      migrator.instance_variable_set(:@export_status, 'completed')
      expect(migrator.retrieve_export).to eq({'foo' => 'bar', 'baz' => 'qux'})
    end

    it 'must raise an exception when the response status is something other than 200' do
      response_body = {foo: 'bar', baz: 'qux'}.to_json
      stub_request(:get, fetch_url).
        to_return(:status => 404, :body => response_body, :headers => {})
      expect { migrator.retrieve_export }.
        to raise_error RuntimeError, /404/
    end
  end

  describe '#start!' do
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
      @migrator = Lti::ContentMigrationService::Migrator.new(@course, @tool)
      @migrator.start!
    end

    it 'must post the context_id to the configured tools' do
      assert_requested(:post, 'https://lti.example.com/begin_export', {
        body: hash_including(context_id: Lti::Asset.opaque_identifier_for(@course))
      })
    end

    it 'must post the tool_consumer_instance_guid to the configured tools' do
      assert_requested(:post, 'https://lti.example.com/begin_export', {
        body: hash_including(tool_consumer_instance_guid: @root_account.lti_guid)
      })
    end

    it 'must include a JWT as the Authorization header for each request' do
      assert_requested(:post, 'https://lti.example.com/begin_export', {
        headers: {'Authorization' => /^Bearer [a-zA-Z0-9\-_]{36,}\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]{43}$/}
      })
    end

    it 'must include any variable expansions requested by the tool' do
      assert_requested(:post, 'https://lti.example.com/begin_export', {
        body: hash_including('custom_course_id' => @course.id.to_s)
      })
    end

    it 'must mark the migration as successfully started' do
      expect(@migrator).to be_successfully_started
    end
  end

  describe '#successfully_started?' do
    let(:migrator) { Lti::ContentMigrationService::Migrator.new('', '') }
    it 'must return true when status and fetch urls are both present' do
      migrator.instance_variable_set(:@status_url, 'junk')
      migrator.instance_variable_set(:@fetch_url, 'junk')
      expect(migrator).to be_successfully_started
    end

    it 'must return false when there are not status and fetch urls' do
      expect(migrator).to_not be_successfully_started
    end
  end
end

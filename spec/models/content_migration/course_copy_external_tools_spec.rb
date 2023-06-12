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

require_relative "course_copy_helper"

describe ContentMigration do
  context "course copy external tools" do
    include_context "course copy"

    before :once do
      @tool_from = @copy_from.context_external_tools.create!(name: "new tool", consumer_key: "key", shared_secret: "secret", custom_fields: { "a" => "1", "b" => "2" }, url: "http://www.example.com")
      @tool_from.settings[:course_navigation] = { url: "http://www.example.com", text: "Example URL" }
      @tool_from.save!
    end

    it "copies external tools" do
      @copy_from.tab_configuration = [
        { "id" => 0 }, { "id" => "context_external_tool_#{@tool_from.id}" }, { "id" => 14 }
      ]
      @copy_from.save!

      run_course_copy

      expect(@copy_to.context_external_tools.count).to eq 1
      tool_to = @copy_to.context_external_tools.first

      expect(@copy_to.tab_configuration).to eq [
        { "id" => 0 }, { "id" => "context_external_tool_#{tool_to.id}" }, { "id" => 14 }
      ]

      expect(tool_to.name).to eq @tool_from.name
      expect(tool_to.custom_fields).to eq @tool_from.custom_fields
      expect(tool_to.has_placement?(:course_navigation)).to be true
      expect(tool_to.consumer_key).to eq @tool_from.consumer_key
      expect(tool_to.shared_secret).to eq @tool_from.shared_secret
    end

    it "does not duplicate external tools used in modules" do
      mod1 = @copy_from.context_modules.create!(name: "some module")
      tag = mod1.add_item({ type: "context_external_tool",
                            title: "Example URL",
                            url: "http://www.example.com",
                            new_tab: true })
      tag.save

      run_course_copy

      expect(@copy_to.context_external_tools.count).to eq 1

      tool_to = @copy_to.context_external_tools.first
      expect(tool_to.name).to eq @tool_from.name
      expect(tool_to.consumer_key).to eq @tool_from.consumer_key
      expect(tool_to.has_placement?(:course_navigation)).to be true
    end

    it "copies external tool assignments" do
      assignment_model(course: @copy_from, points_possible: 40, submission_types: "external_tool", grading_type: "points")
      tag_from = @assignment.build_external_tool_tag(url: "http://example.com/one", new_tab: true)
      tag_from.content_type = "ContextExternalTool"
      tag_from.content_id = @tool_from.id
      tag_from.save!

      run_course_copy

      tool_to = @copy_to.context_external_tools.where(migration_id: mig_id(@tool_from)).first
      expect(tool_to).not_to be_nil
      asmnt_2 = @copy_to.assignments.first
      expect(asmnt_2.submission_types).to eq "external_tool"
      expect(asmnt_2.external_tool_tag).not_to be_nil
      tag_to = asmnt_2.external_tool_tag
      expect(tag_to.content_type).to eq tag_from.content_type
      expect(tag_to.content_id).to eq tool_to.id
      expect(tag_to.url).to eq tag_from.url
      expect(tag_to.new_tab).to eq tag_from.new_tab
    end

    it "copies account-level external tool assignments" do
      account_tool = @copy_from.account.context_external_tools.build name: "blah", url: "https://blah.example.com", shared_secret: "123", consumer_key: "456"
      assignment_model(course: @copy_from, points_possible: 40, submission_types: "external_tool", grading_type: "points")
      @assignment.create_external_tool_tag(url: "http://blah.example.com/one", new_tab: true, content: account_tool)

      run_course_copy

      asmnt_2 = @copy_to.assignments.first
      tag_to = asmnt_2.external_tool_tag
      expect(tag_to.content).to eq account_tool

      run_course_copy

      expect(asmnt_2.reload.external_tool_tag).to eq tag_to # don't recreate the tag
    end

    it "copies vendor extensions" do
      @tool_from.settings[:vendor_extensions] = [{ platform: "my.lms.com", custom_fields: { "key" => "value" } }]
      @tool_from.save!

      run_course_copy

      tool = @copy_to.context_external_tools.where(migration_id: mig_id(@tool_from)).first
      expect(tool.settings[:vendor_extensions]).to eq [{ "platform" => "my.lms.com", "custom_fields" => { "key" => "value" } }]
    end

    it "copies canvas extensions" do
      @tool_from.user_navigation = { url: "http://www.example.com", text: "hello", labels: { "en" => "hello", "es" => "hola" }, extra: "extra", custom_fields: { "key" => "value" } }
      @tool_from.course_navigation = { url: "http://www.example.com", text: "hello", labels: { "en" => "hello", "es" => "hola" }, default: "disabled", visibility: "members", extra: "extra", custom_fields: { "key" => "value" } }
      @tool_from.account_navigation = { url: "http://www.example.com", text: "hello", labels: { "en" => "hello", "es" => "hola" }, extra: "extra", custom_fields: { "key" => "value" } }
      @tool_from.resource_selection = { url: "http://www.example.com", text: "hello", labels: { "en" => "hello", "es" => "hola" }, selection_width: 100, selection_height: 50, extra: "extra", custom_fields: { "key" => "value" } }
      @tool_from.editor_button = { url: "http://www.example.com", text: "hello", labels: { "en" => "hello", "es" => "hola" }, selection_width: 100, selection_height: 50, icon_url: "http://www.example.com", extra: "extra", custom_fields: { "key" => "value" } }
      @tool_from.save!

      run_course_copy

      tool = @copy_to.context_external_tools.where(migration_id: mig_id(@tool_from)).first
      expect(tool.course_navigation).not_to be_nil
      expect(tool.course_navigation).to eq @tool_from.course_navigation
      expect(tool.editor_button).not_to be_nil
      expect(tool.editor_button).to eq @tool_from.editor_button
      expect(tool.resource_selection).not_to be_nil
      expect(tool.resource_selection).to eq @tool_from.resource_selection
      expect(tool.account_navigation).not_to be_nil
      expect(tool.account_navigation).to eq @tool_from.account_navigation
      expect(tool.user_navigation).not_to be_nil
      expect(tool.user_navigation).to eq @tool_from.user_navigation
    end

    it "keeps reference to ContextExternalTool by id for courses" do
      mod1 = @copy_from.context_modules.create!(name: "some module")
      mod1.add_item type: "context_external_tool",
                    id: @tool_from.id,
                    url: "https://www.example.com/launch"
      run_course_copy

      tool_copy = @copy_to.context_external_tools.where(migration_id: mig_id(@tool_from)).first
      tag = @copy_to.context_modules.first.content_tags.first
      expect(tag.content_type).to eq "ContextExternalTool"
      expect(tag.content_id).to eq tool_copy.id
    end

    it "keeps reference to ContextExternalTool by id for accounts" do
      account = @copy_from.root_account
      @tool_from.context = account
      @tool_from.save!
      mod1 = @copy_from.context_modules.create!(name: "some module")
      mod1.add_item type: "context_external_tool", id: @tool_from.id, url: "https://www.example.com/launch"

      run_course_copy

      tag = @copy_to.context_modules.first.content_tags.first
      expect(tag.content_type).to eq "ContextExternalTool"
      expect(tag.content_id).to eq @tool_from.id
    end

    it "keeps tab configuration for account-level external tools" do
      account = @copy_from.root_account
      @tool_from.context = account
      @tool_from.save!

      @copy_from.tab_configuration = [
        { "id" => 0 }, { "id" => "context_external_tool_#{@tool_from.id}" }, { "id" => 14 }
      ]
      @copy_from.save!

      run_course_copy

      expect(@copy_to.tab_configuration).to eq [
        { "id" => 0 }, { "id" => "context_external_tool_#{@tool_from.id}" }, { "id" => 14 }
      ]
    end

    it "does not double-escape retrieval urls" do
      url = "http://www.example.com?url=http%3A%2F%2Fwww.anotherurl.com"

      @copy_from.syllabus_body = "<p><iframe src=\"/courses/#{@copy_from.id}/external_tools/retrieve?url=#{CGI.escape(url)}\" width=\"320\" height=\"240\" style=\"width: 553px; height: 335px;\"></iframe></p>"

      run_course_copy

      expect(@copy_to.syllabus_body).to eq @copy_from.syllabus_body.sub("/courses/#{@copy_from.id}/", "/courses/#{@copy_to.id}/")
    end

    it "copies message_type (and other fields)" do
      @tool_from.course_settings_sub_navigation = { url: "http://www.example.com",
                                                    text: "hello",
                                                    message_type: "ContentItemSelectionResponse" }
      @tool_from.settings[:selection_width] = 5000
      @tool_from.save!

      run_course_copy

      tool = @copy_to.context_external_tools.where(migration_id: mig_id(@tool_from)).first
      expect(tool.settings[:selection_width]).to eq 5000
      expect(tool.course_settings_sub_navigation[:message_type]).to eq "ContentItemSelectionResponse"
    end

    it "copies content_migration settings" do
      @tool_from.settings[:content_migration] = {
        "export_start_url" => "https://example.com/export",
        "import_start_url" => "https://example.com/import"
      }
      @tool_from.save!

      run_course_copy
      tool = @copy_to.context_external_tools.where(migration_id: mig_id(@tool_from)).first
      expect(tool.settings[:content_migration]).to eq @tool_from.settings[:content_migration]
    end
  end
end

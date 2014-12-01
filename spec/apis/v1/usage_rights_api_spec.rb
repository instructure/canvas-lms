#
# Copyright (C) 2014 Instructure, Inc.
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
# with this program. If not, see <http://www.gnu.org/content_licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe UsageRightsController, type: :request do
  context "Course" do
    before(:once) do
      teacher_in_course active_all: true
      @root = Folder.root_folders(@course).first
      @folderA = @course.folders.create! parent_folder: @root, name: 'folder_A'
      @folderB = @course.folders.create! parent_folder: @folderA, name: 'folder_B'
      @fileR = attachment_model context: @course, folder: @root, display_name: 'file_R'
      @fileA1 = attachment_model context: @course, folder: @folderA, display_name: 'file_A1'
      @fileA2 = attachment_model context: @course, folder: @folderA, display_name: 'file_A2'
      @fileB = attachment_model context: @course, folder: @folderB, display_name: 'file_B'
    end

    describe "licenses" do
      it "should require :read on the context" do
        api_call_as_user(user_model, :get, "/api/v1/courses/#{@course.id}/content_licenses",
                 { controller: 'usage_rights', action: 'licenses', course_id: @course.to_param, format: 'json'},
                 {}, {}, {expected_status: 401})
      end

      it "should list licenses" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/content_licenses",
                 { controller: 'usage_rights', action: 'licenses', course_id: @course.to_param, format: 'json'})
        expect(json).to match_array(UsageRights.licenses.map { |license, data| { 'id' => license, 'name' => data[:readable_license], 'url' => data[:license_url] } })
      end
    end

    describe "set_usage_rights" do
      it "should require :manage_files on the context" do
        student_in_course active_all: true
        api_call_as_user(@student, :put, "/api/v1/courses/#{@course.id}/usage_rights",
                         { controller: 'usage_rights', action: 'set_usage_rights', course_id: @course.to_param, format: 'json'},
                         {}, {}, {expected_status: 401})
      end

      it "should require usage_rights hash" do
        json = api_call(:put, "/api/v1/courses/#{@course.id}/usage_rights",
                         { controller: 'usage_rights', action: 'set_usage_rights', course_id: @course.to_param, format: 'json' },
                         { file_ids: [@fileR.id] }, {}, {expected_status: 400})
        expect(json).to eql({'message' => "No 'usage_rights' object supplied"})
      end

      it "should require file_ids or folder_ids parameters" do
        json = api_call(:put, "/api/v1/courses/#{@course.id}/usage_rights",
                        { controller: 'usage_rights', action: 'set_usage_rights', course_id: @course.to_param, format: 'json' },
                        { usage_rights: {use_justification: 'public_domain'} }, {}, {expected_status: 400})
        expect(json).to eql({'message' => "Must supply 'file_ids' and/or 'folder_ids' parameter"})
      end

      it "should require valid usage_rights parameters" do
        json = api_call(:put, "/api/v1/courses/#{@course.id}/usage_rights",
                        { controller: 'usage_rights', action: 'set_usage_rights', course_id: @course.to_param, format: 'json' },
                        { file_ids: [@fileR.id], usage_rights: {use_justification: 'just_because'} }, {}, {expected_status: 400})
        expect(json['errors']['use_justification']).not_to be_nil
      end

      it "should infer a default license from the use_justification" do
        json = api_call(:put, "/api/v1/courses/#{@course.id}/usage_rights",
                        { controller: 'usage_rights', action: 'set_usage_rights', course_id: @course.to_param, format: 'json' },
                        { file_ids: [@fileR.id], usage_rights: {use_justification: 'public_domain'} })

        expect(json['message']).to eq('1 file updated')
        expect(json['file_ids']).to match_array([@fileR.id])
        expect(json['legal_copyright']).to be_nil
        expect(json['license']).to eq('public_domain')
        expect(json['use_justification']).to eq('public_domain')

        @fileR.reload
        expect(@fileR.usage_rights).not_to be_nil
        expect(@fileR.usage_rights.legal_copyright).to be_nil
        expect(@fileR.usage_rights.license).to eq('public_domain')
        expect(@fileR.usage_rights.use_justification).to eq('public_domain')
      end

      it "should reuse usage_rights objects" do
        usage_rights = @course.usage_rights.create! use_justification: 'creative_commons', legal_copyright: '(C) 2014 XYZ Corp', license: 'cc_by_nd'
        @fileR.usage_rights = usage_rights
        @fileR.save

        json = api_call(:put, "/api/v1/courses/#{@course.id}/usage_rights",
                 { controller: 'usage_rights', action: 'set_usage_rights', course_id: @course.to_param, format: 'json' },
                 { file_ids: [@fileR.id, @fileA1.id], usage_rights: {use_justification: 'creative_commons', legal_copyright: '(C) 2014 XYZ Corp', license: 'cc_by_nd'} })
        expect(json['message']).to eq('2 files updated')
        expect(json['file_ids']).to match_array([@fileR.id, @fileA1.id])

        expect(@fileR.reload.usage_rights_id).to eq(usage_rights.id)
        expect(@fileA1.reload.usage_rights_id).to eq(usage_rights.id)
      end

      it "should process folder contents recursively" do
        json = api_call(:put, "/api/v1/courses/#{@course.id}/usage_rights",
                        { controller: 'usage_rights', action: 'set_usage_rights', course_id: @course.to_param, format: 'json' },
                        { folder_ids: [@folderA.id], usage_rights: {use_justification: 'creative_commons', legal_copyright: '(C) 2014 XYZ Corp', license: 'cc_by_nd'} })
        expect(json['message']).to eq('3 files updated')
        expect(json['file_ids']).to match_array([@fileA1.id, @fileA2.id, @fileB.id])

        expect(@fileR.reload.usage_rights).to be_nil

        usage_rights = @fileA1.reload.usage_rights
        expect(usage_rights).not_to be_nil
        expect(usage_rights.use_justification).to eq('creative_commons')
        expect(usage_rights.license).to eq('cc_by_nd')

        expect(@fileA2.reload.usage_rights_id).to eq(usage_rights.id)
        expect(@fileB.reload.usage_rights_id).to eq(usage_rights.id)
      end

      it "should skip deleted files and folders" do
        @fileR.destroy
        @fileA1.destroy
        @folderB.destroy
        json = api_call(:put, "/api/v1/courses/#{@course.id}/usage_rights",
                        { controller: 'usage_rights', action: 'set_usage_rights', course_id: @course.to_param, format: 'json' },
                        { file_ids: [@fileR.id], folder_ids: [@folderA.id], usage_rights: {use_justification: 'used_by_permission', legal_copyright: '(C) 2014 XYZ Corp'} })
        expect(json['message']).to eq('1 file updated')
        expect(json['file_ids']).to match_array([@fileA2.id])
        expect(@fileR.reload.usage_rights).to be_nil
        expect(@fileA1.reload.usage_rights).to be_nil
        expect(@fileA2.reload.usage_rights.legal_copyright).to eq('(C) 2014 XYZ Corp')
        expect(@fileB.reload.usage_rights).to be_nil
      end
    end

    describe "remove_usage_rights" do
      it "should require :manage_files on the context" do
        student_in_course active_all: true
        api_call_as_user(@student, :delete, "/api/v1/courses/#{@course.id}/usage_rights",
                         { controller: 'usage_rights', action: 'remove_usage_rights', course_id: @course.to_param, format: 'json'},
                         {}, {}, {expected_status: 401})
      end

      it "should remove usage rights" do
        usage_rights = @course.usage_rights.create! use_justification: 'creative_commons', legal_copyright: '(C) 2014 XYZ Corp', license: 'cc_by_nd'
        @course.attachments.update_all(usage_rights_id: usage_rights)
        json = api_call(:delete, "/api/v1/courses/#{@course.id}/usage_rights",
                 { controller: 'usage_rights', action: 'remove_usage_rights', course_id: @course.to_param, format: 'json'},
                 { folder_ids: [@folderA.id] })
        expect(json['message']).to eq("3 files updated")
        expect(json['file_ids']).to match_array([@fileA1.id, @fileA2.id, @fileB.id])
        expect(@fileR.reload.usage_rights_id).to eq(usage_rights.id)
        expect(@course.attachments.where(usage_rights_id: nil).pluck(:id)).to match_array([@fileA1.id, @fileA2.id, @fileB.id])
      end
    end
  end

  context "User" do
    before(:once) do
      user_model
      attachment_model(context: @user)
    end

    it "should list licenses" do
      json = api_call(:get, "/api/v1/users/#{@user.id}/content_licenses",
                      { controller: 'usage_rights', action: 'licenses', user_id: @user.to_param, format: 'json'})
      expect(json).to match_array(UsageRights.licenses.map { |license, data| { 'id' => license, 'name' => data[:readable_license], 'url' => data[:license_url] } })
    end

    it "should set usage rights" do
      json = api_call(:put, "/api/v1/users/#{@user.id}/usage_rights",
                      { controller: 'usage_rights', action: 'set_usage_rights', user_id: @user.to_param, format: 'json' },
                      { file_ids: [@attachment.id], usage_rights: {use_justification: 'own_copyright', legal_copyright: '(C) 2014 XYZ Corp'} })
      expect(@attachment.reload.usage_rights.use_justification).to eq('own_copyright')
    end
  end

  context "Group" do
    before(:once) do
      group_model
      attachment_model(context: @group)
      account_admin_user(account: @group.account)
    end

    it "should list licenses" do
      json = api_call(:get, "/api/v1/groups/#{@group.id}/content_licenses",
                      { controller: 'usage_rights', action: 'licenses', group_id: @group.to_param, format: 'json'})
      expect(json).to match_array(UsageRights.licenses.map { |license, data| { 'id' => license, 'name' => data[:readable_license], 'url' => data[:license_url] } })
    end

    it "should set usage rights" do
      json = api_call(:put, "/api/v1/groups/#{@group.id}/usage_rights",
                      { controller: 'usage_rights', action: 'set_usage_rights', group_id: @group.to_param, format: 'json' },
                      { file_ids: [@attachment.id], usage_rights: {use_justification: 'fair_use', legal_copyright: '(C) 2014 XYZ Corp'} })
      expect(@attachment.reload.usage_rights.use_justification).to eq('fair_use')
    end
  end
end

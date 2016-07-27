#
# Copyright (C) 2011 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# Public: Create a new valid LTI tool for the given course.
#
# course - The course to create the tool for.
#
# Returns a valid ExternalTool.
def new_valid_tool(course)
  tool = course.context_external_tools.new(
      name: "bob",
      consumer_key: "bob",
      shared_secret: "bob",
      tool_id: 'some_tool',
      privacy_level: 'public'
  )
  tool.url = "http://www.example.com/basic_lti"
  tool.resource_selection = {
    :url => "http://#{HostUrl.default_host}/selection_test",
    :selection_width => 400,
    :selection_height => 400}
  tool.save!
  tool
end

describe ExternalToolsController do
  before :once do
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)
  end

  describe "GET 'jwt_token'" do

    before :each do
      @iat = Time.zone.now
      Time.zone.class.any_instance.stubs(:now).returns(@iat)
      @tool = new_valid_tool(@course)
      @tool.course_navigation = { message_type: 'ContentItemSelectionResponse' }
      @tool.save!
      @course.name = 'Course Name'
      @course.save!
    end

    it "returns the correct JWT token when given using the tool_id param" do
      user_session(@teacher)
      response = get :jwt_token, {course_id: @course.id, tool_id: @tool.id}
      jwt = JSON.parse(response.body[9..-1])['jwt_token']
      decoded_token = Canvas::Security.decode_jwt(jwt, [:skip_verification])

      expect(decoded_token['custom_canvas_user_id']).to eq @teacher.id.to_s
      expect(decoded_token['custom_canvas_course_id']).to eq @course.id.to_s
      expect(decoded_token['consumer_key']). to eq @tool.consumer_key
      expect(decoded_token['iat']). to eq @iat.to_i
    end

    it "does not return a JWT token for another context" do
      teacher_course = @course
      other_course = course()

      @tool.context_id = other_course.id
      @tool.save!

      user_session(@teacher)
      response = get :jwt_token, {course_id: teacher_course.id, tool_id: @tool.id}

      expect(response.status).to eq 404
    end


    it "returns the correct JWT token when given using the tool_launch_url param" do
      user_session(@teacher)
      response = get :jwt_token, {course_id: @course.id, tool_launch_url: @tool.url}
      decoded_token = Canvas::Security.decode_jwt(JSON.parse(response.body[9..-1])['jwt_token'], [:skip_verification])

      expect(decoded_token['custom_canvas_user_id']).to eq @teacher.id.to_s
      expect(decoded_token['custom_canvas_course_id']).to eq @course.id.to_s
      expect(decoded_token['consumer_key']). to eq @tool.consumer_key
      expect(decoded_token['iat']). to eq @iat.to_i
    end

    it "sets status code to 404 if the requested tool id does not exist" do
      user_session(@teacher)
      response = get :jwt_token, {course_id: @course.id, tool_id: 999999}
      expect(response.status).to eq 404
    end

    it "sets status code to 404 if no query params are provided" do
      user_session(@teacher)
      response = get :jwt_token, {course_id: @course.id}
      expect(response.status).to eq 404
    end

    it "sets status code to 404 if the requested tool_launch_url does not exist" do
      user_session(@teacher)
      response = get :jwt_token, {course_id: @course.id, tool_launch_url:'http://www.nothere.com/doesnt_exist'}
      expect(response.status).to eq 404
    end
  end

  describe "GET 'show'" do
    context 'basic-lti-launch-request' do
      it "launches account tools for non-admins" do
        user_session(@teacher)
        tool = @course.account.context_external_tools.new(:name => "bob",
                                                          :consumer_key => "bob",
                                                          :shared_secret => "bob")
        tool.url = "http://www.example.com/basic_lti"
        tool.account_navigation = { enabled: true }
        tool.save!

        get :show, :account_id => @course.account.id, id: tool.id

        expect(response).to be_success
      end

      it "generates the resource_link_id correctly for a course navigation launch" do
        user_session(@teacher)
        tool = @course.context_external_tools.new(:name => "bob",
                                                          :consumer_key => "bob",
                                                          :shared_secret => "bob")
        tool.url = "http://www.example.com/basic_lti"
        tool.course_navigation = { enabled: true }
        tool.save!

        get :show, :course_id => @course.id, id: tool.id
        expect(assigns[:lti_launch].params['resource_link_id']).to eq opaque_id(@course)
      end

      it 'generates the correct resource_link_id for a homework submission' do
        user_session(@teacher)
        assignment = @course.assignments.create!(name: 'an assignment')
        assignment.save!
        tool = @course.context_external_tools.new(:name => "bob",
                                                  :consumer_key => "bob",
                                                  :shared_secret => "bob")
        tool.url = "http://www.example.com/basic_lti"
        tool.course_navigation = { enabled: true }
        tool.homework_submission = { enabled: true }
        tool.save!

        get :show, course_id: @course.id, id: tool.id, launch_type: 'homework_submission', assignment_id: assignment.id
        expect(response).to be_success

        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params['resource_link_id']).to eq opaque_id(@course)
      end

      it "returns flash error if the tool is not found" do
        user_session(@teacher)
        get :show, :account_id => @course.account.id, id: 0
        expect(response).to be_redirect
        expect(flash[:error]).to match(/find valid settings/)
      end
    end

    context 'ContentItemSelectionResponse' do
      before :once do
        @tool = new_valid_tool(@course)
        @tool.course_navigation = { message_type: 'ContentItemSelectionResponse' }
        @tool.save!

        @course.name = 'a course'
        @course.save!
      end

      it "generates the resource_link_id correctly" do
        user_session(@teacher)
        tool = @tool
        tool.settings['post_only'] = 'true'
        tool.url = "http://www.example.com/basic_lti?first=john&last=smith"
        tool.save!
        get :show, course_id: @course.id, id: tool.id
        expect(assigns[:lti_launch].params['resource_link_id']).to eq opaque_id(@course)
      end

      it "should remove query params when post_only is set" do
        user_session(@teacher)
        tool = @tool
        tool.settings['post_only'] = 'true'
        tool.url = "http://www.example.com/basic_lti?first=john&last=smith"
        tool.save!
        get :show, course_id: @course.id, id: tool.id
        expect(assigns[:lti_launch].resource_url).to eq 'http://www.example.com/basic_lti'
      end

      it "should not remove query params when post_only is not set" do
        user_session(@teacher)
        tool = @tool
        tool.url = "http://www.example.com/basic_lti?first=john&last=smith"
        tool.save!
        get :show, course_id: @course.id, id: tool.id
        expect(assigns[:lti_launch].resource_url).to eq 'http://www.example.com/basic_lti?first=john&last=smith'
      end

      it "generates launch params for a ContentItemSelectionResponse message" do
        user_session(@teacher)
        HostUrl.stubs(:outgoing_email_address).returns('some_address')

        @course.root_account.lti_guid = 'root-account-guid'
        @course.root_account.name = 'root account'
        @course.root_account.save!

        get :show, :course_id => @course.id, id: @tool.id

        expect(response).to be_success
        lti_launch = assigns[:lti_launch]
        expect(lti_launch.link_text).to eq 'bob'
        expect(lti_launch.resource_url).to eq 'http://www.example.com/basic_lti'
        expect(lti_launch.launch_type).to be_nil
        expect(lti_launch.params['lti_message_type']).to eq 'ContentItemSelectionResponse'
        expect(lti_launch.params['lti_version']).to eq 'LTI-1p0'
        expect(lti_launch.params['context_id']).to eq opaque_id(@course)
        expect(lti_launch.params['resource_link_id']).to eq opaque_id(@course)
        expect(lti_launch.params['context_title']).to eq 'a course'
        expect(lti_launch.params['roles']).to eq 'Instructor'
        expect(lti_launch.params['tool_consumer_instance_guid']).to eq 'root-account-guid'
        expect(lti_launch.params['tool_consumer_instance_name']).to eq 'root account'
        expect(lti_launch.params['tool_consumer_instance_contact_email']).to eq 'some_address'
        expect(lti_launch.params['launch_presentation_return_url']).to start_with 'http'
        expect(lti_launch.params['launch_presentation_locale']).to eq 'en'
        expect(lti_launch.params['launch_presentation_document_target']).to eq 'iframe'
      end

      it "sends content item json for a course" do
        user_session(@teacher)
        get :show, :course_id => @course.id, id: @tool.id
        content_item = JSON.parse(assigns[:lti_launch].params['content_items'])
        placement = content_item['@graph'].first

        expect(content_item['@context']).to eq 'http://purl.imsglobal.org/ctx/lti/v1/ContentItemPlacement'
        expect(content_item['@graph'].size).to eq 1
        expect(placement['@type']).to eq 'ContentItemPlacement'
        expect(placement['placementOf']['@type']).to eq 'FileItem'
        expect(placement['placementOf']['@id']).to eq "#{api_v1_course_content_exports_url(@course)}?export_type=common_cartridge"
        expect(placement['placementOf']['mediaType']).to eq 'application/vnd.instructure.api.content-exports.course'
        expect(placement['placementOf']['title']).to eq 'a course'
      end

      it "sends content item json for an assignment" do
        user_session(@teacher)
        assignment = @course.assignments.create!(name: 'an assignment')
        get :show, :course_id => @course.id, id: @tool.id, :assignments => [assignment.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "select%5Bassignments%5D%5B%5D=#{assignment.id}"
        expect(placement['placementOf']['mediaType']).to eq 'application/vnd.instructure.api.content-exports.assignment'
        expect(placement['placementOf']['title']).to eq 'an assignment'
      end

      it "sends content item json for a discussion topic" do
        user_session(@teacher)
        topic = @course.discussion_topics.create!(:title => "blah")
        get :show, :course_id => @course.id, id: @tool.id, :discussion_topics => [topic.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "select%5Bdiscussion_topics%5D%5B%5D=#{topic.id}"
        expect(placement['placementOf']['mediaType']).to eq 'application/vnd.instructure.api.content-exports.discussion_topic'
        expect(placement['placementOf']['title']).to eq 'blah'
      end

      it "sends content item json for a file" do
        user_session(@teacher)
        attachment_model
        get :show, :course_id => @course.id, id: @tool.id, :files => [@attachment.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        download_url = placement['placementOf']['@id']

        expect(download_url).to include(@attachment.uuid)
        expect(placement['placementOf']['mediaType']).to eq @attachment.content_type
        expect(placement['placementOf']['title']).to eq @attachment.display_name
      end

      it "sends content item json for a quiz" do
        user_session(@teacher)
        quiz = @course.quizzes.create!(title: 'a quiz')
        get :show, :course_id => @course.id, id: @tool.id, :quizzes => [quiz.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "select%5Bquizzes%5D%5B%5D=#{quiz.id}"
        expect(placement['placementOf']['mediaType']).to eq 'application/vnd.instructure.api.content-exports.quiz'
        expect(placement['placementOf']['title']).to eq 'a quiz'
      end

      it "sends content item json for a module" do
        user_session(@teacher)
        context_module = @course.context_modules.create!(name: 'a module')
        get :show, :course_id => @course.id, id: @tool.id, :modules => [context_module.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "select%5Bmodules%5D%5B%5D=#{context_module.id}"
        expect(placement['placementOf']['mediaType']).to eq 'application/vnd.instructure.api.content-exports.module'
        expect(placement['placementOf']['title']).to eq 'a module'
      end

      it "sends content item json for a module item" do
        user_session(@teacher)
        context_module = @course.context_modules.create!(name: 'a module')
        quiz = @course.quizzes.create!(title: 'a quiz')
        tag = context_module.add_item(:id => quiz.id, :type => 'quiz')

        get :show, :course_id => @course.id, id: @tool.id, :module_items => [tag.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "select%5Bmodule_items%5D%5B%5D=#{tag.id}"
        expect(placement['placementOf']['mediaType']).to eq 'application/vnd.instructure.api.content-exports.quiz'
        expect(placement['placementOf']['title']).to eq 'a quiz'
      end

      it "sends content item json for a page" do
        user_session(@teacher)
        page = @course.wiki.wiki_pages.create!(title: 'a page')
        get :show, :course_id => @course.id, id: @tool.id, :pages => [page.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "select%5Bpages%5D%5B%5D=#{page.id}"
        expect(placement['placementOf']['mediaType']).to eq 'application/vnd.instructure.api.content-exports.page'
        expect(placement['placementOf']['title']).to eq 'a page'
      end

      it "sends content item json for selected content" do
        user_session(@teacher)
        page = @course.wiki.wiki_pages.create!(title: 'a page')
        assignment = @course.assignments.create!(name: 'an assignment')
        get :show, :course_id => @course.id, id: @tool.id, :pages => [page.id], :assignments => [assignment.id]
        placement = JSON.parse(assigns[:lti_launch].params['content_items'])['@graph'].first
        migration_url = placement['placementOf']['@id']
        params = migration_url.split('?').last.split('&')

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include 'export_type=common_cartridge'
        expect(params).to include "select%5Bpages%5D%5B%5D=#{page.id}"
        expect(params).to include "select%5Bassignments%5D%5B%5D=#{assignment.id}"
        expect(placement['placementOf']['mediaType']).to eq 'application/vnd.instructure.api.content-exports.course'
        expect(placement['placementOf']['title']).to eq 'a course'
      end

      it "returns flash error if invalid id params are passed in" do
        user_session(@teacher)
        get :show, :course_id => @course.id, id: @tool.id, :pages => [0]
        expect(response).to be_redirect
        expect(flash[:error]).to match(/error generating the tool launch/)
      end
    end

    context 'ContentItemSelectionRequest' do
      before :once do
        @tool = new_valid_tool(@course)
        @tool.migration_selection = { message_type: 'ContentItemSelectionRequest' }
        @tool.resource_selection = { message_type: 'ContentItemSelectionRequest' }
        @tool.homework_submission = { message_type: 'ContentItemSelectionRequest' }
        @tool.editor_button = { message_type: 'ContentItemSelectionRequest', icon_url: 'http://example.com/icon.png' }
        @tool.save!

        @course.name = 'a course'
        @course.save!
      end

      it "generates launch params for a ContentItemSelectionRequest message" do
        user_session(@teacher)
        get :show, course_id: @course.id, id: @tool.id, launch_type: 'migration_selection'
        expect(response).to be_success

        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params['lti_message_type']).to eq 'ContentItemSelectionRequest'
        expect(lti_launch.params['content_item_return_url']).to eq "http://test.host/courses/#{@course.id}/external_content/success/external_tool_dialog"
        expect(lti_launch.params['accept_multiple']).to eq 'false'
      end

      it "sets proper return data for migration_selection" do
        user_session(@teacher)
        get :show, course_id: @course.id, id: @tool.id, launch_type: 'migration_selection'
        expect(response).to be_success

        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params['accept_copy_advice']).to eq 'true'
        expect(lti_launch.params['accept_presentation_document_targets']).to eq 'download'
        expect(lti_launch.params['accept_media_types']).to eq 'application/vnd.ims.imsccv1p1,application/vnd.ims.imsccv1p2,application/vnd.ims.imsccv1p3,application/zip,application/xml'
      end

      it "sets proper return data for resource_selection" do
        user_session(@teacher)
        get :show, course_id: @course.id, id: @tool.id, launch_type: 'resource_selection'
        expect(response).to be_success

        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params['accept_copy_advice']).to eq nil
        expect(lti_launch.params['accept_presentation_document_targets']).to eq 'frame,window'
        expect(lti_launch.params['accept_media_types']).to eq 'application/vnd.ims.lti.v1.ltilink'
      end

      it "sets proper return data for collaboration" do
        user_session(@teacher)
        @tool.collaboration = { message_type: 'ContentItemSelectionRequest' }
        @tool.save!
        get :show, course_id: @course.id, id: @tool.id, launch_type: 'collaboration'
        expect(response).to be_success

        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params['accept_copy_advice']).to eq nil
        expect(lti_launch.params['accept_presentation_document_targets']).to eq 'window'
        expect(lti_launch.params['accept_media_types']).to eq 'application/vnd.ims.lti.v1.ltilink'
      end

      context "homework submission" do

        it "sets accept_copy_advice to true if submission_type includes online_upload" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: 'an assignment')
          assignment.allowed_extensions += ['pdf', 'jpeg']
          assignment.submission_types = 'online_upload'
          assignment.save!
          get :show, course_id: @course.id, id: @tool.id,
            launch_type: 'homework_submission', assignment_id: assignment.id
          expect(response).to be_success

          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params['accept_copy_advice']).to eq 'true'
        end

        it "sets accept_copy_advice to false if submission_type does not include online_upload" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: 'an assignment')
          assignment.allowed_extensions += ['pdf', 'jpeg']
          assignment.submission_types = 'online_text_entry'
          assignment.save!
          get :show, course_id: @course.id, id: @tool.id, launch_type: 'homework_submission',
            assignment_id: assignment.id
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params['accept_copy_advice']).to eq 'false'
        end

        it "sets proper accept_media_types for homework_submission with extension restrictions" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: 'an assignment')
          assignment.allowed_extensions += ['pdf', 'jpeg']
          assignment.submission_types = 'online_upload'
          assignment.save!
          get :show, course_id: @course.id, id: @tool.id, launch_type: 'homework_submission',
            assignment_id: assignment.id
          expect(response).to be_success

          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params['accept_media_types']).to eq 'application/pdf,image/jpeg'
        end

        it "sends the ext_content_file_extensions paramter for restriced file types" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: 'an assignment')
          assignment.allowed_extensions += ['pdf', 'jpeg']
          assignment.submission_types = 'online_upload'
          assignment.save!
          get :show, course_id: @course.id, id: @tool.id, launch_type: 'homework_submission',
            assignment_id: assignment.id
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params['ext_content_file_extensions']).to eq 'pdf,jpeg'
        end

        it "doesn't set the ext_content_file_extensions parameter if online_upload isn't accepted" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: 'an assignment')
          assignment.submission_types = 'online_text_entry'
          assignment.allowed_extensions += ['pdf', 'jpeg']
          assignment.save!
          get :show, course_id: @course.id, id: @tool.id, launch_type: 'homework_submission',
            assignment_id: assignment.id
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params.key?('ext_content_file_extensions')).not_to be
        end

        it "sets the accept_media_types parameter to '*.*'' if online_upload isn't accepted" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: 'an assignment')
          assignment.allowed_extensions += ['pdf', 'jpeg']
          assignment.save!
          get :show, course_id: @course.id, id: @tool.id, launch_type: 'homework_submission',
            assignment_id: assignment.id
          expect(response).to be_success

          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params['accept_media_types']).to eq '*/*'
        end

        it "sets the accept_presentation_document_target to window if online_url is a submission type" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: 'an assignment')
          assignment.submission_types = 'online_url'
          assignment.save!
          get :show, course_id: @course.id, id: @tool.id, launch_type: 'homework_submission',
            assignment_id: assignment.id
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params['accept_presentation_document_targets']).to include 'window'
        end

        it "doesn't add none to accept_presentation_document_target if online_upload isn't a submission_type" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: 'an assignment')
          assignment.submission_types = 'online_url'
          assignment.save!
          get :show, course_id: @course.id, id: @tool.id, launch_type: 'homework_submission',
            assignment_id: assignment.id
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params['accept_presentation_document_targets']).not_to include 'none'
        end

        it "sets the mime type to */* if there is a online_url submission type" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: 'an assignment')
          assignment.allowed_extensions += ['pdf', 'jpeg']
          assignment.submission_types = 'online_upload,online_url'
          assignment.save!
          get :show, course_id: @course.id, id: @tool.id, launch_type: 'homework_submission',
            assignment_id: assignment.id
          expect(response).to be_success

          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params['accept_media_types']).to eq '*/*'
        end


      end

      it "sets proper return data for editor_button" do
        user_session(@teacher)
        get :show, course_id: @course.id, id: @tool.id, launch_type: 'editor_button'
        expect(response).to be_success

        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params['accept_copy_advice']).to eq nil
        expect(lti_launch.params['accept_presentation_document_targets']).to eq 'embed,frame,iframe,window'
        expect(lti_launch.params['accept_media_types']).to eq 'image/*,text/html,application/vnd.ims.lti.v1.ltilink,*/*'
      end

      it "does not copy query params to POST if disable_lti_post_only feature flag is set" do
        user_session(@teacher)
        @course.root_account.enable_feature!(:disable_lti_post_only)
        @tool.url = 'http://www.instructure.com/test?first=rory&last=williams'
        @tool.save!

        get :show, course_id: @course.id, id: @tool.id, launch_type: 'migration_selection'
        expect(assigns[:lti_launch].resource_url).to eq 'http://www.instructure.com/test?first=rory&last=williams'
      end
    end
  end

  describe "GET 'retrieve'" do
    let :account do
      Account.default
    end

    let :tool do
      tool = account.context_external_tools.new(
        name: "bob",
        consumer_key: "bob",
        shared_secret: "bob",
        tool_id: 'some_tool',
        privacy_level: 'public'
      )
      tool.url = "http://www.example.com/basic_lti?first=john&last=smith"
      tool.resource_selection = {
        :url => "http://#{HostUrl.default_host}/selection_test",
        :selection_width => 400,
        :selection_height => 400}
      tool.save!
      tool
    end

    it "should require authentication" do
      user_model
      user_session(@user)
      get 'retrieve', :course_id => @course.id
      assert_unauthorized
    end

    it "should find tools matching by exact url" do
      user_session(@teacher)
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.url = "http://www.example.com/basic_lti"
      tool.save!
      get 'retrieve', :course_id => @course.id, :url => "http://www.example.com/basic_lti"
      expect(response).to be_success
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params).not_to be_nil
    end

    it "should find tools matching by domain" do
      user_session(@teacher)
      tool = new_valid_tool(@course)
      get 'retrieve', :course_id => @course.id, :url => "http://www.example.com/basic_lti"
      expect(response).to be_success
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params).not_to be_nil
    end

    it "should redirect if no matching tools are found" do
      user_session(@teacher)
      get 'retrieve', :course_id => @course.id, :url => "http://www.example.com"
      expect(response).to be_redirect
      expect(flash[:error]).to eq "Couldn't find valid settings for this link"
    end

    it "should return a variable expansion for a collaboration" do
      user_session(@teacher)
      collab = ExternalToolCollaboration.create!(
        title: "my collab",
        user: @teacher,
        url: 'http://www.example.com'
      )
      tool = new_valid_tool(@course)
      tool.collaboration = { message_type: 'ContentItemSelectionRequest' }
      tool.settings[:custom_fields] = { 'collaboration_url' => '$Canvas.api.collaborationMembers.url' }
      tool.save!
      get 'retrieve', course_id: @course.id, url: tool.url, content_item_id: collab.id, placement: 'collaboration'
      expect(assigns[:lti_launch].params['custom_collaboration_url']).to eq api_v1_collaboration_members_url(collab)
    end

    it "should remove query params when post_only is set" do
      u = user(:active_all => true)
      account.account_users.create!(user: u)
      user_session(@user)

      tool.settings['post_only'] = 'true'
      tool.save!
      get :retrieve, {url: tool.url, account_id:account.id}
      expect(assigns[:lti_launch].resource_url).to eq 'http://www.example.com/basic_lti'
    end

    it "should not remove query params when post_only is not set" do
      u = user(:active_all => true)
      account.account_users.create!(user: u)
      user_session(@user)

      tool.save!
      get :retrieve, {url: tool.url, account_id:account.id}
      expect(assigns[:lti_launch].resource_url).to eq 'http://www.example.com/basic_lti?first=john&last=smith'
    end

    context 'collaborations' do
      let(:collab) do
        collab = ExternalToolCollaboration.create!(
          title: "my collab",
          user: @teacher,
          url: 'http://www.example.com'
        )
      end

      it "lets you specify the selection_type" do
        u = user(active_all: true)
        account.account_users.create!( user: u)
        user_session u
        tool.collaboration = { message_type: 'ContentItemSelectionRequest' }
        tool.save!
        get :retrieve, {url: tool.url, account_id: account.id, placement: 'collaboration'}
        expect(assigns[:lti_launch].params['lti_message_type']).to eq "ContentItemSelectionRequest"
      end

      it "creates a content-item return url with an id" do
        u = user(active_all: true)
        account.account_users.create!(user:u)
        user_session u
        tool.collaboration = { message_type: 'ContentItemSelectionRequest' }
        tool.save!
        get :retrieve, {url: tool.url, course_id: @course.id, placement: 'collaboration', content_item_id: collab.id }
        return_url = assigns[:lti_launch].params['content_item_return_url']
        expect(return_url).to eq "http://test.host/courses/#{@course.id}/external_content/success/external_tool_dialog/#{collab.id}"
      end

      it "sets the auto_create param to true" do
        u = user(active_all: true)
        account.account_users.create!(user:u)
        user_session u
        tool.collaboration = { message_type: 'ContentItemSelectionRequest' }
        tool.save!
        get :retrieve, {url: tool.url, course_id: @course.id, placement: 'collaboration', content_item_id: collab.id }
        expect(assigns[:lti_launch].params['auto_create']).to eq "true"
      end

      it "sets the accept_unsigned param to false" do
        u = user(active_all: true)
        account.account_users.create!(user:u)
        user_session u
        tool.collaboration = { message_type: 'ContentItemSelectionRequest' }
        tool.save!
        get :retrieve, {url: tool.url, course_id: @course.id, placement: 'collaboration', content_item_id: collab.id }
        expect(assigns[:lti_launch].params['accept_unsigned']).to eq "false"
      end

      it "adds a data element with a jwt that contains the id if a content_item_id param is present " do
        u = user(active_all: true)
        account.account_users.create!(user:u)
        user_session u
        tool.collaboration = { message_type: 'ContentItemSelectionRequest' }
        tool.save!
        get :retrieve, {url: tool.url, course_id: @course.id, placement: 'collaboration', content_item_id: collab.id }
        data = assigns[:lti_launch].params['data']
        json_data = Canvas::Security.decode_jwt(data)
        expect(json_data[:content_item_id]).to eq collab.id.to_s
      end

      it "adds a data element with a jwt that contains the consumer_key if a content_item_id param is present " do
        u = user(active_all: true)
        account.account_users.create!(user:u)
        user_session u
        tool.collaboration = { message_type: 'ContentItemSelectionRequest' }
        tool.save!
        get :retrieve, {url: tool.url, course_id: @course.id, placement: 'collaboration', content_item_id: collab.id }
        data = assigns[:lti_launch].params['data']
        json_data = Canvas::Security.decode_jwt(data)
        expect(json_data[:oauth_consumer_key]).to eq tool.consumer_key
      end

      it 'adds to the data element the default launch url' do
        u = user(active_all: true)
        account.account_users.create!(user:u)
        user_session u
        tool.collaboration = { message_type: 'ContentItemSelectionRequest' }
        tool.save!
        get :retrieve, {url: tool.url, course_id: @course.id, placement: 'collaboration', content_item_id: collab.id }
        data = assigns[:lti_launch].params['data']
        json_data = Canvas::Security.decode_jwt(data)
        expect(json_data[:default_launch_url]).to eq tool.url
      end
    end
  end

  describe "GET 'resource_selection'" do
    it "should require authentication" do
      user_model
      user_session(@user)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => 0
      assert_unauthorized
    end

    it "should be accessible by students" do
      user_session(@student)
      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      expect(response).to be_success
    end

    it "should redirect if no matching tools are found" do
      user_session(@teacher)
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob")
      tool.url = "http://www.example.com/basic_lti"
      # this tool exists, but isn't properly configured
      tool.save!
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      expect(response).to be_redirect
      expect(flash[:error]).to eq "Couldn't find valid settings for this tool"
    end

    it "should find a valid tool if one exists" do
      user_session(@teacher)
      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      expect(response).to be_success
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params['custom_canvas_enrollment_state']).to eq 'active'
    end

    it "should set html selection if specified" do
      user_session(@teacher)
      tool = new_valid_tool(@course)
      html = "<img src='/blank.png'/>"
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id, :editor_button => '1', :selection => html
      expect(response).to be_success
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params['text']).to eq CGI::escape(html)
    end

    it "should find account-level tools" do
      @user = account_admin_user
      user_session(@user)

      tool = new_valid_tool(Account.default)
      get 'resource_selection', :account_id => Account.default.id, :external_tool_id => tool.id
      expect(response).to be_success
      expect(assigns[:tool]).to eq tool
    end

    it "should be accessible even after course is soft-concluded" do
      user_session(@student)
      @course.start_at = 2.days.ago
      @course.conclude_at = 1.day.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      expect(response).to be_success
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params['custom_canvas_enrollment_state']).to eq 'inactive'
    end

    it "should be accessible even after course is hard-concluded" do
      user_session(@student)
      @course.complete

      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      expect(response).to be_success
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params['custom_canvas_enrollment_state']).to eq 'inactive'
    end

    it "should be accessible even after enrollment is concluded and include a parameter indicating inactive state" do
      user_session(@student)
      e = @student.enrollments.first
      e.conclude
      e.reload
      expect(e.workflow_state).to eq 'completed'

      tool = new_valid_tool(@course)
      get 'resource_selection', :course_id => @course.id, :external_tool_id => tool.id
      expect(response).to be_success
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params['custom_canvas_enrollment_state']).to eq 'inactive'
    end
  end

  describe "PUT 'update'" do

    context "form post", type: :request do

      let(:post_body) {
        'external_tool%5Bname%5D=IMS+Cert+Tool&external_tool%5Bprivacy_level%5D=name_only'\
        '&external_tool%5Bconsumer_key%5D=29f0c0ad-0cff-433f-8e35-797bd34710ea&external_tool'\
        '%5Bcustom_fields%5Bsimple_key%5D%5D=custom_simple_value&external_tool%5Bcustom_fields'\
        '%5Bcert_userid%5D%5D=%24User.id&external_tool%5Bcustom_fields%5BComplex!%40%23%24%5E*()'\
        '%7B%7D%5B%5DKEY%5D%5D=Complex!%40%23%24%5E*%3B()%7B%7D%5B%5D%C2%BDValue&external_tool'\
        '%5Bcustom_fields%5Bcert_username%5D%5D=%24User.username&external_tool%5Bcustom_fields'\
        '%5Btc_profile_url%5D%5D=%24ToolConsumerProfile.url&external_tool%5Bdomain%5D=null&'\
        'external_tool%5Burl%5D=https%3A%2F%2Fwww.imsglobal.org%2Flti%2Fcert%2Ftc_tool.php%3F'\
        'x%3DWith%2520Space%26y%3Dyes&external_tool%5Bdescription%5D=null&external_tool%5Bshared_secret%5D=secret'
      }

      it 'accepts form data' do
        user_session(@teacher)
        tool = new_valid_tool(@course)
        put(
          "/api/v1/courses/#{@course.id}/external_tools/#{tool.id}",
          post_body,
          { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded '}
        )
        expect(response).to be_success
        expect(assigns[:tool]).not_to be_nil
      end

      it 'uses custom parsing for form data' do
        user_session(@teacher)
        tool = new_valid_tool(@course)
        put(
          "/api/v1/courses/#{@course.id}/external_tools/#{tool.id}",
          post_body,
          { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded '}
        )

        expect(assigns[:tool].settings[:custom_fields]["Complex!@#$^*(){}[]KEY"]).to eq 'Complex!@#$^*;(){}[]½Value'
      end
    end
  end

  describe "POST 'create'" do

    context "form post", type: :request do

      let(:post_body) {
        'external_tool%5Bname%5D=IMS+Cert+Tool&external_tool%5Bprivacy_level%5D=name_only'\
        '&external_tool%5Bconsumer_key%5D=29f0c0ad-0cff-433f-8e35-797bd34710ea&external_tool'\
        '%5Bcustom_fields%5Bsimple_key%5D%5D=custom_simple_value&external_tool%5Bcustom_fields'\
        '%5Bcert_userid%5D%5D=%24User.id&external_tool%5Bcustom_fields%5BComplex!%40%23%24%5E*()'\
        '%7B%7D%5B%5DKEY%5D%5D=Complex!%40%23%24%5E*%3B()%7B%7D%5B%5D%C2%BDValue&external_tool'\
        '%5Bcustom_fields%5Bcert_username%5D%5D=%24User.username&external_tool%5Bcustom_fields'\
        '%5Btc_profile_url%5D%5D=%24ToolConsumerProfile.url&external_tool%5Bdomain%5D=null&'\
        'external_tool%5Burl%5D=https%3A%2F%2Fwww.imsglobal.org%2Flti%2Fcert%2Ftc_tool.php%3F'\
        'x%3DWith%2520Space%26y%3Dyes&external_tool%5Bdescription%5D=null&external_tool%5Bshared_secret%5D=secret'
      }

      it 'accepts form data' do
        user_session(@teacher)
        post(
          "/api/v1/courses/#{@course.id}/external_tools",
          post_body,
          { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded '}
        )
        expect(response).to be_success
        expect(assigns[:tool]).not_to be_nil
      end

      it 'uses custom parsing for form data' do
        user_session(@teacher)
        post(
          "/api/v1/courses/#{@course.id}/external_tools",
          post_body,
          { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded '}
        )
        tool = assigns[:tool]
        expect(tool.settings[:custom_fields]["Complex!@#$^*(){}[]KEY"]).to eq 'Complex!@#$^*;(){}[]½Value'
      end

    end

    it "should require authentication" do
      post 'create', :course_id => @course.id, :format => "json"
      assert_status(401)
    end

    it "should accept basic configurations" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret"}, :format => "json"
      expect(response).to be_success
      expect(assigns[:tool]).not_to be_nil
      expect(assigns[:tool].name).to eq "tool name"
      expect(assigns[:tool].url).to eq "http://example.com"
      expect(assigns[:tool].consumer_key).to eq "key"
      expect(assigns[:tool].shared_secret).to eq "secret"
    end

    it "should fail on basic xml with no url or domain set" do
      user_session(@teacher)
      xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
    xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
    xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
    xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
    xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
    http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
    <blti:title>Other Name</blti:title>
    <blti:description>Description</blti:description>
    <blti:extensions platform="canvas.instructure.com">
      <lticm:property name="privacy_level">public</lticm:property>
    </blti:extensions>
    <cartridge_bundle identifierref="BLTI001_Bundle"/>
    <cartridge_icon identifierref="BLTI001_Icon"/>
</cartridge_basiclti_link>
      XML
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
      expect(response).not_to be_success
    end

    it "should handle advanced xml configurations" do
      user_session(@teacher)
      xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
    xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
    xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
    xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
    xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
    http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
    <blti:title>Other Name</blti:title>
    <blti:description>Description</blti:description>
    <blti:launch_url>http://example.com/other_url</blti:launch_url>
    <blti:extensions platform="canvas.instructure.com">
      <lticm:property name="privacy_level">public</lticm:property>
      <lticm:property name="not_selectable">true</lticm:property>
      <lticm:options name="editor_button">
        <lticm:property name="url">http://example.com/editor</lticm:property>
        <lticm:property name="icon_url">http://example.com/icon.png</lticm:property>
        <lticm:property name="text">Editor Button</lticm:property>
        <lticm:property name="selection_width">500</lticm:property>
        <lticm:property name="selection_height">300</lticm:property>
      </lticm:options>
    </blti:extensions>
    <cartridge_bundle identifierref="BLTI001_Bundle"/>
    <cartridge_icon identifierref="BLTI001_Icon"/>
</cartridge_basiclti_link>
      XML
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
      expect(response).to be_success
      expect(assigns[:tool]).not_to be_nil
      # User-entered name overrides name provided in xml
      expect(assigns[:tool].name).to eq "tool name"
      expect(assigns[:tool].description).to eq "Description"
      expect(assigns[:tool].url).to eq "http://example.com/other_url"
      expect(assigns[:tool].consumer_key).to eq "key"
      expect(assigns[:tool].shared_secret).to eq "secret"
      expect(assigns[:tool].not_selectable).to be_truthy
      expect(assigns[:tool].has_placement?(:editor_button)).to be_truthy
    end

    it "should handle advanced xml configurations with no url or domain set" do
      user_session(@teacher)
      xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
    xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
    xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
    xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
    xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
    http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
    <blti:title>Other Name</blti:title>
    <blti:description>Description</blti:description>
    <blti:extensions platform="canvas.instructure.com">
      <lticm:property name="privacy_level">public</lticm:property>
      <lticm:options name="editor_button">
        <lticm:property name="url">http://example.com/editor</lticm:property>
        <lticm:property name="icon_url">http://example.com/icon.png</lticm:property>
        <lticm:property name="text">Editor Button</lticm:property>
        <lticm:property name="selection_width">500</lticm:property>
        <lticm:property name="selection_height">300</lticm:property>
      </lticm:options>
    </blti:extensions>
    <cartridge_bundle identifierref="BLTI001_Bundle"/>
    <cartridge_icon identifierref="BLTI001_Icon"/>
</cartridge_basiclti_link>
      XML
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
      expect(response).to be_success
      expect(assigns[:tool]).not_to be_nil
      # User-entered name overrides name provided in xml
      expect(assigns[:tool].name).to eq "tool name"
      expect(assigns[:tool].description).to eq "Description"
      expect(assigns[:tool].url).to be_nil
      expect(assigns[:tool].domain).to be_nil
      expect(assigns[:tool].consumer_key).to eq "key"
      expect(assigns[:tool].shared_secret).to eq "secret"
      expect(assigns[:tool].has_placement?(:editor_button)).to be_truthy
    end

    it "should handle advanced xml configurations by URL retrieval" do
      user_session(@teacher)
      xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
    xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
    xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
    xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
    xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
    http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
    <blti:title>Other Name</blti:title>
    <blti:description>Description</blti:description>
    <blti:launch_url>http://example.com/other_url</blti:launch_url>
    <blti:extensions platform="canvas.instructure.com">
      <lticm:property name="privacy_level">public</lticm:property>
      <lticm:options name="editor_button">
        <lticm:property name="url">http://example.com/editor</lticm:property>
        <lticm:property name="icon_url">http://example.com/icon.png</lticm:property>
        <lticm:property name="text">Editor Button</lticm:property>
        <lticm:property name="selection_width">500</lticm:property>
        <lticm:property name="selection_height">300</lticm:property>
      </lticm:options>
    </blti:extensions>
    <cartridge_bundle identifierref="BLTI001_Bundle"/>
    <cartridge_icon identifierref="BLTI001_Icon"/>
</cartridge_basiclti_link>
      XML
      obj = OpenStruct.new({:body => xml})
      Net::HTTP.any_instance.stubs(:request).returns(obj)
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_url", :config_url => "http://config.example.com"}, :format => "json"

      expect(response).to be_success
      expect(assigns[:tool]).not_to be_nil
      # User-entered name overrides name provided in xml
      expect(assigns[:tool].name).to eq "tool name"
      expect(assigns[:tool].description).to eq "Description"
      expect(assigns[:tool].url).to eq "http://example.com/other_url"
      expect(assigns[:tool].consumer_key).to eq "key"
      expect(assigns[:tool].shared_secret).to eq "secret"
      expect(assigns[:tool].has_placement?(:editor_button)).to be_truthy
    end

    it "should fail gracefully on invalid URL retrieval or timeouts" do
      Net::HTTP.any_instance.stubs(:request).raises(Timeout::Error)
      user_session(@teacher)
      xml = "bob"
      post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_url", :config_url => "http://config.example.com"}, :format => "json"
      expect(response).not_to be_success
      expect(assigns[:tool]).to be_new_record
      json = json_parse(response.body)
      expect(json['errors']['config_url'][0]['message']).to eq I18n.t(:retrieve_timeout, 'could not retrieve configuration, the server response timed out')
    end

    context "navigation tabs caching" do
      it "shouldn't clear the navigation tabs cache for non navigtaion tools" do
        enable_cache do
          user_session(@teacher)
          nav_cache = Lti::NavigationCache.new(@course.root_account)
          cache_key = nav_cache.cache_key
          xml = <<-XML
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
  <blti:title>Redirect Tool</blti:title>
  <blti:description>
    Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.
  </blti:description>
  <blti:launch_url>https://www.edu-apps.org/redirect</blti:launch_url>
  <blti:custom>
    <lticm:property name="url">https://</lticm:property>
  </blti:custom>
  <blti:extensions platform="canvas.instructure.com">
    <lticm:property name="icon_url">
      https://www.edu-apps.org/assets/lti_redirect_engine/redirect_icon.png
    </lticm:property>
    <lticm:property name="link_text"/>
    <lticm:property name="privacy_level">anonymous</lticm:property>
    <lticm:property name="tool_id">redirect</lticm:property>
  </blti:extensions>
</cartridge_basiclti_link>
          XML
          post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
          expect(response).to be_success
          expect(nav_cache.cache_key).to eq cache_key
        end
      end

      it 'should clear the navigation tabs cache for course nav' do
        enable_cache do
          user_session(@teacher)
          cache_key = Lti::NavigationCache.new(@course.root_account).cache_key
          xml = <<-XML
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
  <blti:title>Redirect Tool</blti:title>
  <blti:description>
    Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.
  </blti:description>
  <blti:launch_url>https://www.edu-apps.org/redirect</blti:launch_url>
  <blti:custom>
    <lticm:property name="url">https://</lticm:property>
  </blti:custom>
  <blti:extensions platform="canvas.instructure.com">
    <lticm:options name="course_navigation">
      <lticm:property name="enabled">true</lticm:property>
      <lticm:property name="visibility">public</lticm:property>
    </lticm:options>
    <lticm:property name="icon_url">
      https://www.edu-apps.org/assets/lti_redirect_engine/redirect_icon.png
    </lticm:property>
    <lticm:property name="link_text"/>
    <lticm:property name="privacy_level">anonymous</lticm:property>
    <lticm:property name="tool_id">redirect</lticm:property>
  </blti:extensions>
</cartridge_basiclti_link>
          XML
          post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
          expect(response).to be_success
          expect(Lti::NavigationCache.new(@course.root_account).cache_key).not_to eq cache_key
        end
      end

      it 'should clear the navigation tabs cache for account nav' do
        enable_cache do
          user_session(@teacher)
          cache_key = Lti::NavigationCache.new(@course.root_account).cache_key
          xml = <<-XML
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
  <blti:title>Redirect Tool</blti:title>
  <blti:description>
    Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.
  </blti:description>
  <blti:launch_url>https://www.edu-apps.org/redirect</blti:launch_url>
  <blti:custom>
    <lticm:property name="url">https://</lticm:property>
  </blti:custom>
  <blti:extensions platform="canvas.instructure.com">
    <lticm:options name="account_navigation">
      <lticm:property name="enabled">true</lticm:property>
      <lticm:property name="visibility">public</lticm:property>
    </lticm:options>
    <lticm:property name="icon_url">
      https://www.edu-apps.org/assets/lti_redirect_engine/redirect_icon.png
    </lticm:property>
    <lticm:property name="link_text"/>
    <lticm:property name="privacy_level">anonymous</lticm:property>
    <lticm:property name="tool_id">redirect</lticm:property>
  </blti:extensions>
</cartridge_basiclti_link>
          XML
          post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
          expect(response).to be_success
          expect(Lti::NavigationCache.new(@course.root_account).cache_key).not_to eq cache_key
        end
      end

      it 'should clear the navigation tabs cache for user nav' do
        enable_cache do
          user_session(@teacher)
          cache_key = Lti::NavigationCache.new(@course.root_account).cache_key
          xml = <<-XML
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
  <blti:title>Redirect Tool</blti:title>
  <blti:description>
    Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.
  </blti:description>
  <blti:launch_url>https://www.edu-apps.org/redirect</blti:launch_url>
  <blti:custom>
    <lticm:property name="url">https://</lticm:property>
  </blti:custom>
  <blti:extensions platform="canvas.instructure.com">
    <lticm:options name="user_navigation">
      <lticm:property name="enabled">true</lticm:property>
      <lticm:property name="visibility">public</lticm:property>
    </lticm:options>
    <lticm:property name="icon_url">
      https://www.edu-apps.org/assets/lti_redirect_engine/redirect_icon.png
    </lticm:property>
    <lticm:property name="link_text"/>
    <lticm:property name="privacy_level">anonymous</lticm:property>
    <lticm:property name="tool_id">redirect</lticm:property>
  </blti:extensions>
</cartridge_basiclti_link>
          XML
          post 'create', :course_id => @course.id, :external_tool => {:name => "tool name", :url => "http://example.com", :consumer_key => "key", :shared_secret => "secret", :config_type => "by_xml", :config_xml => xml}, :format => "json"
          expect(response).to be_success
          expect(Lti::NavigationCache.new(@course.root_account).cache_key).not_to eq cache_key
        end
      end
    end

  end

  describe "'GET 'generate_sessionless_launch'" do
    it "generates a sessionless launch" do
      @tool = new_valid_tool(@course)
      user_session(@user)

      get :generate_sessionless_launch, :course_id => @course.id, id: @tool.id

      expect(response).to be_success

      json = JSON.parse(response.body.sub(/^while\(1\)\;/, ''))
      verifier = CGI.parse(URI.parse(json['url']).query)['verifier'].first
      redis_key = "#{@course.class.name}:#{ExternalToolsController::REDIS_PREFIX}#{verifier}"
      launch_settings = JSON.parse(Canvas.redis.get(redis_key))
      tool_settings = launch_settings['tool_settings']

      expect(launch_settings['launch_url']).to eq 'http://www.example.com/basic_lti'
      expect(launch_settings['tool_name']).to eq 'bob'
      expect(launch_settings['analytics_id']).to eq 'some_tool'
      expect(tool_settings['custom_canvas_course_id']).to eq @course.id.to_s
      expect(tool_settings['custom_canvas_user_id']).to eq @user.id.to_s
    end

    it "generates a sessionless launch for an external tool assignment" do
      tool = new_valid_tool(@course)
      user_session(@user)
      assignment_model(:course => @course,
                       :name => 'tool assignment',
                       :submission_types => 'external_tool',
                       :points_possible => 20,
                       :grading_type => 'points')
      tag = @assignment.build_external_tool_tag(:url => tool.url)
      tag.content_type = 'ContextExternalTool'
      tag.save!

      get :generate_sessionless_launch, course_id: @course.id, launch_type: 'assessment', assignment_id: @assignment.id

      expect(response).to be_success

      json = JSON.parse(response.body.sub(/^while\(1\)\;/, ''))
      verifier = CGI.parse(URI.parse(json['url']).query)['verifier'].first
      redis_key = "#{@course.class.name}:#{ExternalToolsController::REDIS_PREFIX}#{verifier}"
      launch_settings = JSON.parse(Canvas.redis.get(redis_key))
      tool_settings = launch_settings['tool_settings']

      expect(launch_settings['launch_url']).to eq 'http://www.example.com/basic_lti'
      expect(launch_settings['tool_name']).to eq 'bob'
      expect(launch_settings['analytics_id']).to eq 'some_tool'
      expect(tool_settings['custom_canvas_course_id']).to eq @course.id.to_s
      expect(tool_settings['custom_canvas_user_id']).to eq @user.id.to_s
      expect(tool_settings["resource_link_id"]).to eq opaque_id(@assignment.external_tool_tag)
    end
  end

  def opaque_id(asset)
    if asset.respond_to?('lti_context_id')
      Lti::Asset.global_context_id_for(asset)
    else
      Lti::Asset.context_id_for(asset)
    end
  end

end

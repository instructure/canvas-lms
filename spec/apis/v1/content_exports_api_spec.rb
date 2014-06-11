#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe ContentExportsApiController, type: :request do
  let(:t_teacher) do
    user(active_all: true)
  end

  let(:t_course) do
    course_with_teacher(user: t_teacher, active_all: true)
    @course.wiki.wiki_pages.create! title: "something to export"
    @course
  end

  def past_export
    export = t_course.content_exports.create
    export.export_type = 'common_cartridge'
    export.workflow_state = 'exported'
    export.user = t_teacher
    att = export.attachments.create! filename: 'blah', uploaded_data: StringIO.new('blah')
    export.attachment_id = att.id
    export.save
    progress = Progress.new(context: export, completion: 100, tag: 'course_export')
    progress.workflow_state = 'completed'
    progress.save!
    export
  end

  def pending_export
    export = t_course.content_exports.create
    export.export_type = 'qti'
    export.save
    progress = Progress.create!(context: export, tag: 'course_export')
    export
  end

  def course_copy_export
    export = t_course.content_exports.create
    export.export_type = 'course_copy'
    export.save
    export
  end

  describe "index" do
    it "should check permissions" do
      student = student_in_course(course: t_course, active_all: true).user
      api_call_as_user(student, :get, "/api/v1/courses/#{t_course.id}/content_exports",
        { controller: 'content_exports_api', action: 'index', format: 'json', course_id: t_course.to_param },
        {}, {}, { expected_status: 401 })
    end

    it "should return the correct data" do
      @past = past_export
      @pending = pending_export
      @cc = course_copy_export
      json = api_call_as_user(t_teacher, :get, "/api/v1/courses/#{t_course.id}/content_exports",
         { controller: 'content_exports_api', action: 'index', format: 'json', course_id: t_course.to_param })

      json.size.should eql 2
      json[0]['id'].should eql @pending.id
      json[0]['workflow_state'].should eql 'created'
      json[0]['export_type'].should eql 'qti'
      json[0]['course_id'].should eql t_course.id
      json[0]['created_at'].should eql @pending.created_at.as_json
      json[0]['progress_url'].should be_include "/progress/#{@pending.job_progress.id}"

      json[1]['id'].should eql @past.id
      json[1]['workflow_state'].should eql 'exported'
      json[1]['export_type'].should eql 'common_cartridge'
      json[1]['course_id'].should eql t_course.id
      json[1]['created_at'].should eql @past.created_at.as_json
      json[1]['user_id'].should eql t_teacher.id
      json[1]['progress_url'].should be_include "/progress/#{@past.job_progress.id}"
      json[1]['attachment']['url'].should be_include "/files/#{@past.attachment.id}/download?download_frd=1&verifier=#{@past.attachment.uuid}"
    end

    it "should paginate" do
      exports = (1..5).map { pending_export }
      json = api_call_as_user(t_teacher, :get, "/api/v1/courses/#{t_course.id}/content_exports?per_page=3",
         { controller: 'content_exports_api', action: 'index', format: 'json', course_id: t_course.to_param, per_page: '3' })
      json.size.should eql 3
      json += api_call_as_user(t_teacher, :get, "/api/v1/courses/#{t_course.id}/content_exports?per_page=3&page=2",
         { controller: 'content_exports_api', action: 'index', format: 'json', course_id: t_course.to_param, per_page: '3', page: '2' })
      json.size.should eql 5
      json.map{ |el| el['id'] }.should eql exports.map(&:id).sort.reverse
    end
  end

  describe "show" do
    it "should check permissions" do
      @past = past_export
      student = student_in_course(course: t_course, active_all: true).user
      api_call_as_user(student, :get, "/api/v1/courses/#{t_course.id}/content_exports/#{@past.id}",
         { controller: 'content_exports_api', action: 'show', format: 'json', course_id: t_course.to_param, id: @past.to_param },
         {}, {}, { expected_status: 401 })
    end

    it "should return the correct data" do
      @past = past_export
      json = api_call_as_user(t_teacher, :get, "/api/v1/courses/#{t_course.id}/content_exports/#{@past.id}",
         { controller: 'content_exports_api', action: 'show', format: 'json', course_id: t_course.to_param, id: @past.to_param })
      json['id'].should eql @past.id
      json['workflow_state'].should eql 'exported'
      json['export_type'].should eql 'common_cartridge'
      json['course_id'].should eql t_course.id
      json['created_at'].should eql @past.created_at.as_json
      json['user_id'].should eql t_teacher.id
      json['attachment']['url'].should be_include "/files/#{@past.attachment.id}/download?download_frd=1&verifier=#{@past.attachment.uuid}"
    end

    it "should not find course copy exports" do
      @cc = course_copy_export
      json = api_call_as_user(t_teacher, :get, "/api/v1/courses/#{t_course.id}/content_exports/#{@cc.id}",
         { controller: 'content_exports_api', action: 'show', format: 'json', course_id: t_course.to_param, id: @cc.to_param },
         {}, {}, { expected_status: 404 })
    end
  end

  describe "create" do
    it "should check permissions" do
      student = student_in_course(course: t_course, active_all: true).user
      json = api_call_as_user(student, :post, "/api/v1/courses/#{t_course.id}/content_exports?export_type=qti",
        { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param, export_type: 'qti' },
        {}, {}, { expected_status: 401 })
    end

    it "should require an export_type parameter" do
      json = api_call_as_user(t_teacher, :post, "/api/v1/courses/#{t_course.id}/content_exports",
        { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param },
        {}, {}, { expected_status: 400 })
    end

    it "should require a sensible export_type parameter" do
      json = api_call_as_user(t_teacher, :post, "/api/v1/courses/#{t_course.id}/content_exports?export_type=frog",
        { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param, export_type: 'frog' },
        {}, {}, { expected_status: 400 })
    end

    it "should create a qti export" do
      json = api_call_as_user(t_teacher, :post, "/api/v1/courses/#{t_course.id}/content_exports?export_type=qti",
        { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param, export_type: 'qti' })
      export = t_course.content_exports.find_by_id(json['id'])
      export.should_not be_nil
      export.workflow_state.should eql 'created'
      export.export_type.should eql 'qti'
      export.user_id.should eql t_teacher.id
      export.settings['selected_content']['all_quizzes'].should be_true
      export.job_progress.should be_queued
    end

    it "should create a course export and update progress" do
      json = api_call_as_user(t_teacher, :post, "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
        { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param, export_type: 'common_cartridge' })
      export = t_course.content_exports.find_by_id(json['id'])
      export.should_not be_nil
      export.workflow_state.should eql 'created'
      export.export_type.should eql 'common_cartridge'
      export.user_id.should eql t_teacher.id
      export.settings['selected_content']['everything'].should be_true
      export.job_progress.should be_queued

      run_jobs

      export.reload
      export.workflow_state.should eql 'exported'
      export.job_progress.should be_completed
      export.attachment.should_not be_nil
    end

    it "should create a 1.3 common cartridge if specified" do
      t_course.assignments.create! name: 'teh assignment', description: '<b>what</b>', points_possible: 11, submission_types: 'online_text_entry'
      json = api_call_as_user(t_teacher, :post, "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge&version=1.3",
        { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param, export_type: 'common_cartridge',
          version: '1.3' })
      export = t_course.content_exports.find(json['id'])
      run_jobs
      f = export.reload.attachment.open(need_local_file: true)
      Zip::File.open(f.path) do |zf|
        doc = Nokogiri::XML(zf.read('imsmanifest.xml'))
        doc.at_css('metadata schemaversion').text.should == '1.3.0'
      end
    end

  end
end

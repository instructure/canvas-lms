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
  let_once(:t_teacher) do
    user(active_all: true)
  end

  let_once(:t_course) do
    course_with_teacher(user: t_teacher, active_all: true)
    @course.wiki.wiki_pages.create! title: "something to export"
    @course
  end

  let_once(:t_student) do
    student_in_course(course: t_course, active_all: true).user
  end

  def past_export(context = t_course, user = t_teacher, type = 'common_cartridge')
    export = context.content_exports.create
    export.export_type = type
    export.workflow_state = 'exported'
    export.user = user
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
    export.save!
    export
  end

  describe "index" do
    it "should check permissions" do
      random_user = user active_all: true
      api_call_as_user(random_user, :get, "/api/v1/courses/#{t_course.id}/content_exports",
        { controller: 'content_exports_api', action: 'index', format: 'json', course_id: t_course.to_param },
        {}, {}, { expected_status: 401 })
    end

    it "should return the correct data" do
      @my_zip_export = past_export(t_course, t_teacher, 'zip')
      @other_zip_export = past_export(t_course, t_student, 'zip')
      @past = past_export
      @pending = pending_export
      @cc = course_copy_export
      json = api_call_as_user(t_teacher, :get, "/api/v1/courses/#{t_course.id}/content_exports",
         { controller: 'content_exports_api', action: 'index', format: 'json', course_id: t_course.to_param })

      json.size.should eql 3
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

      json[2]['id'].should eql @my_zip_export.id
      json[2]['workflow_state'].should eql 'exported'
      json[2]['export_type'].should eql 'zip'
      json[2]['course_id'].should eql t_course.id
      json[2]['created_at'].should eql @my_zip_export.created_at.as_json
      json[2]['user_id'].should eql t_teacher.id
      json[2]['progress_url'].should be_include "/progress/#{@my_zip_export.job_progress.id}"
      json[2]['attachment']['url'].should be_include "/files/#{@my_zip_export.attachment.id}/download?download_frd=1&verifier=#{@my_zip_export.attachment.uuid}"
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
      api_call_as_user(t_student, :get, "/api/v1/courses/#{t_course.id}/content_exports/#{@past.id}",
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

    it "should not read other users' zip exports" do
      @zip_export = past_export(t_course, t_student, 'zip')
      json = api_call_as_user(t_teacher, :get, "/api/v1/courses/#{t_course.id}/content_exports/#{@zip_export.id}",
                              { controller: 'content_exports_api', action: 'show', format: 'json', course_id: t_course.to_param, id: @zip_export.to_param },
                              {}, {}, { expected_status: 401 })
    end
  end

  describe "create" do
    it "should check permissions" do
      json = api_call_as_user(t_student, :post, "/api/v1/courses/#{t_course.id}/content_exports?export_type=qti",
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

    it "should set skip notifications flag" do
      json = api_call_as_user(t_teacher, :post, "/api/v1/courses/#{t_course.id}/content_exports",
        { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param, export_type: 'common_cartridge', skip_notifications: true })
      export = t_course.content_exports.find_by_id(json['id'])
      export.send_notification?.should be_false
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

    context "selective exports" do
      let_once :att_to_copy do
        Attachment.create!(:context => t_course, :filename => 'hi.txt',
                           :uploaded_data => StringIO.new("stuff"), :folder => Folder.unfiled_folder(t_course))
      end
      let_once :att_to_not_copy do
        Attachment.create!(:context => t_course, :filename => 'derp.txt',
                           :uploaded_data => StringIO.new("more stuff"), :folder => Folder.unfiled_folder(t_course))
      end
      let_once :page_to_copy do
        page_to_copy = t_course.wiki.wiki_pages.create!(:title => "other page")
        page_to_copy.body = "<p><a href=\"/courses/#{t_course.id}/files/#{att_to_copy.id}/preview\">hey look a link</a></p>"
        page_to_copy.save!
        page_to_copy
      end
      let_once(:page_to_not_copy){ t_course.wiki.wiki_pages.create!(:title => "another page") }
      let_once(:mod) do
        # both the wiki page and the referenced attachment should be exported implicitly through the module
        mod = t_course.context_modules.create!(:name => "who cares")
        mod.add_item(:id => page_to_copy.id, :type => "wiki_page")
        mod
      end

      it "should create a selective course export with old migration id format" do
        json = api_call_as_user(t_teacher, :post, "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param, export_type: 'common_cartridge'},
                                { :select => {:context_modules => {mod.asset_string => "1"}}})
        export = t_course.content_exports.find_by_id(json['id'])
        export.should_not be_nil
        export.workflow_state.should eql 'created'
        export.export_type.should eql 'common_cartridge'
        export.user_id.should eql t_teacher.id
        export.settings['selected_content']['context_modules'].should == {CC::CCHelper.create_key(mod) => "1"}
        export.job_progress.should be_queued

        run_jobs

        export.reload
        export.workflow_state.should eql 'exported'
        export.job_progress.should be_completed
        export.attachment.should_not be_nil

        course
        cm = @course.content_migrations.new
        cm.attachment = export.attachment
        cm.migration_type = "canvas_cartridge_importer"
        cm.migration_settings[:import_immediately] = true
        cm.save!
        cm.queue_migration

        run_jobs

        @course.context_modules.find_by_migration_id(CC::CCHelper.create_key(mod)).should_not be_nil
        copied_page = @course.wiki.wiki_pages.find_by_migration_id(CC::CCHelper.create_key(page_to_copy))
        copied_page.should_not be_nil
        @course.wiki.wiki_pages.find_by_migration_id(CC::CCHelper.create_key(page_to_not_copy)).should be_nil

        copied_att = @course.attachments.find_by_filename(att_to_copy.filename)
        copied_att.should_not be_nil
        copied_page.body.should == "<p><a href=\"/courses/#{@course.id}/files/#{copied_att.id}/preview\">hey look a link</a></p>"
        @course.attachments.find_by_filename(att_to_not_copy.filename).should be_nil
      end

      it "should create a selective course export with arrays of ids" do
        json = api_call_as_user(t_teacher, :post, "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                                { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param, export_type: 'common_cartridge'},
                                { :select => {:context_modules => [mod.id]}})
        export = t_course.content_exports.find_by_id(json['id'])
        export.should_not be_nil
        export.workflow_state.should eql 'created'
        export.export_type.should eql 'common_cartridge'
        export.user_id.should eql t_teacher.id
        export.settings['selected_content']['context_modules'].should == {CC::CCHelper.create_key(mod) => "1"}
        export.job_progress.should be_queued

        run_jobs

        export.reload
        export.workflow_state.should eql 'exported'
        export.job_progress.should be_completed
        export.attachment.should_not be_nil

        course
        cm = @course.content_migrations.new
        cm.attachment = export.attachment
        cm.migration_type = "canvas_cartridge_importer"
        cm.migration_settings[:import_immediately] = true
        cm.save!
        cm.queue_migration

        run_jobs

        @course.context_modules.find_by_migration_id(CC::CCHelper.create_key(mod)).should_not be_nil
        copied_page = @course.wiki.wiki_pages.find_by_migration_id(CC::CCHelper.create_key(page_to_copy))
        copied_page.should_not be_nil
        @course.wiki.wiki_pages.find_by_migration_id(CC::CCHelper.create_key(page_to_not_copy)).should be_nil

        copied_att = @course.attachments.find_by_filename(att_to_copy.filename)
        copied_att.should_not be_nil
        copied_page.body.should == "<p><a href=\"/courses/#{@course.id}/files/#{copied_att.id}/preview\">hey look a link</a></p>"
        @course.attachments.find_by_filename(att_to_not_copy.filename).should be_nil
      end
    end
  end

  describe "#content_list" do
    it "should return a list of exportable content for a course directly" do
      @dt1 = @course.discussion_topics.create!(:message => "hi", :title => "discussion title")
      @cm = @course.context_modules.create!(:name => "some module")
      @att = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@course), :context => @course)
      @wiki = @course.wiki.wiki_pages.create!(:title => "wiki", :body => "ohai")

      @quiz = @course.quizzes.create!(:title => "quizz")
      @quiz.did_edit
      @quiz.offer!
      @quiz.assignment.should_not be_nil

      list_url = "/api/v1/courses/#{@course.id}/content_list"
      params = {:controller => 'content_exports_api', :format => 'json', :course_id => @course.id.to_param, :action => 'content_list'}
      json = api_call_as_user(t_teacher, :get, list_url, params)
      json.sort_by{|h| h['type']}.should == [
        {"type"=>"assignments", "property"=>"select[all_assignments]", "title"=>"Assignments", "count"=>1, "sub_items_url"=>"http://www.example.com/api/v1/courses/#{@course.id}/content_list?type=assignments"},
        {"type"=>"attachments", "property"=>"select[all_attachments]", "title"=>"Files", "count"=>1, "sub_items_url"=>"http://www.example.com/api/v1/courses/#{@course.id}/content_list?type=attachments"},
        {"type"=>"context_modules", "property"=>"select[all_context_modules]", "title"=>"Modules", "count"=>1, "sub_items_url"=>"http://www.example.com/api/v1/courses/#{@course.id}/content_list?type=context_modules"},
        {"type"=>"course_settings", "property"=>"select[all_course_settings]", "title"=>"Course Settings"},
        {"type"=>"discussion_topics", "property"=>"select[all_discussion_topics]", "title"=>"Discussion Topics", "count"=>1, "sub_items_url"=>"http://www.example.com/api/v1/courses/#{@course.id}/content_list?type=discussion_topics"},
        {"type"=>"quizzes", "property"=>"select[all_quizzes]", "title"=>"Quizzes", "count"=>1, "sub_items_url"=>"http://www.example.com/api/v1/courses/#{@course.id}/content_list?type=quizzes"},
        {"type"=>"syllabus_body", "property"=>"select[all_syllabus_body]", "title"=>"Syllabus Body"},
        {"type"=>"wiki_pages", "property"=>"select[all_wiki_pages]", "title"=>"Wiki Pages", "count"=>2, "sub_items_url"=>"http://www.example.com/api/v1/courses/#{@course.id}/content_list?type=wiki_pages"}
      ]

      json = api_call_as_user(t_teacher, :get, list_url + '?type=context_modules', params.merge({type: 'context_modules'}))
      json.length.should == 1
      json.first["type"].should == 'context_modules'
      json.first["title"].should == @cm.name
      json.first["id"].should == @cm.asset_string

      json = api_call_as_user(t_teacher, :get, list_url + '?type=quizzes', params.merge({type: 'quizzes'}))
      json.first["type"].should == 'quizzes'
      json.first["title"].should == @quiz.title
      json.first["id"].should == @quiz.asset_string
      json.first['linked_resource']['id'].should == @quiz.assignment.asset_string
    end
  end

  describe "zip exports" do
    context "course" do
      before do
        @root_folder = Folder.root_folders(t_course).first
        @file1 = attachment_model context: t_course, display_name: 'file1.txt', folder: @root_folder, uploaded_data: stub_file_data('file1.txt', 'file1', 'text/plain')
        @sub_folder = t_course.folders.create! name: 'teh_folder', parent_folder: @root_folder, locked: true
        @file2 = attachment_model context: t_course, display_name: 'file2.txt', folder: @sub_folder, uploaded_data: stub_file_data('file2.txt', 'file2', 'text/plain')
      end

      it "should download course files" do
        json = api_call_as_user(t_teacher, :post, "/api/v1/courses/#{t_course.id}/content_exports?export_type=zip",
                        { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param, export_type: 'zip' })
        run_jobs
        export = t_course.content_exports.find_by_id(json['id'])
        export.should be_present
        export.attachment.should be_present
        export.attachment.display_name.should eql 'course_files_export.zip'
        tf = export.attachment.open need_local_file: true
        Zip::File.open(tf) do |zf|
          zf.entries.map(&:name).should =~ %w(file1.txt teh_folder/file2.txt)
        end
      end

      it "should support content selection" do
        file3 = attachment_model context: t_course, display_name: 'file3.txt', folder: @root_folder, uploaded_data: stub_file_data('file3.txt', 'file3', 'text/plain')
        json = api_call_as_user(t_teacher, :post, "/api/v1/courses/#{t_course.id}/content_exports?export_type=zip&select[folders][]=#{@sub_folder.id}&select[attachments][]=#{file3.id}",
                                { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param,
                                  export_type: 'zip', select: {'folders' => [@sub_folder.to_param], 'attachments' => [file3.to_param]} })
        run_jobs
        export = t_course.content_exports.find_by_id(json['id'])
        export.should be_present
        export.attachment.should be_present
        export.attachment.display_name.should eql 'course_files_export.zip'
        tf = export.attachment.open need_local_file: true
        Zip::File.open(tf) do |zf|
          zf.entries.map(&:name).should =~ %w(teh_folder/file2.txt file3.txt)
        end
      end

      context "as a student" do
        it "should exclude non-zip and/or other users' exports from #index" do
          my_zip_export = past_export(t_course, t_student, 'zip')
          past_export(t_course, t_student, 'common_cartridge')  # disallowed type
          past_export(t_course, t_teacher, 'zip')               # other user
          json = api_call_as_user(t_student, :get, "/api/v1/courses/#{t_course.id}/content_exports",
                          { controller: 'content_exports_api', action: 'index', format: 'json', course_id: t_course.to_param })
          json.map{|ex|ex["id"]}.should =~ [my_zip_export.id]
        end

        it "should deny access to admin exports in #show" do
          cc_export = past_export
          api_call_as_user(t_student, :get, "/api/v1/courses/#{t_course.id}/content_exports/#{cc_export.id}",
                           { controller: 'content_exports_api', action: 'show', format: 'json', course_id: t_course.to_param, id: cc_export.to_param },
                           {}, {}, {expected_status: 401})
        end

        it "should exclude locked and deleted folders and files from archive" do
          file3 = attachment_model context: t_course, display_name: 'file3.txt', folder: @root_folder, uploaded_data: stub_file_data('file3.txt', 'file3', 'text/plain'), locked: true
          del_file0 = attachment_model context: t_course, display_name: 'del_file0.txt', folder: @root_folder, uploaded_data: stub_file_data('del_file0.txt', 'del_file0', 'text/plain'), file_state: 'deleted'
          del_folder = t_course.folders.create! name: 'del_folder', parent_folder: @root_folder
          del_file1 = attachment_model context: t_course, display_name: 'del_file1.txt', folder: del_folder, uploaded_data: stub_file_data('del_file1.txt', 'del_file1', 'text/plain')
          del_folder.destroy
          json = api_call_as_user(t_student, :post, "/api/v1/courses/#{t_course.id}/content_exports?export_type=zip",
                          { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param, export_type: 'zip' })
          run_jobs
          export = t_course.content_exports.find_by_id(json['id'])
          export.should be_present
          export.attachment.should be_present
          tf = export.attachment.open need_local_file: true
          Zip::File.open(tf) do |zf|
            zf.entries.map(&:name).should =~ %w(file1.txt)
          end
        end

        it "should reject common cartridge export due to permissions" do
          api_call_as_user(t_student, :post, "/api/v1/courses/#{t_course.id}/content_exports?export_type=common_cartridge",
                   { controller: 'content_exports_api', action: 'create', format: 'json', course_id: t_course.to_param, export_type: 'common_cartridge' },
                   {}, {}, {expected_status: 401})
        end
      end
    end

    context "group" do
      let(:t_group) do
        group_with_user(active_all: true, context: t_course.account, user: t_teacher)
        @group
      end

      it "should require :read permission" do
        user_model
        api_call_as_user(@user, :post, "/api/v1/groups/#{t_group.id}/content_exports?export_type=zip",
                 { controller: 'content_exports_api', action: 'create', format: 'json', group_id: t_group.to_param, export_type: 'zip' },
                 {}, {}, {expected_status: 401})
      end

      it "should create a group file export" do
        json = {}
        expect {
          json = api_call_as_user(t_teacher, :post, "/api/v1/groups/#{t_group.id}/content_exports?export_type=zip",
                          { controller: 'content_exports_api', action: 'create', format: 'json', group_id: t_group.to_param, export_type: 'zip' })
        }.to change(Delayed::Job, :count).by(1)
        export = t_group.content_exports.find(json['id'])
        export.export_type.should == 'zip'
      end

      it "should reject common cartridge format with bad_request" do
        api_call_as_user(t_teacher, :post, "/api/v1/groups/#{t_group.id}/content_exports?export_type=common_cartridge",
                 { controller: 'content_exports_api', action: 'create', format: 'json', group_id: t_group.to_param, export_type: 'common_cartridge' },
                 {}, {}, {expected_status: 400})
      end

      it "should list exports" do
        zip_export = past_export(t_group, t_teacher, 'zip')
        json = api_call_as_user(t_teacher, :get, "/api/v1/groups/#{t_group.id}/content_exports",
                        { controller: 'content_exports_api', action: 'index', format: 'json', group_id: t_group.to_param })
        json.map{|e| e['id']}.should eql [zip_export.id]
      end

      it "should show an export" do
        zip_export = past_export(t_group, t_teacher, 'zip')
        json = api_call_as_user(t_teacher, :get, "/api/v1/groups/#{t_group.id}/content_exports/#{zip_export.id}",
                        { controller: 'content_exports_api', action: 'show', format: 'json', group_id: t_group.to_param, id: zip_export.to_param })
        json['id'].should eql zip_export.id
        json['export_type'].should eql 'zip'
      end
    end

    context "user" do
      it "should require :read permission" do
        api_call_as_user(t_teacher, :post, "/api/v1/users/#{t_student.id}/content_exports?export_type=zip",
                 { controller: 'content_exports_api', action: 'create', format: 'json', user_id: t_student.to_param, export_type: 'zip' },
                 {}, {}, {expected_status: 401})
      end

      it "should create a user file export" do
        json = {}
        expect {
          json = api_call_as_user(t_student, :post, "/api/v1/users/#{t_student.id}/content_exports?export_type=zip",
                                  { controller: 'content_exports_api', action: 'create', format: 'json', user_id: t_student.to_param, export_type: 'zip' })
        }.to change(Delayed::Job, :count).by(1)
        export = t_student.content_exports.find(json['id'])
        export.export_type.should == 'zip'
      end

      it "should reject qti format with bad_request" do
        api_call_as_user(t_student, :post, "/api/v1/users/#{t_student.id}/content_exports?export_type=qti",
                         { controller: 'content_exports_api', action: 'create', format: 'json', user_id: t_student.to_param, export_type: 'qti' },
                         {}, {}, {expected_status: 400})
      end

      it "should list exports created by the user" do
        zip_export = past_export(t_student, t_student, 'zip')
        other_zip_export = past_export(t_student, t_teacher, 'zip')
        json = api_call_as_user(t_student, :get, "/api/v1/users/#{t_student.id}/content_exports",
                                { controller: 'content_exports_api', action: 'index', format: 'json', user_id: t_student.to_param })
        json.map{|e| e['id']}.should eql [zip_export.id]
      end

      it "should show an export" do
        zip_export = past_export(t_student, t_student, 'zip')
        json = api_call_as_user(t_student, :get, "/api/v1/users/#{t_student.id}/content_exports/#{zip_export.id}",
                                { controller: 'content_exports_api', action: 'show', format: 'json', user_id: t_student.to_param, id: zip_export.to_param })
        json['id'].should eql zip_export.id
        json['export_type'].should eql 'zip'
      end

      it "should not show another user's export" do
        zip_export = past_export(t_student, t_student, 'zip')
        json = api_call_as_user(t_teacher, :get, "/api/v1/users/#{t_student.id}/content_exports/#{zip_export.id}",
                                { controller: 'content_exports_api', action: 'show', format: 'json', user_id: t_student.to_param, id: zip_export.to_param },
                                {}, {}, expected_status: 401)
      end
    end
  end
end

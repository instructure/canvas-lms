#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

describe ContentMigrationsController, type: :request do
  before do
    course_with_teacher_logged_in(:active_all => true, :user => user_with_pseudonym)
    @migration_url = "/api/v1/courses/#{@course.id}/content_migrations"
    @params = { :controller => 'content_migrations', :format => 'json', :course_id => @course.id.to_param}

    @migration = @course.content_migrations.create
    @migration.migration_type = 'common_cartridge_importer'
    @migration.context = @course
    @migration.user = @user
    @migration.started_at = 1.week.ago
    @migration.finished_at = 1.day.ago
    @migration.save!
  end

  describe 'index' do
    before do
      @params = @params.merge( :action => 'index')
    end

    it "should return list" do
      json = api_call(:get, @migration_url, @params)
      json.length.should == 1
      json.first['id'].should == @migration.id
    end

    it "should paginate" do
      migration = @course.content_migrations.create!
      json = api_call(:get, @migration_url + "?per_page=1", @params.merge({:per_page=>'1'}))
      json.length.should == 1
      json.first['id'].should == migration.id
      json = api_call(:get, @migration_url + "?per_page=1&page=2", @params.merge({:per_page => '1', :page => '2'}))
      json.length.should == 1
      json.first['id'].should == @migration.id
    end

    it "should 401" do
      course_with_student_logged_in(:course => @course, :active_all => true)
      api_call(:get, @migration_url, @params, {}, {}, :expected_status => 401)
    end

    it "should create the course root folder" do
      @course.folders.should be_empty
      api_call(:get, @migration_url, @params)
      @course.reload.folders.should_not be_empty
    end

    context "User" do
      before do
        @migration = @user.content_migrations.create
        @migration.migration_type = 'zip_file_import'
        @migration.user = @user
        @migration.save!
        @migration_url = "/api/v1/users/#{@user.id}/content_migrations"
        @params = @params.reject{ |k| k == :course_id }.merge(user_id: @user.id)
      end

      it "should return list" do
        json = api_call(:get, @migration_url, @params)
        json.length.should == 1
        json.first['id'].should == @migration.id
      end
    end

    context "Group" do
      before do
        group_with_user user: @user
        @migration = @group.content_migrations.create
        @migration.migration_type = 'zip_file_import'
        @migration.user = @user
        @migration.save!
        @migration_url = "/api/v1/groups/#{@group.id}/content_migrations"
        @params = @params.reject{ |k| k == :course_id }.merge(group_id: @group.id)
      end

      it "should return list" do
        json = api_call(:get, @migration_url, @params)
        json.length.should == 1
        json.first['id'].should == @migration.id
      end
    end

    context "Account" do
      before do
        @account = Account.create!(:name => 'name')
        @account.add_user(@user)
        @migration = @account.content_migrations.create
        @migration.migration_type = 'qti_converter'
        @migration.user = @user
        @migration.save!
        @migration_url = "/api/v1/accounts/#{@account.id}/content_migrations"
        @params = @params.reject{ |k| k == :course_id }.merge(account_id: @account.id)
      end

      it "should return list" do
        json = api_call(:get, @migration_url, @params)
        json.length.should == 1
        json.first['id'].should == @migration.id
      end
    end
  end

  describe 'show' do
    before do
      @migration_url = @migration_url + "/#{@migration.id}"
      @params = @params.merge( :action => 'show', :id => @migration.id.to_param )
    end

    it "should return migration" do
      @migration.attachment = Attachment.create!(:context => @migration, :filename => "test.txt", :uploaded_data => StringIO.new("test file"))
      @migration.save!
      progress = Progress.create!(:tag => "content_migration", :context => @migration)
      json = api_call(:get, @migration_url, @params)

      json['id'].should == @migration.id
      json['migration_type'].should == @migration.migration_type
      json['finished_at'].should_not be_nil
      json['started_at'].should_not be_nil
      json['user_id'].should == @user.id
      json["workflow_state"].should == "pre_processing"
      json["migration_issues_url"].should == "http://www.example.com/api/v1/courses/#{@course.id}/content_migrations/#{@migration.id}/migration_issues"
      json["migration_issues_count"].should == 0
      json["attachment"]["url"].should =~ %r{/files/#{@migration.attachment.id}/download}
      json['progress_url'].should == "http://www.example.com/api/v1/progress/#{progress.id}"
      json['migration_type_title'].should == 'Common Cartridge'
    end

    it "should return waiting_for_select when it's supposed to" do
      @migration.workflow_state = 'exported'
      @migration.migration_settings[:import_immediately] = false
      @migration.save!
      json = api_call(:get, @migration_url, @params)
      json['workflow_state'].should == 'waiting_for_select'
    end

    it "should 404" do
      api_call(:get, @migration_url + "000", @params.merge({:id => @migration.id.to_param + "000"}), {}, {}, :expected_status => 404)
    end

    it "should 401" do
      course_with_student_logged_in(:course => @course, :active_all => true)
      api_call(:get, @migration_url, @params, {}, {}, :expected_status => 401)
    end

    it "should not return attachment for course copies" do
      @migration.migration_type = 'course_copy_importer'
      @migration.source_course_id = @course.id
      @migration.source_course = @course
      @attachment = Attachment.create!(:context => @migration, :filename => "test.zip", :uploaded_data => StringIO.new("test file"))
      @attachment.file_state = "deleted"
      @attachment.workflow_state = "unattached"
      @attachment.save
      @migration.attachment = @attachment
      @migration.save!

      json = api_call(:get, @migration_url, @params)
      json["attachment"].should be_nil
    end

    it "should return source course info for course copy" do
      @migration.migration_type = 'course_copy_importer'
      @migration.source_course_id = @course.id
      @migration.source_course = @course
      @migration.save!

      json = api_call(:get, @migration_url, @params)
      json['settings']['source_course_id'].should == @course.id
      json['settings']['source_course_name'].should == @course.name
    end

    it "should mark as failed if stuck in pre_processing" do
      @migration.workflow_state = 'pre_processing'
      @migration.save!
      ContentMigration.where(:id => @migration.id).update_all(:updated_at => Time.now.utc - 2.hours)

      json = api_call(:get, @migration_url, @params)
      json['workflow_state'].should == 'failed'
      json['migration_issues_count'].should == 1
      @migration.reload
      @migration.should be_failed
      @migration.migration_issues.first.description.should == "The file upload process timed out."
    end

    context "User" do
      before do
        @migration = @user.content_migrations.create
        @migration.migration_type = 'zip_file_import'
        @migration.user = @user
        @migration.save!
        @migration_url = "/api/v1/users/#{@user.id}/content_migrations/#{@migration.id}"
        @params = @params.reject{ |k| k == :course_id }.merge(user_id: @user.id, id: @migration.to_param)
      end

      it "should return migration" do
        json = api_call(:get, @migration_url, @params)
        json['id'].should == @migration.id
      end
    end

    context "Group" do
      before do
        group_with_user user: @user
        @migration = @group.content_migrations.create
        @migration.migration_type = 'zip_file_import'
        @migration.user = @user
        @migration.save!
        @migration_url = "/api/v1/groups/#{@group.id}/content_migrations/#{@migration.id}"
        @params = @params.reject{ |k| k == :course_id }.merge(group_id: @group.id, id: @migration.to_param)
      end

      it "should return migration" do
        json = api_call(:get, @migration_url, @params)
        json['id'].should == @migration.id
      end
    end

    context "Account" do
      before do
        @account = Account.create!(:name => 'name')
        @account.add_user(@user)
        @migration = @account.content_migrations.create
        @migration.migration_type = 'qti_converter'
        @migration.user = @user
        @migration.save!
        @migration_url = "/api/v1/accounts/#{@account.id}/content_migrations/#{@migration.id}"
        @params = @params.reject{ |k| k == :course_id }.merge(account_id: @account.id, id: @migration.to_param)
      end

      it "should return migration" do
        json = api_call(:get, @migration_url, @params)
        json['id'].should == @migration.id
      end
    end
  end

  describe 'create' do
    before do
      @params = {:controller => 'content_migrations', :format => 'json', :course_id => @course.id.to_param, :action => 'create'}
      @post_params = {:migration_type => 'common_cartridge_importer', :pre_attachment => {:name => "test.zip"}}
    end

    it "should error for unknown type" do
      json = api_call(:post, @migration_url, @params, {:migration_type => 'jerk'}, {}, :expected_status => 400)
      json.should == {"message"=>"Invalid migration_type"}
    end

    it "should queue a migration" do
      @post_params.delete :pre_attachment
      p = Canvas::Plugin.new("hi")
      p.stubs(:settings).returns({'worker' => 'CCWorker', 'valid_contexts' => ['Course']}.with_indifferent_access)
      Canvas::Plugin.stubs(:find).returns(p)
      json = api_call(:post, @migration_url, @params, @post_params)
      json["workflow_state"].should == 'running'
      migration = ContentMigration.find json['id']
      migration.workflow_state.should == "exporting"
      migration.job_progress.workflow_state.should == 'queued'
    end

    it "should not queue a migration if do_not_run flag is set" do
      @post_params.delete :pre_attachment
      p = Canvas::Plugin.new("hi")
      p.stubs(:settings).returns({'worker' => 'CCWorker', 'valid_contexts' => ['Course']}.with_indifferent_access)
      Canvas::Plugin.stubs(:find).returns(p)
      json = api_call(:post, @migration_url, @params, @post_params.merge(:do_not_run => true))
      json["workflow_state"].should == 'pre_processing'
      migration = ContentMigration.find json['id']
      migration.workflow_state.should == "created"
      migration.job_progress.should be_nil
    end

    it "should error if expected setting isn't set" do
      json = api_call(:post, @migration_url, @params, {:migration_type => 'course_copy_importer'}, {}, :expected_status => 400)
      json.should == {"message"=>'A course copy requires a source course.'}
    end

    it "should queue if correct settings set" do
      # implicitly tests that the response was a 200
      api_call(:post, @migration_url, @params, {:migration_type => 'course_copy_importer', :settings => {:source_course_id => @course.id.to_param}})
    end

    it "should not queue for course copy and selective_import" do
      json = api_call(:post, @migration_url, @params, {:migration_type => 'course_copy_importer', :selective_import => '1', :settings => {:source_course_id => @course.id.to_param}})
      json["workflow_state"].should == 'waiting_for_select'
      migration = ContentMigration.find json['id']
      migration.workflow_state.should == "exported"
      migration.job_progress.should be_nil
    end

    it "should translate a sis source_course_id" do
      other_course = course active_all: true
      other_course.sis_source_id = "booga"
      other_course.save!
      json = api_call(:post, @migration_url + "?settings[source_course_id]=sis_course_id:booga&migration_type=course_copy_importer",
                      @params.merge(:migration_type => 'course_copy_importer', :settings => {'source_course_id' => 'sis_course_id:booga'}))
      migration = ContentMigration.find json['id']
      migration.migration_settings[:source_course_id].should eql other_course.id
    end

    context "migration file upload" do
      it "should set attachment pre-flight data" do
        json = api_call(:post, @migration_url, @params, @post_params)
        json['pre_attachment'].should_not be_nil
        json['pre_attachment']["upload_params"]["key"].end_with?("test.zip").should == true
      end

      it "should not queue migration with pre_attachent on create" do
        json = api_call(:post, @migration_url, @params, @post_params)
        json["workflow_state"].should == 'pre_processing'
        migration = ContentMigration.find json['id']
        migration.workflow_state.should == "pre_processing"
      end

      it "should error if upload file required but not provided" do
        @post_params.delete :pre_attachment
        json = api_call(:post, @migration_url, @params, @post_params, {}, :expected_status => 400)
        json.should == {"message"=>"File upload or url is required"}
      end

      it "should queue the migration when file finishes uploading" do
        local_storage!
        @attachment = Attachment.create!(:context => @migration, :filename => "test.zip", :uploaded_data => StringIO.new("test file"))
        @attachment.file_state = "deleted"
        @attachment.workflow_state = "unattached"
        @attachment.save
        @migration.attachment = @attachment
        @migration.save!
        @attachment.workflow_state = nil
        @content = Tempfile.new(["test", ".zip"])
        def @content.content_type
          "application/zip"
        end
        @content.write("test file")
        @content.rewind
        @attachment.uploaded_data = @content
        @attachment.save!
        api_call(:post, "/api/v1/files/#{@attachment.id}/create_success?uuid=#{@attachment.uuid}",
                        {:controller => "files", :action => "api_create_success", :format => "json", :id => @attachment.to_param, :uuid => @attachment.uuid})

        @migration.reload
        @migration.attachment.should_not be_nil
        @migration.workflow_state.should == "exporting"
        @migration.job_progress.workflow_state.should == 'queued'
      end

      it "should error if course quota exceeded" do
        @post_params.merge!(:pre_attachment => {:name => "test.zip", :size => 1.gigabyte})
        json = api_call(:post, @migration_url, @params, @post_params)
        json['pre_attachment'].should == {"message"=>"file size exceeds quota", "error" => true}
        json["workflow_state"].should == 'failed'
        migration = ContentMigration.find json['id']
        migration.workflow_state = 'pre_process_error'
      end
    end

    context "by url" do
      it "should queue migration with url sent" do
        post_params = {migration_type: 'common_cartridge_importer', settings:{file_url: 'http://example.com/oi.imscc'}}
        json = api_call(:post, @migration_url, @params, post_params)
        migration = ContentMigration.find json['id']
        migration.attachment.should be_nil
        migration.migration_settings[:file_url].should == post_params[:settings][:file_url]
      end

    end

    context "by LTI extension" do
      it "should queue migration with LTI url sent" do
        post_params = {migration_type: "context_external_tool", settings: {file_url: 'http://example.com/oi.imscc'}}
        json = api_call(:post, @migration_url, @params, post_params)
        migration = ContentMigration.find json['id']
        migration.attachment.should be_nil
        migration.migration_settings[:file_url].should == post_params[:settings][:file_url]
        migration.workflow_state.should == "exporting"
        migration.job_progress.workflow_state.should == 'queued'
      end

      it "should require a file upload" do
        post_params = {migration_type: "context_external_tool", settings: {course_course_id: 42}}
        api_call(:post, @migration_url, @params, post_params, {}, :expected_status => 400)
      end
    end

    context "User" do
      before do
        @migration_url = "/api/v1/users/#{@user.id}/content_migrations"
        @params = @params.reject{|k| k == :course_id}.merge(:user_id => @user.to_param)
        @folder = Folder.root_folders(@user).first
      end

      it "should error for an unsupported type" do
        json = api_call(:post, @migration_url, @params, {:migration_type => 'common_cartridge_importer'},
                        {}, :expected_status => 400)
        json.should == {"message"=>"Unsupported migration_type for context"}
      end

      it "should queue a migration" do
        json = api_call(:post, @migration_url, @params,
          { :migration_type => 'zip_file_importer',
            :settings => { :file_url => 'http://example.com/oi.zip',
                           :folder_id => @folder.id }})
        migration = ContentMigration.find json['id']
        migration.context.should eql @user
      end
    end

    context "Group" do
      before do
        group_with_user user: @user
        @migration_url = "/api/v1/groups/#{@group.id}/content_migrations"
        @params = @params.reject{|k| k == :course_id}.merge(:group_id => @group.to_param)
        @folder = Folder.root_folders(@group).first
      end

      it "should queue a migration" do
        json = api_call(:post, @migration_url, @params,
                        { :migration_type => 'zip_file_importer',
                          :settings => { :file_url => 'http://example.com/oi.zip',
                                         :folder_id => @folder.id }})
        migration = ContentMigration.find json['id']
        migration.context.should eql @group
      end
    end

    context "Account" do
      before do
        @account = Account.create!(:name => 'migration account')
        @account.add_user(@user)
        @migration_url = "/api/v1/accounts/#{@account.id}/content_migrations"
        @params = @params.reject{|k| k == :course_id}.merge(:account_id => @account.to_param)
      end

      it "should queue a migration" do
        json = api_call(:post, @migration_url, @params,
                        { :migration_type => 'qti_converter',
                          :settings => { :file_url => 'http://example.com/oi.zip' }})
        migration = ContentMigration.find json['id']
        migration.context.should eql @account
      end
    end
  end

  describe 'update' do
    before do
      @migration_url = "/api/v1/courses/#{@course.id}/content_migrations/#{@migration.id}"
      @params = {:controller => 'content_migrations', :format => 'json', :course_id => @course.id.to_param, :action => 'update', :id => @migration.id.to_param}
      @post_params = {}
    end

    it "should queue a migration" do
      json = api_call(:put, @migration_url, @params, @post_params)
      json["workflow_state"].should == 'running'
      @migration.reload
      @migration.workflow_state.should == "exporting"
      @migration.job_progress.workflow_state.should == 'queued'
    end

    it "should not queue a migration if do_not_run flag is set" do
      json = api_call(:put, @migration_url, @params, @post_params.merge(:do_not_run => true))
      json["workflow_state"].should == 'pre_processing'
      migration = ContentMigration.find json['id']
      migration.workflow_state.should == "created"
      migration.job_progress.should be_nil
    end

    it "should not change migration_type" do
      json = api_call(:put, @migration_url, @params, @post_params.merge(:migration_type => "oioioi"))
      json['migration_type'].should == 'common_cartridge_importer'
    end

    it "should reset progress after queue" do
      p = @migration.reset_job_progress
      p.completion = 100
      p.workflow_state = 'completed'
      p.save!
      api_call(:put, @migration_url, @params, @post_params)
      p.reload
      p.completion.should == 0
      p.workflow_state.should == 'queued'
    end

    context "selective content" do
      before do
        @migration.workflow_state = 'exported'
        @migration.migration_settings[:import_immediately] = false
        @migration.save!
        @post_params = {:copy => {:all_assignments => true, :context_modules => {'id_9000' => true}}}
      end

      it "should set the selective data" do
        json = api_call(:put, @migration_url, @params, @post_params)
        @migration.reload
        copy_options = {'all_assignments' => 'true', 'context_modules' => {'9000' => 'true'}}
        @migration.migration_settings[:migration_ids_to_import].should == {'copy' => copy_options}
        @migration.copy_options.should == copy_options
      end

      it "should queue a course copy after selecting content" do
        @migration.migration_type = 'course_copy_importer'
        @migration.migration_settings[:source_course_id] = @course.id
        @migration.save!
        json = api_call(:put, @migration_url, @params, @post_params)
        json['workflow_state'].should == 'running'
        @migration.reload
        @migration.workflow_state.should == 'exporting'
      end

      it "should queue a file migration after selecting content" do
        json = api_call(:put, @migration_url, @params, @post_params)
        json['workflow_state'].should == 'running'
        @migration.reload
        @migration.workflow_state.should == 'importing'
      end

    end

  end

  describe 'migration_systems' do
    it "should return the migrators" do
      p = Canvas::Plugin.find('common_cartridge_importer')
      Canvas::Plugin.stubs(:all_for_tag).returns([p])
      json = api_call(:get, "/api/v1/courses/#{@course.id}/content_migrations/migrators",
                      {:controller=>"content_migrations", :action=>"available_migrators", :format=>"json", :course_id=>@course.id.to_param})
      json.should == [{
                              "type" => "common_cartridge_importer",
                              "requires_file_upload" => true,
                              "name" => "Common Cartridge 1.0/1.1/1.2 Package",
                              "required_settings" => []
                      }]
    end

    it "should filter by context type" do
      Canvas::Plugin.stubs(:all_for_tag).returns([Canvas::Plugin.find('common_cartridge_importer'),
                                                  Canvas::Plugin.find('zip_file_importer')])
      json = api_call(:get, "/api/v1/users/#{@user.id}/content_migrations/migrators",
                      {:controller=>"content_migrations", :action=>"available_migrators", :format=>"json", :user_id=>@user.to_param})
      json.should == [{
                          "type" => "zip_file_importer",
                          "requires_file_upload" => true,
                          "name" => "Unzip .zip file into folder",
                          "required_settings" => ['source_folder_id']
                      }]
    end
  end

  describe 'content selection' do
    before do
      @migration_url = "/api/v1/courses/#{@course.id}/content_migrations/#{@migration.id}/selective_data"
      @params = {:controller => 'content_migrations', :format => 'json', :course_id => @course.id.to_param, :action => 'content_list', :id => @migration.id.to_param}
      @orig_course = @course

      course
      @dt1 = @course.discussion_topics.create!(:message => "hi", :title => "discussion title")
      @cm = @course.context_modules.create!(:name => "some module")
      @att = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@course), :context => @course)
      @wiki = @course.wiki.wiki_pages.create!(:title => "wiki", :body => "ohai")
      @migration.migration_type = 'course_copy_importer'
      @migration.migration_settings[:source_course_id] = @course.id
      @migration.save!
    end

    it "should return the top-level list" do
      json = api_call(:get, @migration_url, @params)
      json.should == [{"type"=>"course_settings", "property"=>"copy[all_course_settings]", "title"=>"Course Settings"},
                      {"type"=>"syllabus_body", "property"=>"copy[all_syllabus_body]", "title"=>"Syllabus Body"},
                      {"type"=>"context_modules", "property"=>"copy[all_context_modules]", "title"=>"Modules", "count"=>1, "sub_items_url"=>"http://www.example.com/api/v1/courses/#{@orig_course.id}/content_migrations/#{@migration.id}/selective_data?type=context_modules"},
                      {"type"=>"discussion_topics", "property"=>"copy[all_discussion_topics]", "title"=>"Discussion Topics", "count"=>1, "sub_items_url"=>"http://www.example.com/api/v1/courses/#{@orig_course.id}/content_migrations/#{@migration.id}/selective_data?type=discussion_topics"},
                      {"type"=>"wiki_pages", "property"=>"copy[all_wiki_pages]", "title"=>"Wiki Pages", "count"=>1, "sub_items_url"=>"http://www.example.com/api/v1/courses/#{@orig_course.id}/content_migrations/#{@migration.id}/selective_data?type=wiki_pages"},
                      {"type"=>"attachments", "property"=>"copy[all_attachments]", "title"=>"Files", "count"=>1, "sub_items_url"=>"http://www.example.com/api/v1/courses/#{@orig_course.id}/content_migrations/#{@migration.id}/selective_data?type=attachments"}]
    end

    it "should return individual types" do
      json = api_call(:get, @migration_url + '?type=context_modules', @params.merge({type: 'context_modules'}))
      json.length.should == 1
      json.first["type"].should == 'context_modules'
      json.first["title"].should == @cm.name
    end
  end


end

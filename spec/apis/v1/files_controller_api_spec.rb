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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../locked_spec')

RSpec.configure do |config|
  config.include ApplicationHelper
end

describe "Files API", type: :request do
  context 'locked api item' do
    let(:item_type) { 'file' }

    let(:locked_item) do
      root_folder = Folder.root_folders(@course).first
      Attachment.create!(:filename => 'test.png', :display_name => 'test-frd.png', :uploaded_data => stub_png_data, :folder => root_folder, :context => @course)
    end

    def api_get_json
      api_call(
        :get,
        "/api/v1/files/#{locked_item.id}",
        {:controller=>'files', :action=>'api_show', :format=>'json', :id => locked_item.id.to_s},
      )
    end

    include_examples 'a locked api item'
  end

  before :once do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym)
  end

  describe "api_create_success" do
    before :once do
      @attachment = Attachment.new
      @attachment.context = @course
      @attachment.filename = "test.txt"
      @attachment.file_state = 'deleted'
      @attachment.workflow_state = 'unattached'
      @attachment.content_type = "text/plain"
      @attachment.save!
    end

    def upload_data
      @attachment.workflow_state = nil
      @content = Tempfile.new(["test", ".txt"])
      def @content.content_type
        "text/plain"
      end
      @content.write("test file")
      @content.rewind
      @attachment.uploaded_data = @content
      @attachment.save!
    end

    def call_create_success
      api_call(:post, "/api/v1/files/#{@attachment.id}/create_success?uuid=#{@attachment.uuid}",
               {:controller => "files", :action => "api_create_success", :format => "json", :id => @attachment.to_param, :uuid => @attachment.uuid})
    end

    it "should set the attachment to available (local storage)" do
      local_storage!
      upload_data
      json = call_create_success
      @attachment.reload
      expect(json).to eq({
        'id' => @attachment.id,
        'folder_id' => @attachment.folder_id,
        'url' => file_download_url(@attachment, :verifier => @attachment.uuid, :download => '1', :download_frd => '1'),
        'content-type' => 'text/plain',
        'display_name' => 'test.txt',
        'filename' => @attachment.filename,
        'size' => @attachment.size,
        'unlock_at' => nil,
        'locked' => false,
        'hidden' => false,
        'lock_at' => nil,
        'locked_for_user' => false,
        'preview_url' => context_url(@attachment.context, :context_file_file_preview_url, @attachment, annotate: 0),
        'hidden_for_user' => false,
        'created_at' => @attachment.created_at.as_json,
        'updated_at' => @attachment.updated_at.as_json,
        'thumbnail_url' => nil,
        'modified_at' => @attachment.modified_at.as_json,
        'mime_class' => @attachment.mime_class,
        'media_entry_id' => @attachment.media_entry_id
      })
      expect(@attachment.file_state).to eq 'available'
    end

    it "should set the attachment to available (s3 storage)" do
      s3_storage!

      AWS::S3::S3Object.any_instance.expects(:head).returns({
                                          :content_type => 'text/plain',
                                          :content_length => 1234,
                                      })

      json = call_create_success
      @attachment.reload
      expect(json).to eq({
        'id' => @attachment.id,
        'folder_id' => @attachment.folder_id,
        'url' => file_download_url(@attachment, :verifier => @attachment.uuid, :download => '1', :download_frd => '1'),
        'content-type' => 'text/plain',
        'display_name' => 'test.txt',
        'filename' => @attachment.filename,
        'size' => @attachment.size,
        'unlock_at' => nil,
        'locked' => false,
        'hidden' => false,
        'lock_at' => nil,
        'locked_for_user' => false,
        'preview_url' => context_url(@attachment.context, :context_file_file_preview_url, @attachment, annotate: 0),
        'hidden_for_user' => false,
        'created_at' => @attachment.created_at.as_json,
        'updated_at' => @attachment.updated_at.as_json,
        'thumbnail_url' => nil,
        'modified_at' => @attachment.modified_at.as_json,
        'mime_class' => @attachment.mime_class,
        'media_entry_id' => @attachment.media_entry_id
      })
      expect(@attachment.reload.file_state).to eq 'available'
    end

    it "includes usage rights if overwriting a file that has them already" do
      usage_rights = @course.usage_rights.create! use_justification: 'creative_commons', legal_copyright: '(C) 2014 XYZ Corp', license: 'cc_by_nd'
      @attachment.usage_rights = usage_rights
      @attachment.save!
      upload_data
      json = call_create_success
      expect(json['usage_rights']).to eq({"use_justification"=>"creative_commons",
                                          "license"=>"cc_by_nd",
                                          "legal_copyright"=>"(C) 2014 XYZ Corp",
                                          "license_name"=>"CC Attribution No Derivatives"})
    end

    it "should store long-ish non-ASCII filenames (local storage)" do
      local_storage!
      @attachment.update_attribute(:filename, "Качество образования-1.txt")
      upload_data
      expect { call_create_success }.not_to raise_error
      expect(@attachment.reload.open.read).to eq "test file"
    end

    it "should render the response as text/html when in app" do
      s3_storage!
      FilesController.any_instance.stubs(:in_app?).returns(true)
      FilesController.any_instance.stubs(:verified_request?).returns(true)

      AWS::S3::S3Object.any_instance.expects(:head).returns({
                                          :content_type => 'text/plain',
                                          :content_length => 1234,
                                      })

      raw_api_call(:post, "/api/v1/files/#{@attachment.id}/create_success?uuid=#{@attachment.uuid}",
               {:controller => "files", :action => "api_create_success", :format => "json", :id => @attachment.to_param, :uuid => @attachment.uuid})
      expect(response.headers[content_type_key]).to eq "text/html; charset=utf-8"
      expect(response.body).not_to include 'verifier='
    end

    it "should fail for an incorrect uuid" do
      upload_data
      raw_api_call(:post, "/api/v1/files/#{@attachment.id}/create_success?uuid=abcde",
                   { :controller => "files", :action => "api_create_success", :format => "json", :id => @attachment.to_param, :uuid => "abcde" })
      assert_status(400)
    end

    it "should fail if the attachment is already available" do
      upload_data
      @attachment.update_attribute(:file_state, 'available')
      raw_api_call(:post, "/api/v1/files/#{@attachment.id}/create_success?uuid=#{@attachment.uuid}",
                   { :controller => "files", :action => "api_create_success", :format => "json", :id => @attachment.to_param, :uuid => @attachment.uuid })
      assert_status(400)
    end

    context "upload success context callback" do
      before do
        Course.any_instance.stubs(:file_upload_success_callback)
        Course.any_instance.expects(:file_upload_success_callback).with(@attachment)
      end

      it "should call back for s3" do
        s3_storage!
         AWS::S3::S3Object.any_instance.expects(:head).returns({
                                          :content_type => 'text/plain',
                                          :content_length => 1234,
                                      })
        json = call_create_success
      end

      it "should call back for local storage" do
        local_storage!
        upload_data
        json = call_create_success
      end
    end

  end

  describe "#index" do
    before :once do
      @root = Folder.root_folders(@course).first
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
      @a1 = Attachment.create!(:filename => 'ztest.txt', :display_name => "ztest.txt", :position => 1, :uploaded_data => StringIO.new('file'), :folder => @f1, :context => @course)
      @a3 = Attachment.create(:filename => 'atest3.txt', :display_name => "atest3.txt", :position => 2, :uploaded_data => StringIO.new('file'), :folder => @f1, :context => @course)
      @a3.hidden = true
      @a3.save!
      @a2 = Attachment.create!(:filename => 'mtest2.txt', :display_name => "mtest2.txt", :position => 3, :uploaded_data => StringIO.new('file'), :folder => @f1, :context => @course, :locked => true)

      @files_path = "/api/v1/folders/#{@f1.id}/files"
      @files_path_options = { :controller => "files", :action => "api_index", :format => "json", :id => @f1.id.to_param }
    end

    it "should list files in alphabetical order" do
      json = api_call(:get, @files_path, @files_path_options, {})
      res = json.map{|f|f['display_name']}
      expect(res).to eq %w{atest3.txt mtest2.txt ztest.txt}
      json.map{|f|f['url']}.each { |url| expect(url).to include 'verifier=' }
    end

    it "should omit verifiers using session auth" do
      user_session(@user)
      get @files_path
      expect(response).to be_success
      json = json_parse
      json.map{|f|f['url']}.each { |url| expect(url).not_to include 'verifier=' }
    end

    it "should not omit verifiers using session auth if params[:use_verifiers] is given" do
      user_session(@user)
      get @files_path + "?use_verifiers=1"
      expect(response).to be_success
      json = json_parse
      json.map{|f|f['url']}.each { |url| expect(url).to include 'verifier=' }
    end

    it "should list files in saved order if flag set" do
      json = api_call(:get, @files_path + "?sort_by=position", @files_path_options.merge(:sort_by => 'position'), {})
      res = json.map{|f|f['display_name']}
      expect(res).to eq %w{ztest.txt atest3.txt mtest2.txt}
    end

    it "should not list locked file if not authed" do
      course_with_student_logged_in(:course => @course)
      json = api_call(:get, @files_path, @files_path_options, {})
      expect(json.any?{|f|f['id'] == @a2.id}).to be_falsey
    end

    it "should not list hidden files if not authed" do
      course_with_student_logged_in(:course => @course)
      json = api_call(:get, @files_path, @files_path_options, {})

      expect(json.any?{|f| f['id'] == @a3.id}).to be_falsey
    end

    it "should list hidden files with :read_as_admin rights" do
      course_with_ta(:course => @course, :active_all => true)
      user_session(@user)
      @course.account.role_overrides.create!(:permission => :manage_files, :enabled => false, :role => ta_role)
      json = api_call(:get, @files_path, @files_path_options, {})

      expect(json.any?{|f| f['id'] == @a3.id}).to be_truthy
    end

    it "should not list locked folder if not authed" do
      @f1.locked = true
      @f1.save!
      course_with_student_logged_in(:course => @course)
      raw_api_call(:get, @files_path, @files_path_options, {}, {}, :expected_status => 401)
    end

    it "should 404 for no folder found" do
      raw_api_call(:get, "/api/v1/folders/0/files", @files_path_options.merge(:id => "0"), {}, {}, :expected_status => 404)
    end

    it "should paginate" do
      7.times {|i| Attachment.create!(:filename => "test#{i}.txt", :display_name => "test#{i}.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course) }
      json = api_call(:get, "/api/v1/folders/#{@root.id}/files?per_page=3", @files_path_options.merge(:id => @root.id.to_param, :per_page => '3'), {})
      expect(json.length).to eq 3
      links = response.headers['Link'].split(",")
      expect(links.all?{ |l| l =~ /api\/v1\/folders\/#{@root.id}\/files/ }).to be_truthy
      expect(links.find{ |l| l.match(/rel="next"/)}).to match /page=2/
      expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1/
      expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3/

      json = api_call(:get, "/api/v1/folders/#{@root.id}/files?per_page=3&page=3", @files_path_options.merge(:id => @root.id.to_param, :per_page => '3', :page => '3'), {})
      expect(json.length).to eq 1
      links = response.headers['Link'].split(",")
      expect(links.all?{ |l| l =~ /api\/v1\/folders\/#{@root.id}\/files/ }).to be_truthy
      expect(links.find{ |l| l.match(/rel="prev"/)}).to match /page=2/
      expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1/
      expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3/
    end

    it "should only return names if requested" do
      json = api_call(:get, @files_path, @files_path_options, {:only => ['names']})
      res = json.map{|f|f['display_name']}
      expect(res).to eq %w{atest3.txt mtest2.txt ztest.txt}
      expect(json.any?{|f| f['url']}).to be_falsey
    end

    context "content_types" do
      before :once do
        txt = attachment_model :display_name => 'thing.txt', :content_type => 'text/plain', :context => @course, :folder => @f1
        png = attachment_model :display_name => 'thing.png', :content_type => 'image/png', :context => @course, :folder => @f1
        gif = attachment_model :display_name => 'thing.gif', :content_type => 'image/gif', :context => @course, :folder => @f1
      end

      it "should match one content-type" do
        json = api_call(:get, @files_path + "?content_types=image", @files_path_options.merge(:content_types => 'image'), {})
        res = json.map{|f|f['display_name']}
        expect(res).to eq %w(thing.gif thing.png)
      end

      it "should match multiple content-types" do
        json = api_call(:get, @files_path + "?content_types[]=text&content_types[]=image/gif",
                        @files_path_options.merge(:content_types => ['text', 'image/gif']))
        res = json.map{|f|f['display_name']}
        expect(res).to eq %w(thing.gif thing.txt)
      end
    end

    it "should search for files by title" do
      atts = []
      2.times {|i| atts << Attachment.create!(:filename => "first#{i}.txt", :display_name => "first#{i}.txt", :uploaded_data => StringIO.new('file'), :folder => @f1, :context => @course) }
      2.times {|i| Attachment.create!(:filename => "second#{i}.txt", :display_name => "second#{i}.txt", :uploaded_data => StringIO.new('file'), :folder => @f1, :context => @course) }

      json = api_call(:get, @files_path + "?search_term=fir", @files_path_options.merge(:search_term => 'fir'), {})
      expect(json.map{|h| h['id']}.sort).to eq atts.map(&:id).sort
    end

    it "should include user if requested" do
      @a1.update_attribute(:user, @user)
      json = api_call(:get, @files_path + "?include[]=user", @files_path_options.merge(include: ['user']))
      expect(json.map{|f|f['user']}).to eql [
        {},
        {},
        {
          "id" => @user.id,
          "display_name" => @user.short_name,
          "avatar_image_url" => User.avatar_fallback_url(nil, request),
          "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@user.id}"
        }
      ]
    end

    it "should include usage_rights if requested" do
      @a1.usage_rights = @course.usage_rights.create! legal_copyright: '(C) 2014 Initech', use_justification: 'used_by_permission'
      @a1.save!
      json = api_call(:get, @files_path + "?include[]=usage_rights", @files_path_options.merge(include: ['usage_rights']))
      expect(json.map{|f|f['usage_rights']}).to eql [
          nil,
          nil,
          {
              "legal_copyright" => '(C) 2014 Initech',
              "use_justification" => 'used_by_permission',
              "license" => "private",
              "license_name" => "Private (Copyrighted)"
          }
      ]
    end

    it "should include user even for user files" do
      my_root_folder = Folder.root_folders(@user).first
      my_file = Attachment.create! :filename => 'ztest.txt',
                                   :display_name => "ztest.txt",
                                   :position => 1,
                                   :uploaded_data => StringIO.new('file'),
                                   :folder => my_root_folder,
                                   :context => @user,
                                   :user => @user

      json = api_call(:get, "/api/v1/folders/#{my_root_folder.id}/files?include[]=user", {
        :controller => "files",
        :action => "api_index",
        :format => "json",
        :id => my_root_folder.id.to_param,
        :include => ['user']
      })
      expect(json.map{|f|f['user']}).to eql [
        {
          "id" => @user.id,
          "display_name" => @user.short_name,
          "avatar_image_url" => User.avatar_fallback_url(nil, request),
          "html_url" => "http://www.example.com/about/#{@user.id}"
        }
      ]
    end

  end

  describe "#index for courses" do
    before :once do
      @root = Folder.root_folders(@course).first
      @f1 = @root.sub_folders.create!(:name => "folder1", :context => @course)
      @a1 = Attachment.create!(:filename => 'ztest.txt', :display_name => "ztest.txt", :position => 1, :uploaded_data => StringIO.new('file'), :folder => @f1, :context => @course)
      @a3 = Attachment.create(:filename => 'atest3.txt', :display_name => "atest3.txt", :position => 2, :uploaded_data => StringIO.new('file_'), :folder => @f1, :context => @course)
      @a3.hidden = true
      @a3.save!
      @a2 = Attachment.create!(:filename => 'mtest2.txt', :display_name => "mtest2.txt", :position => 3, :uploaded_data => StringIO.new('file__'), :folder => @f1, :context => @course, :locked => true)

      @files_path = "/api/v1/courses/#{@course.id}/files"
      @files_path_options = { :controller => "files", :action => "api_index", :format => "json", :course_id => @course.id.to_param }
    end

    describe "sort" do
      it "should list files in alphabetical order" do
        json = api_call(:get, @files_path, @files_path_options, {})
        res = json.map{|f|f['display_name']}
        expect(res).to eq %w{atest3.txt mtest2.txt ztest.txt}
      end

      it "should list files in saved order if flag set" do
        json = api_call(:get, @files_path + "?sort_by=position", @files_path_options.merge(:sort_by => 'position'), {})
        res = json.map{|f|f['display_name']}
        expect(res).to eq %w{ztest.txt atest3.txt mtest2.txt}
      end

      it "should sort by size" do
        json = api_call(:get, @files_path + "?sort=size", @files_path_options.merge(sort: 'size'))
        res = json.map{|f|[f['display_name'], f['size']]}
        expect(res).to eq [['ztest.txt', 4], ['atest3.txt', 5], ['mtest2.txt', 6]]
      end

      it "should sort by last-modified time" do
        Timecop.freeze(2.hours.ago) { @a2.touch }
        Timecop.freeze(1.hour.ago) { @a1.touch }
        json = api_call(:get, @files_path + "?sort=updated_at", @files_path_options.merge(sort: 'updated_at'))
        res = json.map{|f|f['display_name']}
        expect(res).to eq %w{mtest2.txt ztest.txt atest3.txt}
      end

      it "should sort by content_type" do
        @a1.update_attribute(:content_type, "application/octet-stream")
        @a2.update_attribute(:content_type, "video/quicktime")
        @a3.update_attribute(:content_type, "text/plain")
        json = api_call(:get, @files_path + "?sort=content_type", @files_path_options.merge(sort: 'content_type'))
        res = json.map{|f|[f['display_name'], f['content-type']]}
        expect(res).to eq [['ztest.txt', 'application/octet-stream'], ['atest3.txt', 'text/plain'], ['mtest2.txt', 'video/quicktime']]
      end

      it "should sort by user, nulls last" do
        @caller = @user
        @s1 = student_in_course(active_all: true, name: 'alice').user
        @a1.update_attribute :user, @s1
        @s2 = student_in_course(active_all: true, name: 'bob').user
        @a3.update_attribute :user, @s2
        @user = @caller
        json = api_call(:get, @files_path + "?sort=user", @files_path_options.merge(sort: 'user'))
        res = json.map do |file|
          [file['display_name'], file['user']['display_name']]
        end
        expect(res).to eq [['ztest.txt', 'alice'], ['atest3.txt', 'bob'], ['mtest2.txt', nil]]
      end

      it "should sort in descending order" do
        json = api_call(:get, @files_path + "?sort=size&order=desc", @files_path_options.merge(sort: 'size', order: 'desc'))
        res = json.map{|f|[f['display_name'], f['size']]}
        expect(res).to eq [['mtest2.txt', 6], ['atest3.txt', 5], ['ztest.txt', 4]]
      end
    end

    it "should not list locked file if not authed" do
      course_with_student_logged_in(:course => @course)
      json = api_call(:get, @files_path, @files_path_options, {})
      expect(json.any?{|f|f[:id] == @a2.id}).to eq false
    end

    it "should not list hidden files if not authed" do
      course_with_student_logged_in(:course => @course)
      json = api_call(:get, @files_path, @files_path_options, {})

      expect(json.any?{|f|f[:id] == @a3.id}).to eq false
    end

    it "should not list locked folder if not authed" do
      @f1.locked = true
      @f1.save!
      course_with_student_logged_in(:course => @course)
      json = api_call(:get, @files_path, @files_path_options, {})

      expect(json).to eq []
    end

    it "should paginate" do
      4.times {|i| Attachment.create!(:filename => "test#{i}.txt", :display_name => "test#{i}.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course) }
      json = api_call(:get, "/api/v1/courses/#{@course.id}/files?per_page=3", @files_path_options.merge(:per_page => '3'), {})
      expect(json.length).to eq 3
      links = response.headers['Link'].split(",")
      expect(links.all?{ |l| l =~ /api\/v1\/courses\/#{@course.id}\/files/ }).to be_truthy
      expect(links.find{ |l| l.match(/rel="next"/)}).to match /page=2/
      expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1/
      expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3/

      json = api_call(:get, "/api/v1/courses/#{@course.id}/files?per_page=3&page=3", @files_path_options.merge(:per_page => '3', :page => '3'), {})
      expect(json.length).to eq 1
      links = response.headers['Link'].split(",")
      expect(links.all?{ |l| l =~ /api\/v1\/courses\/#{@course.id}\/files/ }).to be_truthy
      expect(links.find{ |l| l.match(/rel="prev"/)}).to match /page=2/
      expect(links.find{ |l| l.match(/rel="first"/)}).to match /page=1/
      expect(links.find{ |l| l.match(/rel="last"/)}).to match /page=3/
    end

    context "content_types" do
      before :once do
        txt = attachment_model :display_name => 'thing.txt', :content_type => 'text/plain', :context => @course, :folder => @f1
        png = attachment_model :display_name => 'thing.png', :content_type => 'image/png', :context => @course, :folder => @f1
        gif = attachment_model :display_name => 'thing.gif', :content_type => 'image/gif', :context => @course, :folder => @f1
      end

      it "should match one content-type" do
        json = api_call(:get, @files_path + "?content_types=image", @files_path_options.merge(:content_types => 'image'), {})
        res = json.map{|f|f['display_name']}
        expect(res).to eq %w(thing.gif thing.png)
      end

      it "should match multiple content-types" do
        json = api_call(:get, @files_path + "?content_types[]=text&content_types[]=image/gif",
                        @files_path_options.merge(:content_types => ['text', 'image/gif']))
        res = json.map{|f|f['display_name']}
        expect(res).to eq %w(thing.gif thing.txt)
      end
    end

    it "should search for files by title" do
      atts = []
      2.times {|i| atts << Attachment.create!(:filename => "first#{i}.txt", :display_name => "first#{i}.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course) }
      2.times {|i| Attachment.create!(:filename => "second#{i}.txt", :display_name => "second#{i}.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course) }

      json = api_call(:get, @files_path + "?search_term=fir", @files_path_options.merge(:search_term => 'fir'), {})
      expect(json.map{|h| h['id']}.sort).to eq atts.map(&:id).sort
    end

    describe "hidden folders" do
      before :once do
        hidden_subfolder = @f1.active_sub_folders.build(:name => "hidden", :context => @course)
        hidden_subfolder.workflow_state = 'hidden'
        hidden_subfolder.save!
        hidden_subsub = hidden_subfolder.active_sub_folders.create!(:name => "hsub", :context => @course)
        @teh_file = Attachment.create!(:filename => "implicitly hidden", :uploaded_data => default_uploaded_data, :folder => hidden_subsub, :context => @course)
      end

      context "as teacher" do
        it "should include files in subfolders of hidden folders" do
          json = api_call(:get, @files_path, @files_path_options)
          expect(json.map{|entry| entry['id']}).to include @teh_file.id
        end
      end

      context "as student" do
        before :once do
          student_in_course active_all: true
        end

        it "should exclude files in subfolders of hidden folders" do
          json = api_call(:get, @files_path, @files_path_options)
          expect(json.map{|entry| entry['id']}).not_to include @teh_file.id
        end
      end
    end
  end

  describe "#index other contexts" do
    it "should operate on groups" do
      group_model
      attachment_model display_name: 'foo', content_type: 'text/plain', context: @group, folder: Folder.root_folders(@group).first
      account_admin_user
      json = api_call(:get, "/api/v1/groups/#{@group.id}/files", { controller: "files", action: "api_index", format: "json", group_id: @group.to_param })
      expect(json.map{|r| r['id']}).to eql [@attachment.id]
      expect(response.headers['Link']).to include "/api/v1/groups/#{@group.id}/files"
    end

    it "should operate on users" do
      user_model
      attachment_model display_name: 'foo', content_type: 'text/plain', context: @user, folder: Folder.root_folders(@user).first
      json = api_call(:get, "/api/v1/users/#{@user.id}/files", { controller: "files", action: "api_index", format: "json", user_id: @user.to_param })
      expect(json.map{|r| r['id']}).to eql [@attachment.id]
      expect(response.headers['Link']).to include "/api/v1/users/#{@user.id}/files"
    end
  end

  describe "#show" do
    before :once do
      @root = Folder.root_folders(@course).first
      @att = Attachment.create!(:filename => 'test.png', :display_name => "test-frd.png", :uploaded_data => stub_png_data, :folder => @root, :context => @course)
      @file_path = "/api/v1/files/#{@att.id}"
      @file_path_options = { :controller => "files", :action => "api_show", :format => "json", :id => @att.id.to_param }
    end

    it "should return expected json" do
      json = api_call(:get, @file_path, @file_path_options, {})
      expect(json).to eq({
              'id' => @att.id,
              'folder_id' => @att.folder_id,
              'url' => file_download_url(@att, :verifier => @att.uuid, :download => '1', :download_frd => '1'),
              'content-type' => "image/png",
              'display_name' => 'test-frd.png',
              'filename' => @att.filename,
              'size' => @att.size,
              'unlock_at' => nil,
              'locked' => false,
              'hidden' => false,
              'lock_at' => nil,
              'locked_for_user' => false,
              'hidden_for_user' => false,
              'created_at' => @att.created_at.as_json,
              'updated_at' => @att.updated_at.as_json,
              'thumbnail_url' => @att.thumbnail_url,
              'modified_at' => @att.modified_at.as_json,
              'mime_class' => @att.mime_class,
              'media_entry_id' => @att.media_entry_id
      })
    end

    it "should work with a context path" do
      user_session(@user)
      opts = @file_path_options.merge(:course_id => @course.id.to_param)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/files/#{@att.id}", opts, {})
      expect(json['id']).to eq @att.id
    end

    it "should 404 with wrong context" do
      course_factory
      user_session(@user)
      opts = @file_path_options.merge(:course_id => @course.id.to_param)
      api_call(:get, "/api/v1/courses/#{@course.id}/files/#{@att.id}", opts, {}, {}, :expected_status => 404)
    end

    it "should omit verifiers when using session auth" do
      user_session(@user)
      get @file_path
      expect(response).to be_success
      json = json_parse
      expect(json['url']).to eq file_download_url(@att, :download => '1', :download_frd => '1')
    end

    it "should not omit verifiers when using session auth and params[:use_verifiers] is given" do
      user_session(@user)
      get @file_path + "?use_verifiers=1"
      expect(response).to be_success
      json = json_parse
      expect(json['url']).to eq file_download_url(@att, :download => '1', :download_frd => '1', :verifier => @att.uuid)
    end

    it "should return lock information" do
      one_month_ago, one_month_from_now = 1.month.ago, 1.month.from_now
      att2 = Attachment.create!(:filename => 'test.txt', :display_name => "test.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course, :locked => true)
      att3 = Attachment.create!(:filename => 'test.txt', :display_name => "test.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course, :unlock_at => one_month_ago, :lock_at => one_month_from_now)

      json = api_call(:get, "/api/v1/files/#{att2.id}", {:controller => "files", :action => "api_show", :format => "json", :id => att2.id.to_param}, {})
      expect(json['locked']).to be_truthy
      expect(json['unlock_at']).to be_nil
      expect(json['lock_at']).to be_nil

      json = api_call(:get, "/api/v1/files/#{att3.id}", {:controller => "files", :action => "api_show", :format => "json", :id => att3.id.to_param}, {})
      expect(json['locked']).to be_falsey
      expect(json['unlock_at']).to eq one_month_ago.as_json
      expect(json['lock_at']).to eq one_month_from_now.as_json
    end

    it "should not be locked/hidden for a teacher" do
      att2 = Attachment.create!(:filename => 'test.txt', :display_name => "test.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course, :locked => true)
      att2.hidden = true
      att2.save!
      json = api_call(:get, "/api/v1/files/#{att2.id}", {:controller => "files", :action => "api_show", :format => "json", :id => att2.id.to_param}, {})
      expect(json['locked']).to be_truthy
      expect(json['hidden']).to be_truthy
      expect(json['hidden_for_user']).to be_falsey
      expect(json['locked_for_user']).to be_falsey
    end

    def should_be_locked(json)
      expect(json['url']).to eq ""
      expect(json['thumbnail_url']).to eq ""
      expect(json['hidden']).to be_truthy
      expect(json['hidden_for_user']).to be_truthy
      expect(json['locked_for_user']).to be_truthy
    end

    it "should be locked/hidden for a student" do
      course_with_student(:course => @course)
      att2 = Attachment.create!(:filename => 'test.txt', :display_name => "test.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course, :locked => true)
      att2.hidden = true
      att2.save!
      json = api_call(:get, "/api/v1/files/#{att2.id}", {:controller => "files", :action => "api_show", :format => "json", :id => att2.id.to_param}, {})
      expect(json['locked']).to be_truthy
      should_be_locked(json)

      att2.locked = false
      att2.unlock_at = 2.days.from_now
      att2.lock_at = 2.days.ago
      att2.save!
      json = api_call(:get, "/api/v1/files/#{att2.id}", {:controller => "files", :action => "api_show", :format => "json", :id => att2.id.to_param}, {})
      expect(json['locked']).to be_falsey
      should_be_locked(json)

      att2.lock_at = att2.unlock_at = nil
      att2.save!
      json = api_call(:get, "/api/v1/files/#{att2.id}", {:controller => "files", :action => "api_show", :format => "json", :id => att2.id.to_param}, {})
      expect(json['url']).to eq file_download_url(att2, :verifier => att2.uuid, :download => '1', :download_frd => '1')
      expect(json['locked']).to be_falsey
      expect(json['locked_for_user']).to be_falsey
    end

    it "should return not found error" do
      api_call(:get, "/api/v1/files/0", @file_path_options.merge(:id => '0'), {}, {}, :expected_status => 404)
    end

    it "should return not found for deleted attachment" do
      @att.destroy
      api_call(:get, @file_path, @file_path_options, {}, {}, :expected_status => 404)
    end

    it "should return no permissions error for no context enrollment" do
      course_with_teacher(:active_all => true, :user => user_with_pseudonym)
      api_call(:get, @file_path, @file_path_options, {}, {}, :expected_status => 401)
    end

    it "should return a hidden file" do
      course_with_student(:course => @course)
      @att.hidden = true
      @att.save!
      api_call(:get, @file_path, @file_path_options, {}, {}, :expected_status => 200)
    end

    it "should return user if requested" do
      @att.update_attribute(:user, @user)
      json = api_call(:get, @file_path + "?include[]=user", @file_path_options.merge(include: ['user']))
      expect(json['user']).to eql({
        "id" => @user.id,
        "display_name" => @user.short_name,
        "avatar_image_url" => User.avatar_fallback_url(nil, request),
        "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@user.id}"
      })
    end

    it "should return usage_rights if requested" do
      @att.usage_rights = @course.usage_rights.create! legal_copyright: '(C) 2012 Initrode', use_justification: 'creative_commons', license: 'cc_by_sa'
      @att.save!
      json = api_call(:get, @file_path + "?include[]=usage_rights", @file_path_options.merge(include: ['usage_rights']))
      expect(json['usage_rights']).to eql({
          "legal_copyright" => "(C) 2012 Initrode",
          "use_justification" => "creative_commons",
          "license" => "cc_by_sa",
          "license_name" => "CC Attribution Share Alike"
      })
    end
  end

  describe "#destroy" do
    before :once do
      @root = Folder.root_folders(@course).first
      @att = Attachment.create!(:filename => 'test.txt', :display_name => "test.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course)
      @file_path = "/api/v1/files/#{@att.id}"
      @file_path_options = { :controller => "files", :action => "destroy", :format => "json", :id => @att.id.to_param }
    end

    it "should delete a file" do
      api_call(:delete, @file_path, @file_path_options)
      @att.reload
      expect(@att.file_state).to eq 'deleted'
    end

    it "should return 404" do
      api_call(:delete, "/api/v1/files/0", @file_path_options.merge(:id => '0'), {}, {}, :expected_status => 404)
    end

    it "should return unauthorized error if not authorized to delete" do
      course_with_student(:course => @course)
      api_call(:delete, @file_path, @file_path_options, {}, {}, :expected_status => 401)
    end
  end

  describe "#update" do
    before :once do
      @root = Folder.root_folders(@course).first
      @att = Attachment.create!(:filename => 'test.txt', :display_name => "test.txt", :uploaded_data => StringIO.new('file'), :folder => @root, :context => @course)
      @file_path = "/api/v1/files/#{@att.id}"
      @file_path_options = { :controller => "files", :action => "api_update", :format => "json", :id => @att.id.to_param }
    end

    it "should update" do
      unlock = 1.days.from_now
      lock = 3.days.from_now
      new_params = {:name => "newname.txt", :locked => 'true', :hidden => true, :unlock_at => unlock.iso8601, :lock_at => lock.iso8601}
      json = api_call(:put, @file_path, @file_path_options, new_params, {}, :expected_status => 200)
      expect(json['url']).to include 'verifier='
      @att.reload
      expect(@att.display_name).to eq "newname.txt"
      expect(@att.locked).to be_truthy
      expect(@att.hidden).to be_truthy
      expect(@att.unlock_at.to_i).to eq unlock.to_i
      expect(@att.lock_at.to_i).to eq lock.to_i
    end

    it "should omit verifier in-app" do
      FilesController.any_instance.stubs(:in_app?).returns(true)
      FilesController.any_instance.stubs(:verified_request?).returns(true)

      new_params = {:locked => 'true'}
      json = api_call(:put, @file_path, @file_path_options, new_params)
      expect(json['url']).not_to include 'verifier='
    end

    it "should move to another folder" do
      @sub = @root.sub_folders.create!(:name => "sub", :context => @course)
      api_call(:put, @file_path, @file_path_options, {:parent_folder_id => @sub.id.to_param}, {}, :expected_status => 200)
      @att.reload
      expect(@att.folder_id).to eq @sub.id
    end

    describe "rename where file already exists" do
      before :once do
        @existing_file = Attachment.create! filename: 'newname.txt', display_name: 'newname.txt', uploaded_data: StringIO.new('blah'), folder: @root, context: @course
      end

      it "should fail if on_duplicate isn't provided" do
        api_call(:put, @file_path, @file_path_options, {name: 'newname.txt'}, {}, {expected_status: 409})
        expect(@att.reload.display_name).to eq 'test.txt'
        expect(@existing_file.reload).not_to be_deleted
      end

      it "should overwrite if asked" do
        api_call(:put, @file_path, @file_path_options, {name: 'newname.txt', on_duplicate: 'overwrite'})
        expect(@att.reload.display_name).to eq 'newname.txt'
        expect(@existing_file.reload).to be_deleted
        expect(@existing_file.replacement_attachment).to eq @att
      end

      it "should rename if asked" do
        api_call(:put, @file_path, @file_path_options, {name: 'newname.txt', on_duplicate: 'rename'})
        expect(@existing_file.reload).not_to be_deleted
        expect(@existing_file.name).to eq 'newname.txt'
        expect(@att.reload.display_name).not_to eq 'test.txt'
        expect(@att.display_name).not_to eq 'newname.txt'
        expect(@att.display_name).to start_with 'newname'
        expect(@att.display_name).to end_with '.txt'
      end
    end

    describe "move where file already exists" do
      before :once do
        @sub = @root.sub_folders.create! name: 'sub', context: @course
        @existing_file = Attachment.create! filename: 'test.txt', display_name: 'test.txt', uploaded_data: StringIO.new('existing'), folder: @sub, context: @course
      end

      it "should fail if on_duplicate isn't provided" do
        api_call(:put, @file_path, @file_path_options, {parent_folder_id: @sub.to_param}, {}, {expected_status: 409})
        expect(@existing_file.reload).not_to be_deleted
        expect(@att.reload.folder).to eq @root
      end

      it "should overwrite if asked" do
        api_call(:put, @file_path, @file_path_options, {parent_folder_id: @sub.to_param, on_duplicate: 'overwrite'})
        expect(@existing_file.reload).to be_deleted
        expect(@att.reload.folder).to eq @sub
        expect(@att.display_name).to eq @existing_file.display_name
      end

      it "should rename if asked" do
        api_call(:put, @file_path, @file_path_options, {parent_folder_id: @sub.to_param, on_duplicate: 'rename'})
        expect(@existing_file.reload).not_to be_deleted
        expect(@att.reload.folder).to eq @sub
        expect(@att.display_name).not_to eq @existing_file.display_name
      end
    end

    describe "submissions folder" do
      before(:once) do
        @student = user_model
        @root_folder = Folder.root_folders(@student).first
        @file = Attachment.create! filename: 'file.txt', display_name: 'file.txt', uploaded_data: StringIO.new('blah'), folder: @root_folder, context: @student
        @sub_folder = @student.submissions_folder
        @sub_file = Attachment.create! filename: 'sub.txt', display_name: 'sub.txt', uploaded_data: StringIO.new('bleh'), folder: @sub_folder, context: @student
      end

      it "should not move a file into a submissions folder" do
        api_call_as_user(@student, :put, "/api/v1/files/#{@file.id}",
                         { :controller => "files", :action => "api_update", :format => "json", :id => @file.to_param },
                         { :parent_folder_id => @sub_folder.to_param },
                         {}, { :expected_status => 401 })
      end

      it "should not move a file out of a submissions folder" do
        api_call_as_user(@student, :put, "/api/v1/files/#{@sub_file.id}",
                         { :controller => "files", :action => "api_update", :format => "json", :id => @sub_file.to_param },
                         { :parent_folder_id => @root_folder.to_param },
                         {}, { :expected_status => 401 })
      end
    end

    it "should return unauthorized error" do
      course_with_student(:course => @course)
      api_call(:put, @file_path, @file_path_options, {:name => "new name"}, {}, :expected_status => 401)
    end

    it "should 404 with invalid parent id" do
      api_call(:put, @file_path, @file_path_options, {:parent_folder_id => 0}, {}, :expected_status => 404)
    end

    it "should not allow moving to different context" do
      user_root = Folder.root_folders(@user).first
      api_call(:put, @file_path, @file_path_options, {:parent_folder_id => user_root.id.to_param}, {}, :expected_status => 404)
    end

    context "with usage_rights_required" do
      before do
        @course.enable_feature! :usage_rights_required
        user_session(@teacher)
        @att.update_attribute(:locked, true)
      end

      it "should not publish if usage_rights unset" do
        api_call(:put, @file_path, @file_path_options, {:locked => false}, {}, :expected_status => 400)
        expect(@att.reload).to be_locked
      end

      it "should publish if usage_rights set" do
        @att.usage_rights = @course.usage_rights.create! use_justification: 'public_domain'
        @att.save!
        api_call(:put, @file_path, @file_path_options, {:locked => false}, {}, :expected_status => 200)
        expect(@att.reload).not_to be_locked
      end
    end
  end

  describe "quota" do
    let_once(:t_course) do
      course_with_teacher active_all: true
      @course.storage_quota = 111.megabytes
      @course.save
      attachment_model context: @course, size: 33.megabytes
      @course
    end

    let_once(:t_teacher) do
      t_course.teachers.first
    end

    before(:each) do
      user_session(@teacher)
    end

    it "should return total and used quota" do
      json = api_call_as_user(t_teacher, :get, "/api/v1/courses/#{t_course.id}/files/quota", controller: 'files',
                              action: 'api_quota', format: 'json', course_id: t_course.to_param)
      expect(json).to eql({"quota" => 111.megabytes, "quota_used" => 33.megabytes})
    end

    it "should require manage_files permissions" do
      student_in_course course: t_course, active_all: true
      api_call_as_user(@student, :get, "/api/v1/courses/#{t_course.id}/files/quota",
                       {controller: 'files', action: 'api_quota', format: 'json', course_id: t_course.to_param},
                       {}, {}, { expected_status: 401 })
    end

    it "should operate on groups" do
      group = Account.default.groups.create!
      attachment_model context: group, size: 13.megabytes
      account_admin_user
      json = api_call(:get, "/api/v1/groups/#{group.id}/files/quota", controller: 'files', action: 'api_quota',
                      format: 'json', group_id: group.to_param)
      expect(json).to eql({"quota" => group.quota, "quota_used" => 13.megabytes})
    end

    it "should operate on users" do
      course_with_student active_all: true
      json = api_call(:get, "/api/v1/users/self/files/quota", controller: 'files', action: 'api_quota',
                      format: 'json', user_id: 'self')
      expect(json).to eql({"quota" => @student.quota, "quota_used" => 0})
    end
  end
end

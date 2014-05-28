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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe ContextController do
  describe "GET 'roster'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'roster', :course_id => @course.id
      assert_unauthorized
    end

    it "should work when the context is a group in a course" do
      course_with_student_logged_in(:active_all => true)
      @group = @course.groups.create!
      @group.add_user(@student, 'accepted')
      get 'roster', :group_id => @group.id
      assigns[:primary_users].each_value.first.collect(&:id).should == [@student.id]
      assigns[:secondary_users].each_value.first.collect(&:id).should == [@teacher.id]
    end
  end

  describe "GET 'roster_user'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'roster_user', :course_id => @course.id, :id => @user.id
      assert_unauthorized
    end

    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      @enrollment = @course.enroll_student(user(:active_all => true))
      @enrollment.accept!
      @student = @enrollment.user
      get 'roster_user', :course_id => @course.id, :id => @student.id
      assigns[:membership].should_not be_nil
      assigns[:membership].should eql(@enrollment)
      assigns[:user].should_not be_nil
      assigns[:user].should eql(@student)
      assigns[:topics].should_not be_nil
      assigns[:entries].should_not be_nil
    end

    describe 'across shards' do
      specs_require_sharding

      it 'allows merged users from other shards to be referenced' do
        user1 = user_model
        course1 = course(:active_all => 1)
        course1.enroll_user(user1)

        @shard2.activate do
          @user2 = user_model
          @course2 = course(:active_all => 1)
          @course2.enroll_user(@user2)
        end

        UserMerge.from(user1).into(@user2)

        admin = user_model
        Account.site_admin.add_user(admin)
        user_session(admin)

        get 'roster_user', :course_id => course1.id, :id => @user2.id
        response.should be_success
      end
    end
  end

  describe "POST 'object_snippet'" do
    before(:each) do
      @obj = "<object data='test'></object>"
      HostUrl.stubs(:is_file_host?).returns(true)
      @data = Base64.encode64(@obj)
      @hmac = Canvas::Security.hmac_sha1(@data)
    end

    it "should require a valid HMAC" do
      post 'object_snippet', :object_data => @data, :s => 'DENIED'
      assert_status(400)
    end

    it "should render given a correct HMAC" do
      post 'object_snippet', :object_data => @data, :s => @hmac
      response.should be_success
      response['X-XSS-Protection'].should == '0'
    end
  end

  describe "GET '/media_objects/:id/thumbnail" do
    it "should redirect to kaltura even if the MediaObject does not exist" do
      CanvasKaltura::ClientV3.stubs(:config).returns({})
      CanvasKaltura::ClientV3.any_instance.expects(:thumbnail_url).returns("http://example.com/thumbnail_redirect")
      get :media_object_thumbnail,
        :id => '0_notexist',
        :width => 100,
        :height => 100

      response.should be_redirect
      response.location.should == "http://example.com/thumbnail_redirect"
    end
  end

  describe "POST '/media_objects'" do
    before :each do
      course_with_student_logged_in(:active_all => true)
    end

    it "should match the create_media_object route" do
      assert_recognizes({:controller => 'context', :action => 'create_media_object'}, {:path => 'media_objects', :method => :post})
    end

    it "should update the object if it already exists" do
      @media_object = @user.media_objects.build(:media_id => "new_object")
      @media_object.media_type = "audio"
      @media_object.title = "original title"
      @media_object.save

      @original_count = @user.media_objects.count

      post :create_media_object,
        :context_code => "user_#{@user.id}",
        :id => @media_object.media_id,
        :type => @media_object.media_type,
        :title => "new title"

      @media_object.reload
      @media_object.title.should == "new title"

      @user.reload
      @user.media_objects.count.should == @original_count
    end

    it "should create the object if it doesn't already exist" do
      @original_count = @user.media_objects.count

      post :create_media_object,
        :context_code => "user_#{@user.id}",
        :id => "new_object",
        :type => "audio",
        :title => "title"

      @user.reload
      @user.media_objects.count.should == @original_count + 1
      @media_object = @user.media_objects.last

      @media_object.media_id.should == "new_object"
      @media_object.media_type.should == "audio"
      @media_object.title.should == "title"
    end

    it "should truncate the title and user_entered_title" do
      post :create_media_object,
        :context_code => "user_#{@user.id}",
        :id => "new_object",
        :type => "audio",
        :title => 'x' * 300,
        :user_entered_title => 'y' * 300
      @media_object = @user.reload.media_objects.last
      @media_object.title.size.should <= 255
      @media_object.user_entered_title.size.should <= 255
    end
  end

  describe "GET 'prior_users" do
    before do
      course_with_teacher_logged_in(:active_all => true)
      100.times { student_in_course(:active_all => true).conclude }
      @user = @teacher
    end

    it "should paginate" do
      get :prior_users, :course_id => @course.id
      response.should be_success
      assigns[:prior_users].size.should eql 20
    end
  end
end

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

describe ContextController do
  describe "GET 'roster'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'roster', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      get 'roster', :course_id => @course.id
      assigns[:students].should_not be_nil
      assigns[:teachers].should_not be_nil
    end
    
    it "should retrieve students and teachers" do
      course_with_student_logged_in(:active_all => true)
      @student = @user
      @teacher = user(:active_all => true)
      @teacher = @course.enroll_teacher(@teacher)
      @teacher.accept!
      @teacher = @teacher.user
      get 'roster', :course_id => @course.id
      assigns[:students].should_not be_nil
      assigns[:students].should_not be_empty
      assigns[:students].should be_include(@student) #[0].should eql(@user)
      assigns[:teachers].should_not be_nil
      assigns[:teachers].should_not be_empty
      assigns[:teachers].should be_include(@teacher) #[0].should eql(@teacher)
    end

    it "should not include designers as teachers" do
      course_with_student_logged_in(:active_all => true)
      @designer = user(:active_all => true)
      @course.enroll_designer(@designer).accept!
      get 'roster', :course_id => @course.id
      assigns[:teachers].should_not be_include(@designer)
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
      assigns[:enrollment].should_not be_nil
      assigns[:enrollment].should eql(@enrollment)
      assigns[:user].should_not be_nil
      assigns[:user].should eql(@student)
      assigns[:topics].should_not be_nil
      assigns[:entries].should_not be_nil
    end
  end

  describe "GET 'chat'" do
    it "should redirect if no chats enabled" do
      course_with_teacher(:active_all => true)
      get 'chat', :course_id => @course.id, :id => @user.id
      response.should be_redirect
    end
    
    it "should require authorization" do
      PluginSetting.create!(:name => "tinychat", :settings => {})
      course_with_teacher(:active_all => true)
      get 'chat', :course_id => @course.id, :id => @user.id
      assert_unauthorized
    end
    
    it "should redirect 'disabled', if disabled by the teacher" do
      PluginSetting.create!(:name => "tinychat", :settings => {})
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:tab_configuration, [{'id'=>9,'hidden'=>true}])
      get 'chat', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
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
      response.status.should == '400 Bad Request'
    end

    it "should render given a correct HMAC" do
      post 'object_snippet', :object_data => @data, :s => @hmac
      response.should be_success
      response['X-XSS-Protection'].should == '0'
    end
  end

  describe "GET '/media_objects/:id/thumbnail" do
    it "should redirect to kaltura even if the MediaObject does not exist" do
      Kaltura::ClientV3.stubs(:config).returns({})
      Kaltura::ClientV3.any_instance.expects(:thumbnail_url).returns("http://example.com/thumbnail_redirect")
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
  end
end

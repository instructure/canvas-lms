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

describe "security" do

  describe "session fixation" do
    it "should change the cookie session id after logging in" do
    
      u = user_with_pseudonym :active_user => true,
                              :username => "nobody@example.com",
                              :password => "asdfasdf"
      u.save!
    
      https!
      
      get_via_redirect "/login"
      assert_response :success
      cookie = cookies['_normandy_session']
      cookie.should be_present
      path.should == "/login"

      post_via_redirect "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
                                  "pseudonym_session[password]" => "asdfasdf",
                                  "pseudonym_session[remember_me]" => "1",
                                  "redirect_to_ssl" => "1"
      assert_response :success
      path.should eql("/?login_success=1")
      new_cookie = cookies['_normandy_session']
      new_cookie.should be_present
      cookie.should_not eql(new_cookie)
    end
  end

  describe "permissions" do
    it "should flush the role_override caches on permission changes" do
      course_with_teacher_logged_in

      get "/courses/#{@course.to_param}/users"
      assert_response :success

      RoleOverride.create!(:context => @course,
                           :permission => 'read_roster',
                           :enrollment_type => 'TeacherEnrollment',
                           :enabled => false)

      # if this second get doesn't fail with a permission denied error, we've
      # still got the permissions cached and haven't seen the change
      get "/courses/#{@course.to_param}/users"
      assert_response 401
    end

    # if we end up moving the permissions cache to memcache, this test won't be
    # valid anymore and we need some more extensive tests for actual cache
    # invalidation. right now, though, this is the only really valid way to
    # test that we're actually flushing on every request.
    it "should flush the role_override caches on every request" do
      course_with_teacher_logged_in

      get "/courses/#{@course.to_param}/users"
      assert_response :success

      RoleOverride.send(:instance_variable_get, '@cached_permissions').should_not be_empty
      RoleOverride.send(:class_variable_get, '@@role_override_chain').should_not be_empty

      get "/dashboard"
      assert_response 301

      # verify the cache is emptied on every request
      RoleOverride.send(:instance_variable_get, '@cached_permissions').should be_empty
      RoleOverride.send(:class_variable_get, '@@role_override_chain').should be_empty
    end
  end

  it "should make both session-related cookies httponly" do
    u = user_with_pseudonym :active_user => true,
                            :username => "nobody@example.com",
                            :password => "asdfasdf"
    u.save!

    https!

    post "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
      "pseudonym_session[password]" => "asdfasdf",
      "pseudonym_session[remember_me]" => "1",
      "redirect_to_ssl" => "1"
    assert_response 302
    c1 = response['Set-Cookie'].grep(/\Apseudonym_credentials=/).first
    c2 = response['Set-Cookie'].grep(/\A_normandy_session=/).first
    c1.should match(/; *HttpOnly/)
    c2.should match(/; *HttpOnly/)
    c1.should_not match(/; *secure/)
    c2.should_not match(/; *secure/)
  end

  it "should make both session-related cookies secure only if configured" do
    ActionController::Base.session_options[:secure] = true
    u = user_with_pseudonym :active_user => true,
                            :username => "nobody@example.com",
                            :password => "asdfasdf"
    u.save!

    https!

    post "/login", "pseudonym_session[unique_id]" => "nobody@example.com",
      "pseudonym_session[password]" => "asdfasdf",
      "pseudonym_session[remember_me]" => "1",
      "redirect_to_ssl" => "1"
    assert_response 302
    c1 = response['Set-Cookie'].grep(/\Apseudonym_credentials=/).first
    c2 = response['Set-Cookie'].grep(/\A_normandy_session=/).first
    c1.should match(/; *secure/)
    c2.should match(/; *secure/)
    ActionController::Base.session_options[:secure] = nil
  end
  
  it "should only allow user list username resolution if the current user has appropriate rights" do
    Account.default.pseudonyms.create!(:unique_id => "A1234567").assert_user{|u| u.name = "test user"}
    @course = Account.default.courses.create!
    @course.offer!
    @teacher = user :active_all => true
    @course.enroll_teacher(@teacher).tap do |e|
      e.workflow_state = 'active'
      e.save!
    end
    @student = user :active_all => true
    @course.enroll_student(@student).tap do |e|
      e.workflow_state = 'active'
      e.save!
    end
    @course.reload

    user_session(@student)
    post "/courses/#{@course.id}/user_lists.json", :user_list => "A1234567, A345678"
    assert_response :success
    ActiveSupport::JSON.decode(response.body).should == {
      "duplicates" => [],
      "errored_users" => [],
      "users" => [{"login" => "A1234567"}, {"login" => "A345678"}]
    }
    
    user_session(@teacher)
    post "/courses/#{@course.id}/user_lists.json", :user_list => "A1234567, A345678"
    assert_response :success
    ActiveSupport::JSON.decode(response.body).should == {
      "duplicates" => [],
      "errored_users" => ["A345678"],
      "users" => [{"login" => "A1234567", "name" => "test user"}]
    }
    
    user_session(@student)
    post "/courses/#{@course.id}/user_lists.json", :user_list => "A1234567, A345678"
    assert_response :success
    ActiveSupport::JSON.decode(response.body).should == {
      "duplicates" => [],
      "errored_users" => [],
      "users" => [{"login" => "A1234567"}, {"login" => "A345678"}]
    }
  end

  describe "user masquerading" do
    before(:each) do
      course_with_teacher
      @teacher = @user

      student_in_course
      @student = @user
      user_with_pseudonym :user => @student, :username => 'student@example.com', :password => 'password'

      account_admin_user :account => Account.site_admin
      @admin = @user
      user_with_pseudonym :user => @admin, :username => 'admin@example.com', :password => 'password'
    end

    it "should require confirmation for becoming a user" do
      user_session(@admin, @admin.pseudonyms.first)

      get "/?become_user_id=#{@student.id}"
      assert_response 302
      response.location.should match "/users/#{@student.id}/masquerade$"
      session[:masquerade_return_to].should == "/"
      session[:become_user_id].should be_nil
      assigns['current_user'].id.should == @admin.id
      assigns['real_current_user'].should be_nil

      follow_redirect!
      assert_response 200
      path.should == "/users/#{@student.id}/masquerade"
      session[:become_user_id].should be_nil
      assigns['current_user'].id.should == @admin.id
      assigns['real_current_user'].should be_nil

      post "/users/#{@student.id}/masquerade"
      assert_response 302
      session[:become_user_id].should == @student.id.to_s

      get "/"
      assert_response 200
      session[:become_user_id].should == @student.id.to_s
      assigns['current_user'].id.should == @student.id
      assigns['real_current_user'].id.should == @admin.id
    end

    it "should not allow non-admins to become other people" do
      user_session(@student, @student.pseudonyms.first)

      get "/?become_user_id=#{@teacher.id}"
      assert_response 200
      session[:become_user_id].should be_nil
      assigns['current_user'].id.should == @student.id
      assigns['real_current_user'].should be_nil

      post "/users/#{@teacher.id}/masquerade"
      assert_response 401
      assigns['current_user'].id.should == @student.id
      session[:become_user_id].should be_nil
    end

    it "should record real user in page_views" do
      Setting.set('enable_page_views', 'db')
      user_session(@admin, @admin.pseudonyms.first)

      get "/?become_user_id=#{@student.id}"
      assert_response 302
      response.location.should match "/users/#{@student.id}/masquerade$"
      session[:masquerade_return_to].should == "/"
      session[:become_user_id].should be_nil
      assigns['current_user'].id.should == @admin.id
      assigns['real_current_user'].should be_nil

      follow_redirect!
      assert_response 200
      path.should == "/users/#{@student.id}/masquerade"
      session[:become_user_id].should be_nil
      assigns['current_user'].id.should == @admin.id
      assigns['real_current_user'].should be_nil
      PageView.last.user_id.should == @admin.id
      PageView.last.real_user_id.should be_nil

      post "/users/#{@student.id}/masquerade"
      assert_response 302
      session[:become_user_id].should == @student.id.to_s

      get "/"
      assert_response 200
      session[:become_user_id].should == @student.id.to_s
      assigns['current_user'].id.should == @student.id
      assigns['real_current_user'].id.should == @admin.id
      PageView.last.user_id.should == @student.id
      PageView.last.real_user_id.should == @admin.id
    end
  end

  it "should not allow logins to safefiles domains" do
    HostUrl.stub!(:is_file_host?).and_return(true)
    HostUrl.stub!(:default_host).and_return('test.host')
    get "http://files-test.host/login"
    response.should be_redirect
    uri = URI.parse response['Location']
    uri.host.should == 'test.host'

    HostUrl.stub!(:is_file_host?).and_return(false)
    get "http://test.host/login"
    response.should be_success
  end
end

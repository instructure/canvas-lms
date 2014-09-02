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

describe UsersController do
  describe "#teacher_activity" do
    before do
      course_with_teacher_logged_in(:active_all => true)
      @course.update_attribute(:name, 'coursename1')
      @enrollment.update_attribute(:limit_privileges_to_course_section, true)
      @et = @enrollment
      @s1 = @course.course_sections.first
      @s2 = @course.course_sections.create!(:name => 'Section B')
      @e1 = student_in_course(:active_all => true)
      @e2 = student_in_course(:active_all => true)
      @e1.user.update_attribute(:name, 'studentname1')
      @e2.user.update_attribute(:name, 'studentname2')
      @e2.update_attribute(:course_section, @s2)
    end

    it "should count conversations as interaction" do
      get user_student_teacher_activity_url(@teacher, @e1.user)
      Nokogiri::HTML(response.body).at_css('table.report tbody tr:first td:nth(2)').text.should match(/never/)

      @conversation = Conversation.initiate([@e1.user, @teacher], false)
      @conversation.add_message(@teacher, "hello")

      get user_student_teacher_activity_url(@teacher, @e1.user)
      Nokogiri::HTML(response.body).at_css('table.report tbody tr:first td:nth(2)').text.should match(/less than 1 day/)
    end

    it "should only include students the teacher can view" do
      get user_course_teacher_activity_url(@teacher, @course)
      response.should be_success
      response.body.should match(/studentname1/)
      response.body.should_not match(/studentname2/)
    end

    it "should show user notes if enabled" do
      get user_course_teacher_activity_url(@teacher, @course)
      response.body.should_not match(/journal entry/i)
      @course.root_account.update_attribute(:enable_user_notes, true)
      get user_course_teacher_activity_url(@teacher, @course)
      response.body.should match(/journal entry/i)
    end

    it "should show individual user info across courses" do
      @course1 = @course
      @course2 = course(:active_course => true)
      @course2.update_attribute(:name, 'coursename2')
      student_in_course(:course => @course2, :user => @e1.user)
      get user_student_teacher_activity_url(@teacher, @e1.user)
      response.should be_success
      response.body.should match(/studentname1/)
      response.body.should_not match(/studentname2/)
      response.body.should match(/coursename1/)
      # teacher not in course2
      response.body.should_not match(/coursename2/)
      # now put teacher in course2
      @course2.enroll_teacher(@teacher).accept!
      get user_student_teacher_activity_url(@teacher, @e1.user)
      response.should be_success
      response.body.should match(/coursename1/)
      response.body.should match(/coursename2/)
    end

    it "should be available for concluded courses/enrollments" do
      account_admin_user(:username => "admin")
      user_session(@admin)

      @course.complete
      @et.conclude
      @e1.conclude

      get user_student_teacher_activity_url(@teacher, @e1.user)
      response.should be_success
      response.body.should match(/studentname1/)

      get user_course_teacher_activity_url(@teacher, @course)
      response.should be_success
      response.body.should match(/studentname1/)
    end

    it "should show concluded students to active teachers" do
      @e1.conclude

      get user_student_teacher_activity_url(@teacher, @e1.user)
      response.should be_success
      response.body.should match(/studentname1/)

      get user_course_teacher_activity_url(@teacher, @course)
      response.should be_success
      response.body.should match(/studentname1/)
    end
  end

  describe "#index" do
    it "should render" do
      user_with_pseudonym(:active_all => 1)
      @johnstclair = @user.update_attributes(:name => 'John St. Clair', :sortable_name => 'St. Clair, John')
      user_with_pseudonym(:active_all => 1, :username => 'jtolds@instructure.com', :name => 'JT Olds')
      @jtolds = @user
      Account.default.account_users.create!(user: @user)
      user_session(@user, @pseudonym)
      get account_users_url(Account.default)
      response.should be_success
      response.body.should match /Olds, JT.*St\. Clair, John/m
    end

    it "should not show any student view students at the account level" do
      course_with_teacher(:active_all => true)
      @fake_student = @course.student_view_student

      site_admin_user(:active_all => true)
      user_session(@admin)

      get account_users_url Account.default.id
      body = Nokogiri::HTML(response.body)
      body.css("#user_#{@fake_student.id}").should be_empty
      body.at_css('.users').text.should_not match(/Test Student/)
    end
  end

  describe "#show" do
    it "should allow admins to view users in their account" do
      @admin = account_admin_user
      user_session(@admin)

      course
      student_in_course(:course => @course)
      get "/users/#{@student.id}"
      response.should be_success

      course(:account => account_model)
      student_in_course(:course => @course)
      get "/users/#{@student.id}"
      assert_status(401)
    end

    it "should show user to account users that have the view_statistics permission" do
      account_model
      student_in_course(:account => @account)
      RoleOverride.create!(:context => @account, :permission => 'view_statistics',
                           :enrollment_type => 'AccountMembership', :enabled => true)
      @account.account_users.create!(user: user, membership_type: 'AccountMembership')
      user_session(@user)

      get "/users/#{@student.id}"
      response.should be_success
    end

    it "should show course user to account users that have the read_roster permission" do
      account_model
      student_in_course(:account => @account)
      RoleOverride.create!(:context => @account, :permission => 'read_roster',
                           :enrollment_type => 'AccountMembership', :enabled => true)
      @account.account_users.create!(user: user, membership_type: 'AccountMembership')
      user_session(@user)

      get "/courses/#{@course.id}/users/#{@student.id}"
      response.should be_success
    end
  end

  describe "#avatar_image_url" do
    before do
      course_with_student_logged_in(:active_all => true)
      @a = Account.default
      enable_avatars!
    end

    def enable_avatars!
      @a.enable_service(:avatars)
      @a.save!
    end

    def disable_avatars!
      @a.disable_service(:avatars)
      @a.save!
    end

    it "should maintain protocol and domain name in fallback" do
      disable_avatars!
      enable_cache do
        get "http://someschool.instructure.com/images/users/#{User.avatar_key(@user.id)}"
        response.should redirect_to "http://someschool.instructure.com/images/no_pic.gif"

        get "https://otherschool.instructure.com/images/users/#{User.avatar_key(@user.id)}"
        response.should redirect_to "https://otherschool.instructure.com/images/no_pic.gif"
      end
    end

    it "should maintain protocol and domain name in gravatar redirect fallback" do
      enable_cache do
        get "http://someschool.instructure.com/images/users/#{User.avatar_key(@user.id)}"
        response.should redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI::escape("http://someschool.instructure.com/images/messages/avatar-50.png")}"

        get "https://otherschool.instructure.com/images/users/#{User.avatar_key(@user.id)}"
        response.should redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI::escape("https://otherschool.instructure.com/images/messages/avatar-50.png")}"
      end
    end

    it "should return different urls for different fallbacks" do
      enable_cache do
        get "http://someschool.instructure.com/images/users/#{User.avatar_key(@user.id)}"
        response.should redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI::escape("http://someschool.instructure.com/images/messages/avatar-50.png")}"

        get "http://someschool.instructure.com/images/users/#{User.avatar_key(@user.id)}?fallback=#{CGI.escape("/my/custom/fallback/url.png")}"
        response.should redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI::escape("http://someschool.instructure.com/my/custom/fallback/url.png")}"

        get "http://someschool.instructure.com/images/users/#{User.avatar_key(@user.id)}?fallback=#{CGI.escape("https://test.domain/another/custom/fallback/url.png")}"
        response.should redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI::escape("https://test.domain/another/custom/fallback/url.png")}"
      end
    end

    it "should forget all cached urls when the avatar changes" do
      enable_cache do
        data = Rails.cache.instance_variable_get(:@data)
        orig_size = data.size

        get "http://someschool.instructure.com/images/users/#{User.avatar_key(@user.id)}"
        response.should redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI::escape("http://someschool.instructure.com/images/messages/avatar-50.png")}"

        get "https://otherschool.instructure.com/images/users/#{User.avatar_key(@user.id)}?fallback=/my/custom/fallback/url.png"
        response.should redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI::escape("https://otherschool.instructure.com/my/custom/fallback/url.png")}"

        diff = data.select{|k,v|k =~ /avatar_img/}.size - orig_size
        diff.should > 0

        @user.update_attribute(:avatar_image, {'type' => 'attachment', 'url' => '/images/thumbnails/foo.gif'})
        data.select{|k,v|k =~ /avatar_img/}.size.should == orig_size

        get "http://someschool.instructure.com/images/users/#{User.avatar_key(@user.id)}"
        response.should redirect_to "http://someschool.instructure.com/images/thumbnails/foo.gif"

        get "http://otherschool.instructure.com/images/users/#{User.avatar_key(@user.id)}?fallback=#{CGI::escape("https://test.domain/my/custom/fallback/url.png")}"
        response.should redirect_to "http://otherschool.instructure.com/images/thumbnails/foo.gif"
        data.select{|k,v|k =~ /avatar_img/}.size.should == orig_size + diff
      end
    end
  end

  describe "#grades" do
    it "should only list courses once for multiple enrollments" do
      course_with_student_logged_in(:active_all => true)
      @first_course = @course
      add_section("other section")
      multiple_student_enrollment(@student, @course_section)
      course_with_student(:user => @student, :active_all => true)

      get grades_url
      student_grades = Nokogiri::HTML(response.body).css('.student_grades tr')
      student_grades.length.should == 2
      student_grades.text.should match /#{@first_course.name}/
      student_grades.text.should match /#{@course.name}/
    end
  end

  describe "admin_merge" do
    it "should work for the whole flow" do
      user_with_pseudonym(:active_all => 1)
      Account.default.account_users.create!(user: @user)
      @admin = @user
      user_with_pseudonym(:active_all => 1, :username => 'user2@instructure.com')
      user_session(@admin)

      get user_admin_merge_url(@user, :pending_user_id => @admin.id)
      response.should be_success
      assigns['pending_other_user'].should == @admin
      assigns['other_user'].should be_nil

      get user_admin_merge_url(@user, :new_user_id => @admin.id)
      response.should be_success
      assigns['pending_other_user'].should be_nil
      assigns['other_user'].should == @admin

      post user_merge_url(@user, :new_user_id => @admin.id)
      response.should redirect_to(user_profile_url(@admin))

      @user.reload.should be_deleted
      @admin.reload.should be_registered
      @admin.pseudonyms.count.should == 2
    end
  end
end


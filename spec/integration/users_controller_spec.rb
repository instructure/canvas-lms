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

require 'nokogiri'

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
      expect(Nokogiri::HTML(response.body).at_css('table.report tbody tr:first td:nth(2)').text).to match(/never/)

      @conversation = Conversation.initiate([@e1.user, @teacher], false)
      @conversation.add_message(@teacher, "hello")

      get user_student_teacher_activity_url(@teacher, @e1.user)
      expect(Nokogiri::HTML(response.body).at_css('table.report tbody tr:first td:nth(2)').text).to match(/less than 1 day/)
    end

    it "should only include students the teacher can view" do
      get user_course_teacher_activity_url(@teacher, @course)
      expect(response).to be_success
      expect(response.body).to match(/studentname1/)
      expect(response.body).not_to match(/studentname2/)
    end

    it "should show user notes if enabled" do
      get user_course_teacher_activity_url(@teacher, @course)
      expect(response.body).not_to match(/journal entry/i)
      @course.root_account.update_attribute(:enable_user_notes, true)
      get user_course_teacher_activity_url(@teacher, @course)
      expect(response.body).to match(/journal entry/i)
    end

    it "should show individual user info across courses" do
      @course1 = @course
      @course2 = course(:active_course => true)
      @course2.update_attribute(:name, 'coursename2')
      student_in_course(:course => @course2, :user => @e1.user)
      get user_student_teacher_activity_url(@teacher, @e1.user)
      expect(response).to be_success
      expect(response.body).to match(/studentname1/)
      expect(response.body).not_to match(/studentname2/)
      expect(response.body).to match(/coursename1/)
      # teacher not in course2
      expect(response.body).not_to match(/coursename2/)
      # now put teacher in course2
      @course2.enroll_teacher(@teacher).accept!
      get user_student_teacher_activity_url(@teacher, @e1.user)
      expect(response).to be_success
      expect(response.body).to match(/coursename1/)
      expect(response.body).to match(/coursename2/)
    end

    it "should be available for concluded courses/enrollments" do
      account_admin_user(:username => "admin")
      user_session(@admin)

      @course.complete
      @et.conclude
      @e1.conclude

      get user_student_teacher_activity_url(@teacher, @e1.user)
      expect(response).to be_success
      expect(response.body).to match(/studentname1/)

      get user_course_teacher_activity_url(@teacher, @course)
      expect(response).to be_success
      expect(response.body).to match(/studentname1/)
    end

    it "should show concluded students to active teachers" do
      @e1.conclude

      get user_student_teacher_activity_url(@teacher, @e1.user)
      expect(response).to be_success
      expect(response.body).to match(/studentname1/)

      get user_course_teacher_activity_url(@teacher, @course)
      expect(response).to be_success
      expect(response.body).to match(/studentname1/)
    end

    context "sharding" do
      specs_require_sharding

      it "should show activity for students located on another shard" do
        @shard1.activate do
          @student = user(:name => "im2spoopy4u")
        end
        course_with_student(:course => @course, :user => @student, :active_all => true)

        get user_student_teacher_activity_url(@teacher, @student)
        expect(response).to be_success
        expect(response.body).to include(@student.name)
      end
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
      expect(response).to be_success
      expect(response.body).to match /Olds, JT.*St\. Clair, John/m
    end

    it "should not show any student view students at the account level" do
      course_with_teacher(:active_all => true)
      @fake_student = @course.student_view_student

      site_admin_user(:active_all => true)
      user_session(@admin)

      get account_users_url Account.default.id
      body = Nokogiri::HTML(response.body)
      expect(body.css("#user_#{@fake_student.id}")).to be_empty
      expect(body.at_css('.users').text).not_to match(/Test Student/)
    end
  end

  describe "#show" do
    it "should allow admins to view users in their account" do
      @admin = account_admin_user
      user_session(@admin)

      course
      student_in_course(:course => @course)
      get "/users/#{@student.id}"
      expect(response).to be_success

      course(:account => account_model)
      student_in_course(:course => @course)
      get "/users/#{@student.id}"
      assert_status(401)
    end

    it "should show user to account users that have the view_statistics permission" do
      account_model
      student_in_course(:account => @account)

      role = custom_account_role('custom', :account => @account)
      RoleOverride.create!(:context => @account, :permission => 'view_statistics',
                           :role => role, :enabled => true)
      @account.account_users.create!(user: user, role: role)
      user_session(@user)

      get "/users/#{@student.id}"
      expect(response).to be_success
    end

    it "should show course user to account users that have the read_roster permission" do
      account_model
      student_in_course(:account => @account)
      role = custom_account_role('custom', :account => @account)
      RoleOverride.create!(:context => @account, :permission => 'read_roster',
                           :role => role, :enabled => true)
      @account.account_users.create!(user: user, role: role)
      user_session(@user)

      get "/courses/#{@course.id}/users/#{@student.id}"
      expect(response).to be_success
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
        expect(response).to redirect_to "http://someschool.instructure.com/images/messages/avatar-50.png"

        get "https://otherschool.instructure.com/images/users/#{User.avatar_key(@user.id)}"
        expect(response).to redirect_to "https://otherschool.instructure.com/images/messages/avatar-50.png"
      end
    end

    it "should maintain protocol and domain name in gravatar redirect fallback" do
      enable_cache do
        get "http://someschool.instructure.com/images/users/#{User.avatar_key(@user.id)}"
        expect(response).to redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI::escape("http://someschool.instructure.com/images/messages/avatar-50.png")}"

        get "https://otherschool.instructure.com/images/users/#{User.avatar_key(@user.id)}"
        expect(response).to redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI::escape("https://otherschool.instructure.com/images/messages/avatar-50.png")}"
      end
    end

    it "should forget all cached urls when the avatar changes" do
      enable_cache do
        data = Rails.cache.instance_variable_get(:@data)
        orig_size = data.size

        get "http://someschool.instructure.com/images/users/#{User.avatar_key(@user.id)}"
        expect(response).to redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI::escape("http://someschool.instructure.com/images/messages/avatar-50.png")}"

        diff = data.select{|k,v|k =~ /avatar_img/}.size - orig_size
        expect(diff).to be > 0

        @user.update_attribute(:avatar_image, {'type' => 'attachment', 'url' => '/images/thumbnails/foo.gif'})
        expect(data.select{|k,v|k =~ /avatar_img/}.size).to eq orig_size

        get "http://someschool.instructure.com/images/users/#{User.avatar_key(@user.id)}"
        expect(response).to redirect_to "http://someschool.instructure.com/images/thumbnails/foo.gif"
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
      expect(student_grades.length).to eq 2
      expect(student_grades.text).to match /#{@first_course.name}/
      expect(student_grades.text).to match /#{@course.name}/
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
      expect(response).to be_success
      expect(assigns['pending_other_user']).to eq @admin
      expect(assigns['other_user']).to be_nil

      get user_admin_merge_url(@user, :new_user_id => @admin.id)
      expect(response).to be_success
      expect(assigns['pending_other_user']).to be_nil
      expect(assigns['other_user']).to eq @admin

      post user_merge_url(@user, :new_user_id => @admin.id)
      expect(response).to redirect_to(user_profile_url(@admin))

      expect(@user.reload).to be_deleted
      expect(@admin.reload).to be_registered
      expect(@admin.pseudonyms.count).to eq 2
    end
  end

  context "media_download url" do
    let(:kaltura_client) do
      kaltura_client = mock('CanvasKaltura::ClientV3').responds_like_instance_of(CanvasKaltura::ClientV3)
      CanvasKaltura::ClientV3.stubs(:new).returns(kaltura_client)
      kaltura_client
    end

    let(:media_source_fetcher) {
      media_source_fetcher = mock('MediaSourceFetcher').responds_like_instance_of(MediaSourceFetcher)
      MediaSourceFetcher.expects(:new).with(kaltura_client).returns(media_source_fetcher)
      media_source_fetcher
    }

    before do
      account = Account.create!
      course_with_student(:active_all => true, :account => account)
      user_session(@student)
    end

    it 'should pass the type down to the media fetcher even with a malformed url' do
      media_source_fetcher.expects(:fetch_preferred_source_url).
          with(media_id: 'someMediaId', file_extension: 'mp4', media_type: nil).
          returns('http://example.com/media.mp4')

      # this url actually passes "mp4" into params[:format] instead of params[:type] now
      # but we're going to handle it anyway because we're so nice
      get "/courses/#{@course.id}/media_download.mp4?entryId=someMediaId"
    end
  end
end


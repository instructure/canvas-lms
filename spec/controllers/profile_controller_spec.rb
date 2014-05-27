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

describe ProfileController do
  describe "show" do
    it "should not require an id for yourself" do
      user
      user_session(@user)

      get 'show'
      response.should render_template('profile')
    end

    it "should chain to settings when it's the same user" do
      user
      user_session(@user)

      get 'show', :user_id => @user.id
      response.should render_template('profile')
    end

    it "should require a password session when chaining to settings" do
      user
      user_session(@user)
      session[:used_remember_me_token] = true

      get 'show', :user_id => @user.id
      response.should redirect_to(login_url)
    end
  end

  describe "update" do
    it "should allow changing the default e-mail address and nothing else" do
      user_with_pseudonym(:active_user => true)
      user_session(@user, @pseudonym)
      @cc.position.should == 1
      @cc2 = @user.communication_channels.create!(:path => 'email2@example.com')
      @cc2.position.should == 2
      put 'update', :user_id => @user.id, :default_email_id => @cc2.id, :format => 'json'
      response.should be_success
      @cc2.reload.position.should == 1
      @cc.reload.position.should == 2
    end

    it "should allow changing the default e-mail address and nothing else (name changing disabled)" do
      @account = Account.default
      @account.settings = { :users_can_edit_name => false }
      @account.save!
      user_with_pseudonym(:active_user => true)
      user_session(@user, @pseudonym)
      @cc.position.should == 1
      @cc2 = @user.communication_channels.create!(:path => 'email2@example.com')
      @cc2.position.should == 2
      put 'update', :user_id => @user.id, :default_email_id => @cc2.id, :format => 'json'
      response.should be_success
      @cc2.reload.position.should == 1
      @cc.reload.position.should == 2
    end

    it "should not allow a student view student profile to be edited" do
      course_with_teacher_logged_in(:active_all => true)
      @fake_student = @course.student_view_student
      session[:become_user_id] = @fake_student.id

      put 'update', :user_id => @fake_student.id
      assert_unauthorized
    end
  end

  describe "GET 'communication'" do
    it "should not fail when a user has a notification policy with no notification" do
      # A user might have a NotificationPolicy with no Notification if the policy was created
      # as part of throttling a user's "immediate" messages. Eventually we should fix how that
      # works, but for now we just make sure that that state does not cause an error for the
      # user when they go to their notification preferences.
      user_model
      @user.update_attribute :workflow_state, 'registered'
      user_session(@user)
      cc = @user.communication_channels.create!(:path => 'user@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }
      cc.notification_policies.create!(:notification => nil, :frequency => 'daily')

      get 'communication'
      response.should be_success
    end
  end

  describe "update_profile" do
    before do
      user_with_pseudonym
      @user.register
      # reload to catch the user change
      user_session(@user, @pseudonym.reload)
    end

    it "should let you change your short_name and profile information" do
      put 'update_profile',
          :user => {:short_name => 'Monsturd', :name => 'Jenkins'},
          :user_profile => {:bio => '...', :title => '!!!'},
          :format => 'json'
      response.should be_success

      @user.reload
      @user.short_name.should eql 'Monsturd'
      @user.name.should_not eql 'Jenkins'
      @user.profile.bio.should eql '...'
      @user.profile.title.should eql '!!!'
    end

    it "should not let you change your short_name information if you are not allowed" do
      account = Account.default
      account.settings = { :users_can_edit_name => false }
      account.save!

      old_name = @user.short_name
      old_title = @user.profile.title
      put 'update_profile',
          :user => {:short_name => 'Monsturd', :name => 'Jenkins'},
          :user_profile => {:bio => '...', :title => '!!!'},
          :format => 'json'
      response.should be_success

      @user.reload
      @user.short_name.should eql old_name
      @user.name.should_not eql 'Jenkins'
      @user.profile.bio.should eql '...'
      @user.profile.title.should eql old_title
    end

    it "should let you set visibility on user_services" do
      @user.user_services.create! :service => 'skype', :service_user_name => 'user', :service_user_id => 'user', :visible => true
      @user.user_services.create! :service => 'twitter', :service_user_name => 'user', :service_user_id => 'user', :visible => false

      put 'update_profile',
        :user_profile => {:bio => '...'},
        :user_services => {:twitter => "1", :skype => "false"},
        :format => 'json'
      response.should be_success

      @user.reload
      @user.user_services.find_by_service('skype').visible?.should be_false
      @user.user_services.find_by_service('twitter').visible?.should be_true
    end

    it "should let you set your profile links" do
      put 'update_profile',
        :user_profile => {:bio => '...'},
        :link_urls => ['example.com', 'foo.com', ''],
        :link_titles => ['Example.com', 'Foo', ''],
        :format => 'json'
      response.should be_success

      @user.reload
      @user.profile.links.map { |l| [l.url, l.title] }.should == [
        %w(example.com Example.com),
        %w(foo.com Foo)
      ]
    end
  end
end

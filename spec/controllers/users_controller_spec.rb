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

  it "should filter account users by term" do
    a = Account.default
    u = user(:active_all => true)
    a.add_user(u)
    user_session(@user)
    t1 = a.default_enrollment_term
    t2 = a.enrollment_terms.create!(:name => 'Term 2')

    e1 = course_with_student(:active_all => true)
    c1 = e1.course
    c1.update_attributes!(:enrollment_term => t1)
    e2 = course_with_student(:active_all => true)
    c2 = e2.course
    c2.update_attributes!(:enrollment_term => t2)
    c3 = course_with_student(:active_all => true, :user => e1.user).course
    c3.update_attributes!(:enrollment_term => t1)

    User.update_account_associations(User.all.map(&:id))

    get 'index', :account_id => a.id
    assigns[:users].map(&:id).sort.should == [u, e1.user, c1.teachers.first, e2.user, c2.teachers.first, c3.teachers.first].map(&:id).sort

    get 'index', :account_id => a.id, :enrollment_term_id => t1.id
    assigns[:users].map(&:id).sort.should == [e1.user, c1.teachers.first, c3.teachers.first].map(&:id).sort # 1 student, enrolled twice, and 2 teachers

    get 'index', :account_id => a.id, :enrollment_term_id => t2.id
    assigns[:users].map(&:id).sort.should == [e2.user, c2.teachers.first].map(&:id).sort
  end

  it "should not include deleted courses in manageable courses" do
    course_with_teacher_logged_in(:course_name => "MyCourse1", :active_all => 1)
    course1 = @course
    course1.destroy!
    course_with_teacher(:course_name => "MyCourse2", :user => @teacher, :active_all => 1)
    course2 = @course

    get 'manageable_courses', :user_id => @teacher.id, :term => "MyCourse"
    response.should be_success

    courses = ActiveSupport::JSON.decode(response.body)
    courses.map { |c| c['id'] }.should == [course2.id]
  end

  context "POST 'create'" do
    it "should not allow creating when open_registration is disabled and you're not an admin'" do
      post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
      response.should_not be_success
    end

    context 'open registration' do
      before :each do
        a = Account.default
        a.settings = { :open_registration => true, :no_enrollments_can_create_courses => true }
        a.save!
      end

      it "should create a pre_registered user" do
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
        response.should redirect_to(registered_url)

        p = Pseudonym.find_by_unique_id('jacob@instructure.com')
        p.should be_active
        p.user.should be_pre_registered
        p.user.name.should == 'Jacob Fugal'
        p.user.communication_channels.length.should == 1
        p.user.communication_channels.first.should be_unconfirmed
        p.user.communication_channels.first.path.should == 'jacob@instructure.com'
        p.user.associated_accounts.should == [Account.default]
      end

      it "should complain about conflicting unique_ids" do
        u = User.create! { |u| u.workflow_state = 'registered' }
        p = u.pseudonyms.create!(:unique_id => 'jacob@instructure.com')
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
        assigns[:pseudonym].errors.should_not be_empty
        Pseudonym.find_all_by_unique_id('jacob@instructure.com').should == [p]
      end

      it "should not complain about conflicting ccs, in any state" do
        user1, user2, user3 = User.create!, User.create!, User.create!
        cc1 = user1.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email')
        cc2 = user2.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email') { |cc| cc.workflow_state == 'confirmed' }
        cc3 = user3.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email') { |cc| cc.workflow_state == 'retired' }

        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
        response.should redirect_to(registered_url)

        p = Pseudonym.find_by_unique_id('jacob@instructure.com')
        p.should be_active
        p.user.should be_pre_registered
        p.user.name.should == 'Jacob Fugal'
        p.user.communication_channels.length.should == 1
        p.user.communication_channels.first.should be_unconfirmed
        p.user.communication_channels.first.path.should == 'jacob@instructure.com'
        [cc1, cc2, cc3].should_not be_include(p.user.communication_channels.first)
      end

      it "should re-use 'conflicting' unique_ids if it hasn't been fully registered yet" do
        u = User.create! { |u| u.workflow_state = 'creation_pending' }
        p = Pseudonym.create!(:unique_id => 'jacob@instructure.com', :user => u)
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
        response.should redirect_to(registered_url)

        Pseudonym.find_all_by_unique_id('jacob@instructure.com').should == [p]
        p.reload
        p.should be_active
        p.user.should be_pre_registered
        p.user.name.should == 'Jacob Fugal'
        p.user.communication_channels.length.should == 1
        p.user.communication_channels.first.should be_unconfirmed
        p.user.communication_channels.first.path.should == 'jacob@instructure.com'

        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
        response.should redirect_to(registered_url)

        Pseudonym.find_all_by_unique_id('jacob@instructure.com').should == [p]
        p.reload
        p.should be_active
        p.user.should be_pre_registered
        p.user.name.should == 'Jacob Fugal'
        p.user.communication_channels.length.should == 1
        p.user.communication_channels.first.should be_unconfirmed
        p.user.communication_channels.first.path.should == 'jacob@instructure.com'
      end
    end

    context 'account admin creating users' do
      it "should create a pre_registered user (in the correct account)" do
        account = Account.create!
        user_with_pseudonym(:account => account)
        account.add_user(@user)
        user_session(@user, @pseudonym)
        post 'create', :format => 'json', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
        response.should be_success
        p = Pseudonym.find_by_unique_id('jacob@instructure.com')
        p.account_id.should == account.id
        p.should be_active
        p.user.should be_pre_registered
      end

      it "should notify the user if a merge opportunity arises" do
        notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')

        account = Account.create!
        user_with_pseudonym(:account => account)
        account.add_user(@user)
        user_session(@user, @pseudonym)
        @admin = @user

        u = User.create! { |u| u.workflow_state = 'registered' }
        u.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }
        post 'create', :format => 'json', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :send_confirmation => '0' }, :user => { :name => 'Jacob Fugal' }
        response.should be_success
        p = Pseudonym.find_by_unique_id('jacob@instructure.com')
        Message.find(:first, :conditions => { :communication_channel_id => p.user.email_channel.id, :notification_id => notification.id }).should_not be_nil
      end
    end
  end
end

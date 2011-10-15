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

describe AccountsController do
  def account_with_admin_logged_in(opts = {})
    @account = Account.default
    account_admin_user
    user_session(@admin)
  end

  def cross_listed_course
    account_with_admin_logged_in
    @account1 = Account.create!
    @account1.add_user(@user)
    @course1 = @course
    @course1.account = @account1
    @course1.save!
    @account2 = Account.create!
    @course2 = course
    @course2.account = @account2
    @course2.save!
    @course2.course_sections.first.crosslist_to_course(@course1)
  end

  describe "SIS imports" do
    it "should set batch mode and term if given" do
      account_with_admin_logged_in
      @account.update_attribute(:allow_sis_import, true)
      post 'sis_import_submit', :account_id => @account.id, :import_type => 'instructure_csv_zip', :batch_mode => '1'
      batch = SisBatch.last
      batch.should_not be_nil
      batch.batch_mode.should be_true
      batch.batch_mode_term.should be_nil
      batch.destroy

      post 'sis_import_submit', :account_id => @account.id, :import_type => 'instructure_csv_zip', :batch_mode => '1', :batch_mode_term_id => @account.enrollment_terms.first.id
      batch = SisBatch.last
      batch.should_not be_nil
      batch.batch_mode.should be_true
      batch.batch_mode_term.should == @account.enrollment_terms.first
    end

    it "should set sis stickiness options if given" do
      account_with_admin_logged_in
      @account.update_attribute(:allow_sis_import, true)

      post 'sis_import_submit', :account_id => @account.id,
          :import_type => 'instructure_csv_zip'
      batch = SisBatch.last
      batch.should_not be_nil
      batch.options.should == {}
      batch.destroy

      post 'sis_import_submit', :account_id => @account.id,
          :import_type => 'instructure_csv_zip', :override_sis_stickiness => '1'
      batch = SisBatch.last
      batch.should_not be_nil
      batch.options.should == { :override_sis_stickiness => true }
      batch.destroy

      post 'sis_import_submit', :account_id => @account.id,
          :import_type => 'instructure_csv_zip', :override_sis_stickiness => '1',
          :add_sis_stickiness => '1'
      batch = SisBatch.last
      batch.should_not be_nil
      batch.options.should == { :override_sis_stickiness => true, :add_sis_stickiness => true }
      batch.destroy

      post 'sis_import_submit', :account_id => @account.id,
          :import_type => 'instructure_csv_zip', :override_sis_stickiness => '1',
          :clear_sis_stickiness => '1'
      batch = SisBatch.last
      batch.should_not be_nil
      batch.options.should == { :override_sis_stickiness => true, :clear_sis_stickiness => true }
      batch.destroy

      post 'sis_import_submit', :account_id => @account.id,
          :import_type => 'instructure_csv_zip', :clear_sis_stickiness => '1'
      batch = SisBatch.last
      batch.should_not be_nil
      batch.options.should == {}
      batch.destroy

      post 'sis_import_submit', :account_id => @account.id,
          :import_type => 'instructure_csv_zip', :add_sis_stickiness => '1'
      batch = SisBatch.last
      batch.should_not be_nil
      batch.options.should == {}
      batch.destroy
    end
  end

  describe "managing admins" do
    it "should allow adding a new account admin" do
      account_with_admin_logged_in

      post 'add_account_user', :account_id => @account.id, :admin => { :membership_type => 'AccountAdmin', :email => 'testadmin@example.com' }
      response.should be_redirect

      new_admin = User.find_by_email('testadmin@example.com')
      new_admin.should_not be_nil
      @account.reload
      @account.account_users.map(&:user).should be_include(new_admin)
    end
  end

  it "should redirect to CAS if CAS is enabled" do
    account = account_with_cas({:account => Account.default})
    config = { :cas_base_url => account.account_authorization_config.auth_base }
    cas_client = CASClient::Client.new(config)
    get 'show', :id => account.id
    response.should redirect_to(cas_client.add_service_to_login_url(login_url))
  end

  it "should count total courses correctly" do
    account_with_admin_logged_in
    course
    @course.course_sections.create!
    @course.course_sections.create!
    @course.update_account_associations
    @account.course_account_associations.length.should == 3 # one for each section, and the "nil" section

    get 'show', :id => @account.id, :format => 'html'

    assigns[:associated_courses_count].should == 1
  end
end

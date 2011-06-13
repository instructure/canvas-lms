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
  def account
    @account = @course.account
  end

  def cross_listed_course
    course_with_teacher_logged_in(:active_all => true)
    @account1 = account
    @account1.add_user(@user)
    @course1 = @course
    @course1.account = @account1
    @course1.save!
    @account2 = account
    @course2 = course
    @course2.account = @account2
    @course2.save!
    @course2.course_sections.first.crosslist_to_course(@course1)
    @course1.update_account_associations
    @course2.update_account_associations
  end

  describe "SIS imports" do
    it "should set batch mode and term if given" do
      course_with_teacher_logged_in(:active_all => true)
      @account = account
      @account.update_attribute(:allow_sis_import, true)
      @account.add_user(@user)
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
  end

  it "should redirect to CAS if CAS is enabled" do
    account = account_with_cas({:account => Account.default})
    config = { :cas_base_url => account.account_authorization_config.auth_base }
    cas_client = CASClient::Client.new(config)
    get 'show', :id => account.id
    response.should redirect_to(cas_client.add_service_to_login_url(login_url))
  end
end

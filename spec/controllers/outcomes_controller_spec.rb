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

describe OutcomesController do
  def context_outcome(context)
    @outcome_group ||= context.root_outcome_group
    @outcome = context.created_learning_outcomes.create!(:title => 'outcome')
    @outcome_group.add_outcome(@outcome)
  end
  
  def course_outcome
    context_outcome(@course)
  end
  
  def account_outcome
    context_outcome(@account)
  end

  describe "GET 'index'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      get 'index', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should redirect 'disabled', if disabled by the teacher" do
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:tab_configuration, [{'id'=>15,'hidden'=>true}])
      get 'index', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      get 'index', :course_id => @course.id
      response.should be_success
    end
    
    it "should work in accounts" do
      @account = Account.default
      account_admin_user
      user_session(@user)
      account_outcome
      get 'index', :account_id => @account.id
    end

    it "should find a common core group from settings" do
      @account = Account.default
      account_admin_user
      user_session(@user)
      account_outcome
      Setting.set(AcademicBenchmark.common_core_setting_key, @outcome_group.id)
      get 'index', :account_id => @account.id
      assigns[:js_env][:COMMON_CORE_GROUP_ID].should == @outcome_group.id
    end
  end

  describe "GET 'show'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_outcome
      get 'show', :course_id => @course.id, :id => @outcome.id
      assert_unauthorized
    end
    
    it "should not allow students to view outcomes" do
      course_with_student_logged_in(:active_all => true)
      course_outcome
      get 'show', :course_id => @course.id, :id => @outcome.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      course_outcome
      get 'show', :course_id => @course.id, :id => @outcome.id
      response.should be_success
    end
    
    it "should work in accounts" do
      @account = Account.default
      account_admin_user
      user_session(@user)
      account_outcome
      get 'show', :account_id => @account.id, :id => @outcome.id
      response.should be_success
    end
    
    it "should include tags from courses when viewed in the account" do
      course
      @account = @course.account

      account_outcome
      @outcome

      quiz = @course.quizzes.create!
      alignment = @outcome.align(quiz, @course)

      account_admin_user(:account => @account)
      user_session(@user)
      get 'show', :account_id => @account.id, :id => @outcome.id

      assigns[:alignments].any?{ |a| a.id == alignment.id }.should be_true
    end

    it "should not allow access to individual outcomes for large_roster courses" do
      course
      course_outcome

      @course.large_roster = true
      @course.save!

      get 'show', :course_id => @course.id, :id => @outcome.id
      response.response_code.should == 302 # requests are redirected for large_roster courses
    end
  end

  describe "GET 'detail'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_outcome
      get 'details', :course_id => @course.id, :outcome_id => @outcome.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      course_outcome
      get 'details', :course_id => @course.id, :outcome_id => @outcome.id
      response.should be_success
    end
    
    it "should work in accounts" do
      @account = Account.default
      account_admin_user
      user_session(@user)
      account_outcome
      get 'details', :account_id => @account.id, :outcome_id => @outcome.id
    end
  end

  describe "GET 'list'" do
    it "should list account outcomes for an account context" do
      @account = Account.default
      account_admin_user
      account_outcome

      user_session(@user)
      get 'list', :account_id => @account.id
      response.should be_success
      data = json_parse
      data.should_not be_empty
    end

    it "should list account outcomes for a subaccount context" do
      @account = Account.default
      account_admin_user
      account_outcome
      sub_account_1 = @account.sub_accounts.create!

      user_session(@user)
      get 'list', :account_id => sub_account_1.id
      response.should be_success
      data = json_parse
      data.should_not be_empty
    end

    it "should list account outcomes for a course context" do
      @account = Account.default
      account_admin_user
      account_outcome

      course_with_teacher_logged_in
      get 'list', :course_id => @course.id
      response.should be_success
      data = json_parse
      data.should_not be_empty
    end
  end
end

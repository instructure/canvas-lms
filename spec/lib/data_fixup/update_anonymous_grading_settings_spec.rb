#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'spec_helper'

describe DataFixup::UpdateAnonymousGradingSettings do
  before(:once) do
    account_model
    course_factory(account: @account, active_all: true)
    assignment_model(course: @course, workflow_state: 'published', anonymous_grading: false)
  end

  def run_for_course(course: @course)
    DataFixup::UpdateAnonymousGradingSettings.run_for_courses_in_range(course.id, course.id)
  end

  def run_for_account(account: @account)
    DataFixup::UpdateAnonymousGradingSettings.run_for_accounts_in_range(account.id, account.id)
  end

  def destroy_allowed_and_off_flags
    DataFixup::UpdateAnonymousGradingSettings.destroy_allowed_and_off_flags
  end

  def set_anonymous_grading_flag(course_or_account:, state: 'on')
    # Manually build the old flag for testing because this patchset also
    # removes the definition of the flag.
    anonymous_grading_flag = course_or_account.feature_flags.where(feature: :anonymous_grading).first_or_initialize
    anonymous_grading_flag.state = state
    anonymous_grading_flag.save!(validate: false)
  end

  describe 'UpdateAnonymousGradingSettings::run_for_accounts_in_range' do
    context 'for an account with anonymous_grading enabled' do
      before(:each) do
        set_anonymous_grading_flag(course_or_account: @account)
      end

      it 'removes the flag on the account' do
        run_for_account
        expect(@course.feature_flag(:anonymous_grading)).to be nil
      end

      it 'enables the anonymous_marking flag on the account' do
        run_for_account
        expect(@course).to be_feature_enabled(:anonymous_marking)
      end

      it 'enables anonymous grading for assignments in courses belonging to the account' do
        run_for_account
        @assignment.reload
        expect(@assignment).to be_anonymous_grading
      end

      it 'enables anonymous grading for assignments in courses in sub-accounts' do
        subaccount = Account.create!(parent_account: @account)
        subaccount_course = Course.create!(account: subaccount, workflow_state: 'available')
        assignment = subaccount_course.assignments.create!(
          anonymous_grading: false,
          title: 'hi :)',
          workflow_state: 'published'
        )

        run_for_account

        assignment.reload
        expect(assignment).to be_anonymous_grading
      end
    end

    it 'does nothing for an account with anonymous_grading set to allowed' do
      set_anonymous_grading_flag(course_or_account: @account, state: 'allowed')
      run_for_account
      expect(@account.feature_flag(:anonymous_grading)).to be_allowed
    end

    it 'does nothing for an account with anonymous_grading disabled' do
      set_anonymous_grading_flag(course_or_account: @account, state: 'off')
      run_for_account
      expect(@account.feature_flag(:anonymous_grading)).not_to be_enabled
    end
  end

  describe 'UpdateAnonymousGradingSettings::run_for_courses_in_range' do
    context 'for a course with anonymous_grading enabled' do
      before(:each) do
        set_anonymous_grading_flag(course_or_account: @course, state: 'on')
      end

      it 'removes the flag on the course' do
        run_for_course
        expect(@course.feature_flag(:anonymous_grading)).to be nil
      end

      it 'enables the anonymous_marking flag on the course' do
        run_for_course
        expect(@course).to be_feature_enabled(:anonymous_marking)
      end

      it 'enables anonymous grading for assignments in the course' do
        @assignment.update!(anonymous_grading: false)
        run_for_course
        @assignment.reload
        expect(@assignment).to be_anonymous_grading
      end
    end

    it 'does nothing for a course with anonymous_grading disabled' do
      set_anonymous_grading_flag(course_or_account: @course, state: 'off')
      run_for_course
      expect(@course.feature_flag(:anonymous_grading).state).to eq 'off'
    end
  end

  describe 'UpdateAnonymousGradingSettings::destroy_allowed_and_off_flags' do
    it 'removes the anonymous_grading feature flag for an account with the flag set to allowed' do
      set_anonymous_grading_flag(course_or_account: @account, state: 'allowed')
      destroy_allowed_and_off_flags
      expect(@account.feature_flag(:anonymous_grading)).to be nil
    end

    it 'removes the anonymous_grading feature flag for an account with the flag set to off' do
      set_anonymous_grading_flag(course_or_account: @account, state: 'off')
      destroy_allowed_and_off_flags
      expect(@account.feature_flag(:anonymous_grading)).to be nil
    end

    it 'ignores the anonymous_grading feature flag for an account with the flag set to on' do
      set_anonymous_grading_flag(course_or_account: @account, state: 'on')
      destroy_allowed_and_off_flags
      expect(@account.feature_flag(:anonymous_grading)).to be_enabled
    end
  end
end

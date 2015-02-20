#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe GradingPeriod do
  before :once do
    @grading_period = GradingPeriod.create(course_id: 1, start_date: Time.zone.now, end_date: 1.day.from_now)
  end

  describe "validation" do
    it "should be valid with appropriate input" do
      expect(@grading_period).to be_valid
    end

    it "should require a start_date" do
      expect(GradingPeriod.create(course_id: 1, end_date: 1.day.from_now)).to_not be_valid
    end

    it "should require an end_date" do
      expect(GradingPeriod.create(course_id: 1, start_date: Time.zone.now)).to_not be_valid
    end

    context "when end_date is before the start_date" do
      it "should not be able to create a grading period with end_date before the start_date" do
        expect(GradingPeriod.create(course_id: 1, start_date: 2.days.from_now, end_date: Time.zone.now)).to_not be_valid
      end

      it "should not be able to update the end_date to be before the start_date" do
        grading_period = GradingPeriod.create(course_id: 1, start_date: Time.zone.now, end_date: 1.day.from_now)
        expect(grading_period).to be_valid
        grading_period.update_attributes(end_date: 1.day.ago)
        expect(grading_period).not_to be_valid
      end

      it "should not be able to update the start_date to be after the end_date" do
        grading_period = GradingPeriod.create(course_id: 1, start_date: Time.zone.now, end_date: 1.day.from_now)
        expect(grading_period).to be_valid
        grading_period.update_attributes(start_date: 2.days.from_now)
        expect(grading_period).not_to be_valid
      end
    end
  end

  describe '#destroy' do
    it 'soft deletes' do
      @grading_period.destroy
      expect(@grading_period).to be_deleted
      expect(@grading_period).to_not be_destroyed
    end
  end

  describe '#assignments' do
    before :once do
      course_with_teacher active_all: true
      @gp1, @gp2 = grading_periods count: 2
      @a1, @a2 = [@gp1, @gp2].map { |gp|
        @course.assignments.create! due_at: gp.start_date + 1
      }
      # no due date goes in final grading period
      @a3 = @course.assignments.create!
    end

    it 'filters assignments for grading period' do
      expect(@gp1.assignments(@course.assignments)).to eq [@a1]
      expect(@gp2.assignments(@course.assignments)).to eq [@a2, @a3]
    end
  end

  describe "permissions:" do
    context "course belonging to root account" do
      before(:once) do
        @root_account = Account.default
        @sub_account = @root_account.sub_accounts.create!
        course_with_teacher(account: @root_account, active_all: true)
        course_with_student(course: @course, active_all: true)
        @root_account_period = grading_periods(context: @root_account, count: 1).first
        @sub_account_period = grading_periods(context: @sub_account, count: 1).first
        @course_period = grading_periods(context: @course, count: 1).first
      end

      context "root-account admin" do
        before(:once) do
          account_admin_user(account: @root_account)
        end

        it "should be able to read and manage root-account level grading periods" do
          expect(@root_account_period.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end

        it "should be able to read and manage sub-account level grading periods" do
          expect(@sub_account_period.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end

        it "should be able to read and manage course level grading periods" do
          expect(@course_period.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end
      end

      context "sub-account admin" do
        before(:once) do
          account_admin_user(account: @sub_account)
        end

        it "should NOT be able to manage root-account level grading periods, but should be able to read them" do
          expect(@root_account_period.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should be able to read and manage sub-account level grading periods" do
          expect(@sub_account_period.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end


        it "should NOT be able to read or manage course level grading periods, when the course is under the root-account" do
          expect(@course_period.rights_status(@admin, :read, :manage)).to eq({ read: false, manage: false })
        end
      end

      context "teacher" do
        it "should NOT be able to manage root-account level grading periods, but should be able to read them" do
          expect(@root_account_period.rights_status(@teacher, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should NOT be able to read or manage sub-account level grading period" do
          expect(@sub_account_period.rights_status(@teacher, :read, :manage)).to eq({ read: false, manage: false })
        end

        it "should be able to read and manage course level grading periods" do
          expect(@course_period.rights_status(@teacher, :read, :manage)).to eq({ read: true, manage: true})
        end
      end

      context "student" do
        it "should NOT be able to manage root-account level grading periods, but should be able to read them" do
          expect(@root_account_period.rights_status(@student, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should NOT be able to read or manage sub-account level grading period" do
          expect(@sub_account_period.rights_status(@student, :read, :manage)).to eq({ read: false, manage: false })
        end

        it "should NOT be able to manage course level grading periods, but should be able to read them" do
          expect(@course_period.rights_status(@student, :read, :manage)).to eq({ read: true, manage: false})
        end
      end

      context "multiple grading periods feature flag turned off" do
        before(:once) do
          account_admin_user(account: @root_account)
          @root_account.disable_feature! :multiple_grading_periods
        end

        it "should return false for all permissions" do
          expect(@course_period.rights_status(@admin, :read, :manage)).to eq({ read: false, manage: false })
        end
      end
    end
    context "course belonging to sub-account" do
      before(:once) do
        @root_account = Account.default
        @sub_account = @root_account.sub_accounts.create!
        course_with_teacher(account: @sub_account, active_all: true)
        course_with_student(course: @course, active_all: true)
        @root_account_period = grading_periods(context: @root_account, count: 1).first
        @sub_account_period = grading_periods(context: @sub_account, count: 1).first
        @course_period = grading_periods(context: @course, count: 1).first
      end

      context "root-account admin" do
        before(:once) do
          account_admin_user(account: @root_account)
        end

        it "should be able to read and manage root-account level grading periods" do
          expect(@root_account_period.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end

        it "should be able to read and manage sub-account level grading periods" do
          expect(@sub_account_period.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end


        it "should be able to read and manage course level grading periods" do
          expect(@course_period.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end
      end

      context "sub-account admin" do
        before(:once) do
          account_admin_user(account: @sub_account)
        end

        it "should NOT be able to manage root-account level grading periods, but should be able to read them" do
          expect(@root_account_period.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should be able to read and manage sub-account level grading periods" do
          expect(@sub_account_period.rights_status(@admin, :read, :manage)).to eq({read: true, manage: true })
        end


        it "should be able to read and manage course level grading periods, when the course is under the sub-account" do
          expect(@course_period.rights_status(@admin, :read, :manage)).to eq({read: true, manage: true })
        end
      end

      context "teacher" do
        it "should NOT be able to manage root-account level grading periods, but should be able to read them" do
          expect(@root_account_period.rights_status(@teacher, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should NOT be able to manage sub-account level grading periods, but should be able to read them" do
          expect(@sub_account_period.rights_status(@teacher, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should be able to read and manage course level grading periods" do
          expect(@course_period.rights_status(@teacher, :read, :manage)).to eq({ read: true, manage: true })
        end
      end

      context "student" do
        it "should NOT be able to manage root-account level grading periods, but should be able to read them" do
          expect(@root_account_period.rights_status(@student, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should NOT be able to manage sub-account level grading periods, but should be able to read them" do
          expect(@sub_account_period.rights_status(@student, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should NOT be able to manage course level grading periods, but should be able to read them" do
          expect(@course_period.rights_status(@student, :read, :manage)).to eq({ read: true, manage: false})
        end
      end

      context "multiple grading periods feature flag turned off" do
        before(:once) do
          account_admin_user(account: @sub_account)
          @root_account.disable_feature! :multiple_grading_periods
        end

        it "should return false for all permissions" do
          expect(@course_period.rights_status(@admin, :read, :manage)).to eq({ read: false, manage: false })
        end
      end
    end
  end
end

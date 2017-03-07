#
# Copyright (C) 2014-2016 Instructure, Inc.
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

require_relative '../spec_helper'

describe GradingPeriodGroup do
  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }
  let(:valid_attributes) { { title: "A Title" } }

  let(:account) { Account.default }

  # after dev lands in master, re add this title validation
  # it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to belong_to(:course) }
  it { is_expected.to have_many(:enrollment_terms).inverse_of(:grading_period_group) }
  it { is_expected.to have_many(:grading_periods).dependent(:destroy) }

  describe ".for" do
    context "when given a root account" do
      it "fetches sets on a root account" do
        set = account.grading_period_groups.create!(valid_attributes)
        sets = GradingPeriodGroup.for(account)
        expect(sets.count).to eql 1
        expect(sets).to include set
      end

      it "uses the root account when given sub accounts" do
        set = account.grading_period_groups.create!(valid_attributes)
        sub_account = account.sub_accounts.create!
        sets = GradingPeriodGroup.for(sub_account)
        expect(sets.count).to eql 1
        expect(sets).to include set
      end
    end

    context "when given a course" do
      it "is expected to fail" do
        course = account.courses.create!
        expect {
          GradingPeriodGroup.for(course)
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.for_course' do
    before(:once) do
      @course = account.courses.create!
    end

    it 'returns the set associated with the course' do
      set = account.grading_period_groups.create!(valid_attributes)
      set.enrollment_terms << @course.enrollment_term
      expect(GradingPeriodGroup.for_course(@course)).to eq(set)
    end

    it 'returns nil if no set is associated with the course' do
      expect(GradingPeriodGroup.for_course(@course)).to be_nil
    end

    it 'returns nil if the associated set is soft-deleted' do
      set = account.grading_period_groups.create!(valid_attributes)
      set.enrollment_terms << @course.enrollment_term
      set.destroy
      expect(GradingPeriodGroup.for_course(@course)).to be_nil
    end

    context 'legacy grading periods support' do
      before(:once) do
        @set = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)
      end

      it 'returns the set associated with the course' do
        expect(GradingPeriodGroup.for_course(@course)).to eq(@set)
      end

      it 'returns nil if the associated set is soft-deleted' do
        @set.destroy
        expect(GradingPeriodGroup.for_course(@course)).to be_nil
      end
    end
  end

  describe "validation" do
    let(:group) { GradingPeriodGroup.new valid_attributes }

    it "is valid with an account" do
      group = account.grading_period_groups.build(title: "Example Group")
      expect(group).to be_valid
    end

    it "is valid with a course" do
      course = Course.create!(account: Account.default)
      group = course.grading_period_groups.build(title: "Example Group")
      expect(group).to be_valid
    end

    it "is not valid with a sub-account" do
      sub_account = account.sub_accounts.create!
      group = sub_account.grading_period_groups.build(title: "Example Group")
      expect(group).not_to be_valid
    end

    it "is not valid with only an enrollment term" do
      group.enrollment_terms << account.enrollment_terms.create!
      expect(group).not_to be_valid
    end

    it "is not valid without an account or a course" do
      expect(group).not_to be_valid
    end

    it "cannot be created for a soft-deleted account" do
      account.update_attribute(:workflow_state, 'deleted')
      group = account.grading_period_groups.build(title: "Example Group")
      expect(group).not_to be_valid
    end

    it "cannot be created for a soft-deleted course" do
      course = Course.create!(account: Account.default)
      course.update_attribute(:workflow_state, 'deleted')
      group = course.grading_period_groups.build(title: "Example Group")
      expect(group).not_to be_valid
    end

    it "can belong to a soft-deleted account when also soft-deleted" do
      group = group_helper.create_for_account(account)
      account.update_attribute(:workflow_state, 'deleted')
      group.reload
      expect(group).not_to be_valid
      group.workflow_state = 'deleted'
      expect(group).to be_valid
    end

    it "can belong to a soft-deleted course when also soft-deleted" do
      course = Course.create!(account: Account.default)
      group = group_helper.legacy_create_for_course(course)
      course.update_attribute(:workflow_state, 'deleted')
      group.reload
      expect(group).not_to be_valid
      group.workflow_state = 'deleted'
      expect(group).to be_valid
    end
  end

  it_behaves_like "soft deletion" do
    let(:course) { Course.create!(account: account) }
    let(:creation_arguments) { {title: "A title"} }
    subject { course.grading_period_groups }
  end

  describe "deletion" do
    let(:account) { Account.default }
    let(:term_1)  { account.enrollment_terms.create! }
    let(:term_2)  { account.enrollment_terms.create! }
    let(:group)   { group_helper.create_for_account(account) }

    it "removes associations from related enrollment terms" do
      group.enrollment_terms = [term_1, term_2]
      expect(term_1.reload.grading_period_group).to eql group
      expect(term_2.reload.grading_period_group).to eql group
      group.destroy
      expect(term_1.reload.grading_period_group).to be_nil
      expect(term_2.reload.grading_period_group).to be_nil
    end

    it "removes associations from soft-deleted enrollment terms" do
      group.enrollment_terms = [term_1, term_2]
      term_1.destroy
      expect(term_1.reload.grading_period_group).to eql group
      expect(term_2.reload.grading_period_group).to eql group
      group.destroy
      expect(term_1.reload.grading_period_group).to be_nil
      expect(term_2.reload.grading_period_group).to be_nil
    end
  end

  describe "permissions" do
    let(:permissions) { [:read, :create, :update, :delete] }

    context "course belonging to root account" do
      before :once do
        @root_account = Account.default
        @sub_account = @root_account.sub_accounts.create!
        course_with_teacher(account: @root_account, active_all: true)
        course_with_student(course: @course, active_all: true)
        @root_account_group = group_helper.create_for_account(@root_account)
        @course_group = group_helper.legacy_create_for_course(@course)
      end

      context "root-account admin" do
        before :once do
          account_admin_user(account: @root_account)
          @root_account_admin = @admin
        end

        it "can read, create, update, and delete root-account " \
          "grading period groups" do
          expect(@root_account_group.rights_status(@root_account_admin, *permissions)).to eq({
            read:   true,
            create: true,
            update: true,
            delete: true
          })
        end

        it "can read, update, and delete but NOT create course level " \
          "grading period groups" do
          expect(@course_group.rights_status(@root_account_admin, *permissions)).to eq({
            read:   true,
            create: false,
            update: true,
            delete: true
          })
        end
      end

      context "sub-account admin" do
        before(:once) do
          account_admin_user(account: @sub_account)
          @sub_account_admin = @admin
        end

        it "can read but NOT create, update, not delete root-account " \
          "grading period groups", priority: "1", test_id: 2528644  do
          expect(@root_account_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "cannot read, create, update, delete course " \
          "grading period groups, when the course is under a root-account" do
          expect(@course_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   false,
            create: false,
            update: false,
            delete: false
          })
        end
      end

      context "teacher" do
        it "can read but NOT create, update, nor delete root-account " \
          "grading period groups", priority: "1", test_id: 2528645 do
          expect(@root_account_group.
            rights_status(@teacher, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can read, update, and delete but NOT create course " \
          "grading period groups" do
          expect(@course_group.
            rights_status(@teacher, *permissions)).to eq({
            read:   true,
            create: false,
            update: true,
            delete: true
          })
        end
      end

      context "student" do
        it "can only read root account grading period groups" do
          expect(@root_account_group.
            rights_status(@student, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can only read course grading period groups" do
          expect(@course_group.
            rights_status(@student, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end
      end
    end

    context "course belonging to sub-account" do
      before(:once) do
        @root_account = Account.default
        @sub_account = @root_account.sub_accounts.create!
        course_with_teacher(account: @sub_account, active_all: true)
        course_with_student(course: @course, active_all: true)
        @root_account_group = group_helper.create_for_account(@root_account)
        @course_group = group_helper.legacy_create_for_course(@course)
      end

      context "root-account admin" do
        before(:once) do
          account_admin_user(account: @root_account)
          @root_account_admin = @admin
        end

        it "can read, create, update, and delete root-account " \
          "grading period groups" do
          expect(@root_account_group.
            rights_status(@root_account_admin, *permissions)).to eq({
            read:   true,
            create: true,
            update: true,
            delete: true
          })
        end

        it "can read, update, and destroy but NOT create course " \
          "grading period groups" do
          expect(@course_group.
            rights_status(@root_account_admin, *permissions)).to eq({
            read:   true,
            create: false,
            update: true,
            delete: true
          })
        end
      end

      context "sub-account admin" do
        before(:once) do
          account_admin_user(account: @sub_account)
          @sub_account_admin = @admin
        end

        it "can only read root-account grading period groups" do
          expect(@root_account_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can read, update, and delete but NOT create course grading " \
          "period groups when the course is under the sub-account" do
          expect(@course_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   true,
            create: false,
            update: true,
            delete: true
          })
        end
      end

      context "teacher" do
        it "can only read root-account grading period groups" do
          expect(@root_account_group.
            rights_status(@teacher, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can read, update and delete but NOT create course " \
          "grading period groups" do
          expect(@course_group.
            rights_status(@teacher, *permissions)).to eq({
            read:   true,
            create: false,
            update: true,
            delete: true
          })
        end
      end

      context "student" do
        it "can only read root-account grading period groups" do
          expect(@root_account_group.
            rights_status(@student, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can only read sub-account grading period groups" do
          expect(@course_group.
            rights_status(@student, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end
      end
    end
  end

  describe 'computation of course scores' do
    before(:once) do
      @grading_period_set = account.grading_period_groups.create!(valid_attributes)
      term = account.enrollment_terms.create!
      @grading_period_set.enrollment_terms << term
      account.courses.create!(enrollment_term: term)
    end

    it 'recomputes course scores when the weighted attribute is changed' do
      Enrollment.expects(:recompute_final_score).once
      @grading_period_set.update!(weighted: true)
    end

    it 'does not recompute course scores when the weighted attribute is not changed' do
      Enrollment.expects(:recompute_final_score).never
      @grading_period_set.update!(title: 'The Best Set')
    end
  end
end

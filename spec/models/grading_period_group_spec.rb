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

  # after dev lands in master, re add this title validation
  # it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to belong_to(:course) }
  it { is_expected.to have_many(:enrollment_terms).inverse_of(:grading_period_group) }
  it { is_expected.to have_many(:grading_periods).dependent(:destroy) }

  it { is_expected.to allow_mass_assignment_of(:title) }

  describe ".for" do
    context "given a root account" do
      let(:root_account) { Account.default }
      context "given a set with a term" do
        let(:term) { root_account.enrollment_terms.first }
        let!(:grading_period_set) do
          GradingPeriodGroup.create!(valid_attributes) do |set|
            set.enrollment_terms << term
          end
        end

        it "fetches sets via enrollment terms" do
          sets = GradingPeriodGroup.for(root_account)
          expect(sets.count).to eql 1
          expect(sets).to include grading_period_set
        end

        context "given a sub account" do
          let(:sub_account) { root_account.sub_accounts.create! }
          it "fetches sets on the root account" do
            sets = GradingPeriodGroup.for(sub_account)
            expect(sets.count).to eql 1
            expect(sets).to include grading_period_set
          end
        end
      end
    end

    context "given a course" do
      let(:course) { root_account.courses.create! }
      it "is expected to fail" do
        expect {
          GradingPeriodGroup.for(course)
        }.to raise_error
      end
    end
  end

  describe "validation" do
    let(:account) { Account.default }
    let(:group) { GradingPeriodGroup.new valid_attributes }
    let(:enrollment_term) { account.enrollment_terms.create! }

    it "is valid with only an active enrollment term" do
      group.enrollment_terms << enrollment_term
      expect(group).to be_valid
    end

    it "is valid with a course" do
      course = Course.create!(account: Account.default)
      group = course.grading_period_groups.build(title: 'a group on a course')
      expect(group).to be_valid
    end

    it "is not valid without a course or an enrollment term" do
      expect(group).not_to be_valid
    end

    it "is not valid with enrollment terms associated with different accounts" do
      account_1 = account_model
      account_2 = account_model
      term_1 = account_1.enrollment_terms.create!
      term_2 = account_2.enrollment_terms.create!
      group.enrollment_terms << term_1
      group.enrollment_terms << term_2
      expect(group).not_to be_valid
    end

    it "is valid with only deleted enrollment terms and is deleted" do
      enrollment_term.destroy
      group.enrollment_terms << enrollment_term
      group.workflow_state = 'deleted'
      expect(group).to be_valid
    end

    it "is not valid with only deleted enrollment terms and not deleted" do
      enrollment_term.destroy
      group.enrollment_terms << enrollment_term
      expect(group).not_to be_valid
    end

    it "is not valid with enrollment terms with different accounts and workflow states" do
      account_1 = account_model
      account_2 = account_model
      term_1 = account_1.enrollment_terms.create!
      term_2 = account_2.enrollment_terms.create!
      term_2.destroy
      group.enrollment_terms << term_1
      group.enrollment_terms << term_2
      expect(group).not_to be_valid
    end

    it "is not able to mass-assign the course id" do
      course = course()
      grading_period_group = GradingPeriodGroup.new(valid_attributes.merge(course_id: course.id))
      expect(grading_period_group.course_id).to be_nil
      expect(grading_period_group.course).to be_nil
    end
  end

  describe "#save" do
    let(:account) { Account.default }

    it "associates with the account of a related enrollment term" do
      term_1 = account.enrollment_terms.create!
      term_2 = account.enrollment_terms.create!
      group = group_helper.create_for_enrollment_term(term_1)
      group.enrollment_terms = [term_1, term_2]
      expect(group.reload.account_id).to eql(account.id)
    end

    it "preserves account_id when dissociating from an enrollment term" do
      term_1 = account.enrollment_terms.create!
      term_2 = account.enrollment_terms.create!
      group = group_helper.create_for_enrollment_term(term_1)
      group.enrollment_terms = [term_1, term_2]
      group.destroy
      expect(group.reload.account_id).to eql(account.id)
    end

    it "does not associate the account when already associated with a course" do
      course = account.courses.create!
      term = account.enrollment_terms.create!
      group = group_helper.create_for_course(course)
      group.enrollment_terms << term
      group.save
      expect(group.account_id).to be_nil
    end

    it "deletes orphaned grading period groups" do
      term_1 = account.enrollment_terms.create!
      group_1 = group_helper.create_for_enrollment_term(term_1)
      term_2 = account.enrollment_terms.create!
      group_2 = GradingPeriodGroup.new valid_attributes
      group_2.enrollment_terms.concat([term_1, term_2])
      group_2.save!
      expect(group_1.reload).to be_deleted
    end
  end

  describe "#multiple_grading_periods_enabled?" do
    let(:account) { Account.default }

    context "when associated with an enrollment term" do
      let(:term) { account.enrollment_terms.create! }
      let(:group) { group_helper.create_for_enrollment_term(term) }

      it "returns false if the multiple grading periods feature flag has not been enabled" do
        expect(group.multiple_grading_periods_enabled?).to eq(false)
      end

      it "returns true if the multiple grading periods feature flag has been enabled" do
        account.enable_feature!(:multiple_grading_periods)
        expect(group.multiple_grading_periods_enabled?).to eq(true)
      end
    end

    context "when associated with a course" do
      let(:course) { Course.create!(account: account) }
      let(:group) { group_helper.create_for_course(course) }

      it "returns false if the multiple grading periods feature flag has not been enabled" do
        expect(group.multiple_grading_periods_enabled?).to eq(false)
      end

      it "returns true if the multiple grading periods feature flag has been enabled" do
        course.root_account.enable_feature!(:multiple_grading_periods)
        expect(group.multiple_grading_periods_enabled?).to eq(true)
      end
    end
  end

  it_behaves_like "soft deletion" do
    let(:account) { Account.create! }
    let(:course) { Course.create!(account: account) }
    let(:creation_arguments) { {title: "A title"} }
    subject { course.grading_period_groups }
  end

  describe "deletion" do
    let(:account) { Account.default }
    let(:term_1)  { account.enrollment_terms.create! }
    let(:term_2)  { account.enrollment_terms.create! }
    let(:group)   { group_helper.create_for_enrollment_term(term_1) }

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
        @root_account.enable_feature!(:multiple_grading_periods)
        @sub_account = @root_account.sub_accounts.create!
        course_with_teacher(account: @root_account, active_all: true)
        course_with_student(course: @course, active_all: true)
        root_account_term = @root_account.enrollment_terms.create!
        sub_account_term = @sub_account.enrollment_terms.create!
        @root_account_group = group_helper.create_for_enrollment_term(root_account_term)
        @sub_account_group = group_helper.create_for_enrollment_term(sub_account_term)
        @course_group = group_helper.create_for_course(@course)
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

        it "can read, create, update, and delete sub-account " \
          "grading period groups" do
          expect(@sub_account_group.rights_status(@root_account_admin, *permissions)).to eq({
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
          "grading period groups" do
          expect(@root_account_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can read, create, update, and delete sub-account " \
          "grading period groups" do
          expect(@sub_account_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   true,
            create: true,
            update: true,
            delete: true
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
          "grading period groups" do
          expect(@root_account_group.
            rights_status(@teacher, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "cannot read, create, update, nor delete sub-account " \
          "grading period groups" do
          expect(@sub_account_group.
            rights_status(@teacher, *permissions)).to eq({
            read:   false,
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

        it "cannot read, create, update, nor delete sub-account " \
          "grading period groups" do
          expect(@sub_account_group.
            rights_status(@student, *permissions)).to eq({
            read:   false,
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

      context "multiple grading periods feature flag turned off" do
        before(:once) do
          account_admin_user(account: @root_account)
          @root_account_admin = @admin
          @root_account.disable_feature! :multiple_grading_periods
        end

        it "cannot do anything with grading period groups" do
          expect(@course_group.
            rights_status(@root_account_admin, *permissions)).to eq({
            read:   false,
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
        @root_account.enable_feature!(:multiple_grading_periods)
        @sub_account = @root_account.sub_accounts.create!
        course_with_teacher(account: @sub_account, active_all: true)
        course_with_student(course: @course, active_all: true)
        root_account_term = @root_account.enrollment_terms.create!
        sub_account_term = @sub_account.enrollment_terms.create!
        @root_account_group = group_helper.create_for_enrollment_term(root_account_term)
        @sub_account_group = group_helper.create_for_enrollment_term(sub_account_term)
        @course_group = group_helper.create_for_course(@course)
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

        it "can read, create, update, and delete sub-account " \
          "grading period groups" do
          expect(@sub_account_group.
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

        it "can read, create, update, and delete sub-account " \
          "grading period groups" do
          expect(@sub_account_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   true,
            create: true,
            update: true,
            delete: true
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

        it "can only read sub-account grading period groups" do
          expect(@sub_account_group.
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
          expect(@sub_account_group.
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

      context "multiple grading periods feature flag turned off" do
        before(:once) do
          account_admin_user(account: @sub_account)
          @sub_account_admin = @admin
          @root_account.disable_feature! :multiple_grading_periods
        end

        it "cannot do anything with course grading period groups" do
          expect(@course_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   false,
            create: false,
            update: false,
            delete: false
          })
        end
      end
    end
  end
end

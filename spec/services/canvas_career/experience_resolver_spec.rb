# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module CanvasCareer
  describe ExperienceResolver do
    before :once do
      @root_account = Account.default
      @root_account.enable_feature!(:horizon_course_setting)

      @career_subaccount = @root_account.sub_accounts.create!
      @career_subaccount.horizon_account = true
      @career_subaccount.save!
      @root_account.reload

      @course_academic = course_model(account: @root_account)
      @course_career = course_model(account: @career_subaccount)

      @user = user_factory(active_all: true)

      @session = {}
    end

    before do
      @config = instance_double(Config,
                                learning_provider_app_launch_url: "https://learning-provider.example.com",
                                learner_app_launch_url: "https://learner.example.com")
      @user_preference = instance_double(UserPreferenceManager,
                                         prefers_academic?: false,
                                         prefers_career?: false,
                                         prefers_learning_provider?: false,
                                         prefers_learner?: false)
      allow(Config).to receive(:new).with(@root_account).and_return(@config)
      allow(UserPreferenceManager).to receive(:new).with(@session).and_return(@user_preference)
    end

    describe "resolve" do
      context "on an account context" do
        it "returns CAREER_LEARNING_PROVIDER for admins in horizon accounts" do
          account_admin_user(user: @user, account: @career_subaccount)
          expect(ExperienceResolver.new(@user, @career_subaccount, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNING_PROVIDER
        end

        it "returns ACADEMIC for admins accessing non-horizon accounts" do
          account_admin_user(user: @user, account: @career_subaccount)
          expect(ExperienceResolver.new(@user, @root_account, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
        end

        it "returns ACADEMIC for non-admin users in horizon accounts" do
          expect(ExperienceResolver.new(@user, @career_subaccount, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
        end

        it "returns ACADEMIC when learning provider URL is not configured" do
          account_admin_user(user: @user, account: @career_subaccount)
          allow(@config).to receive(:learning_provider_app_launch_url).and_return("")
          expect(ExperienceResolver.new(@user, @career_subaccount, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
        end
      end

      context "on a course context" do
        context "as a learner" do
          before :once do
            @course_academic.enroll_student(@user, enrollment_state: "active")
            @course_career.enroll_student(@user, enrollment_state: "active")
          end

          it "returns ACADEMIC when learner app URL is not configured" do
            allow(@config).to receive(:learner_app_launch_url).and_return("")
            expect(ExperienceResolver.new(@user, @course_career, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
          end

          it "returns ACADEMIC for non-horizon courses" do
            expect(ExperienceResolver.new(@user, @course_academic, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
          end

          it "returns CAREER_LEARNER for horizon courses" do
            expect(ExperienceResolver.new(@user, @course_career, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNER
          end

          it "returns CAREER_LEARNER for horizon courses with pending invitations" do
            @course_career.enroll_student(@user, enrollment_state: "pending_invited")
            expect(ExperienceResolver.new(@user, @course_career, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNER
          end

          it "returns ACADEMIC for rejected enrollments" do
            Enrollment.find_by(user: @user, course: @course_career).reject!
            expect(ExperienceResolver.new(@user, @course_career, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
          end
        end

        context "as a learning provider" do
          before :once do
            @course_academic.enroll_teacher(@user, enrollment_state: "active")
            @course_career.enroll_teacher(@user, enrollment_state: "active")
          end

          it "returns CAREER_LEARNING_PROVIDER in horizon courses" do
            expect(ExperienceResolver.new(@user, @course_career, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNING_PROVIDER
          end

          it "returns ACADEMIC in non-horizon courses" do
            expect(ExperienceResolver.new(@user, @course_academic, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
          end
        end

        context "as a learner and learning provider" do
          before :once do
            @course_academic.enroll_teacher(@user, enrollment_state: "active")
            @course_academic.enroll_student(@user, enrollment_state: "active")
            @course_career.enroll_teacher(@user, enrollment_state: "active")
            @course_career.enroll_student(@user, enrollment_state: "active")
          end

          it "returns ACADEMIC for non-horizon courses" do
            expect(ExperienceResolver.new(@user, @course_academic, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
          end

          it "returns CAREER_LEARNING_PROVIDER for horizon courses when user prefers learning provider role" do
            allow(@user_preference).to receive(:prefers_learning_provider?).and_return(true)
            expect(ExperienceResolver.new(@user, @course_career, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNING_PROVIDER
          end

          it "returns CAREER_LEARNER for horizon courses when user prefers learner role" do
            allow(@user_preference).to receive(:prefers_learner?).and_return(true)
            expect(ExperienceResolver.new(@user, @course_career, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNER
          end
        end
      end

      context "on contextless routes" do
        it "returns ACADEMIC when user has no enrollments" do
          expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
        end

        it "returns CAREER_LEARNER if no enrollments but career is enabled on the root account" do
          @root_account.horizon_account = true
          @root_account.save!
          expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNER
        end

        context "as a learner" do
          it "returns ACADEMIC when user is enrolled in only academic courses" do
            @course_academic.enroll_student(@user, enrollment_state: "active")
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
          end

          it "returns CAREER_LEARNER when user is enrolled in only career courses" do
            @course_career.enroll_student(@user, enrollment_state: "active")
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNER
          end

          it "returns ACADEMIC when user is enrolled in career and academic courses and prefers academic experience" do
            @course_career.enroll_student(@user, enrollment_state: "active")
            @course_academic.enroll_student(@user, enrollment_state: "active")
            allow(@user_preference).to receive(:prefers_academic?).and_return(true)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
          end

          it "returns CAREER_LEARNER when user is enrolled in career and academic courses and prefers career" do
            @course_career.enroll_student(@user, enrollment_state: "active")
            @course_academic.enroll_student(@user, enrollment_state: "active")
            allow(@user_preference).to receive(:prefers_career?).and_return(true)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNER
          end

          it "returns ACADEMIC when learner app URL is not configured" do
            @course_career.enroll_student(@user, enrollment_state: "active")
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNER
            allow(@config).to receive(:learner_app_launch_url).and_return(nil)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
          end

          it "returns CAREER_LEARNER when user has no enrollments and career is enabled on the root account, even if they prefer academic experience (due to previous enrollments)" do
            @root_account.horizon_account = true
            @root_account.save!
            @root_account.reload
            allow(@user_preference).to receive(:prefers_academic?).and_return(true)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNER
          end
        end

        context "as a learning provider" do
          it "returns ACADEMIC when user is enrolled in only academic courses" do
            @course_academic.enroll_teacher(@user, enrollment_state: "active")
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
          end

          it "returns CAREER_LEARNING_PROVIDER when user is enrolled in only career courses" do
            @course_career.enroll_teacher(@user, enrollment_state: "active")
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNING_PROVIDER
          end

          it "returns CAREER_LEARNING_PROVIDER when user is an admin on a career account" do
            @career_subaccount.account_users.create!(user: @user)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNING_PROVIDER
          end

          it "returns CAREER_LEARNING_PROVIDER when user is an admin on a child of a career account" do
            @career_subaccount.horizon_account = false
            @career_subaccount.save!
            @root_account.reload
            @root_account.horizon_account = true
            @root_account.save!
            @career_subaccount.account_users.create!(user: @user)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNING_PROVIDER
          end

          it "returns ACADEMIC when user is enrolled in career and academic courses and prefers academic experience" do
            @course_career.enroll_teacher(@user, enrollment_state: "active")
            @course_academic.enroll_teacher(@user, enrollment_state: "active")
            allow(@user_preference).to receive(:prefers_academic?).and_return(true)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
          end

          it "returns CAREER_LEARNING_PROVIDER when user is enrolled in career and academic courses and prefers career" do
            @course_career.enroll_teacher(@user, enrollment_state: "active")
            @course_academic.enroll_teacher(@user, enrollment_state: "active")
            allow(@user_preference).to receive(:prefers_career?).and_return(true)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNING_PROVIDER
          end

          it "returns ACADEMIC when learning provider app URL is not configured" do
            @course_career.enroll_teacher(@user, enrollment_state: "active")
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNING_PROVIDER
            allow(@config).to receive(:learning_provider_app_launch_url).and_return(nil)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
          end
        end

        context "as a learner and learning provider" do
          before :once do
            @course_academic.enroll_teacher(@user, enrollment_state: "active")
            @course_academic.enroll_student(@user, enrollment_state: "active")
            @course_career.enroll_teacher(@user, enrollment_state: "active")
            @course_career.enroll_student(@user, enrollment_state: "active")
          end

          it "returns CAREER_LEARNING_PROVIDER when preferring learning provider role and career experience" do
            allow(@user_preference).to receive_messages(prefers_learning_provider?: true, prefers_career?: true)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNING_PROVIDER
          end

          it "returns CAREER_LEARNING_PROVIDER when preferring learning provider role and career experience and user is an admin" do
            @course_career.teacher_enrollments.destroy_all
            @career_subaccount.account_users.create!(user: @user)
            allow(@user_preference).to receive_messages(prefers_learning_provider?: true, prefers_career?: true)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNING_PROVIDER
          end

          it "returns CAREER_LEARNER when preferring learner role and career experience" do
            allow(@user_preference).to receive_messages(prefers_learner?: true, prefers_career?: true)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNER
          end

          it "returns ACADEMIC when preferring academic experience" do
            allow(@user_preference).to receive(:prefers_academic?).and_return(true)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::ACADEMIC
          end

          it "returns CAREER_LEARNER when only a learning provider in academic courses, even if LP is preferred" do
            @course_career.teacher_enrollments.destroy_all
            allow(@user_preference).to receive_messages(prefers_learning_provider?: true, prefers_career?: true)
            expect(ExperienceResolver.new(@user, nil, @root_account, @session).resolve).to eq Constants::App::CAREER_LEARNER
          end
        end
      end
    end

    describe "available_apps" do
      it "returns only ACADEMIC when there's only academic enrollments" do
        @course_academic.enroll_student(@user, enrollment_state: "active")
        expect(ExperienceResolver.new(@user, nil, @root_account, @session).available_apps).to eq [Constants::App::ACADEMIC]
      end

      it "returns only CAREER_LEARNER when there's only career learner enrollments" do
        @course_career.enroll_student(@user, enrollment_state: "active")
        expect(ExperienceResolver.new(@user, nil, @root_account, @session).available_apps).to eq [Constants::App::CAREER_LEARNER]
      end

      it "returns only CAREER_LEARNING_PROVIDER when there's only career learning provider enrollments" do
        @course_career.enroll_teacher(@user, enrollment_state: "active")
        expect(ExperienceResolver.new(@user, nil, @root_account, @session).available_apps).to eq [Constants::App::CAREER_LEARNING_PROVIDER]
      end

      it "returns only CAREER_LEARNING_PROVIDER when there's only career learning provider account users" do
        @career_subaccount.account_users.create!(user: @user)
        expect(ExperienceResolver.new(@user, nil, @root_account, @session).available_apps).to eq [Constants::App::CAREER_LEARNING_PROVIDER]
      end

      it "returns ACADEMIC and CAREER_LEARNER when there's academic and career learner enrollments" do
        @course_career.enroll_student(@user, enrollment_state: "active")
        @course_academic.enroll_student(@user, enrollment_state: "active")
        expect(ExperienceResolver.new(@user, nil, @root_account, @session).available_apps).to contain_exactly(
          Constants::App::ACADEMIC,
          Constants::App::CAREER_LEARNER
        )
      end

      it "returns ACADEMIC and CAREER_LEARNING_PROVIDER when there's academic and career learning provider enrollments" do
        @course_career.enroll_teacher(@user, enrollment_state: "active")
        @course_academic.enroll_teacher(@user, enrollment_state: "active")
        expect(ExperienceResolver.new(@user, nil, @root_account, @session).available_apps).to contain_exactly(
          Constants::App::ACADEMIC,
          Constants::App::CAREER_LEARNING_PROVIDER
        )
      end

      it "returns CAREER_LEARNER and CAREER_LEARNING_PROVIDER when there's career learner and career learning provider enrollments" do
        @course_career.enroll_teacher(@user, enrollment_state: "active")
        @course_career.enroll_student(@user, enrollment_state: "active")
        expect(ExperienceResolver.new(@user, nil, @root_account, @session).available_apps).to contain_exactly(
          Constants::App::CAREER_LEARNER,
          Constants::App::CAREER_LEARNING_PROVIDER
        )
      end

      it "returns CAREER_LEARNER and CAREER_LEARNING_PROVIDER when there's career learner enrollments and career learning provider account users" do
        @career_subaccount.account_users.create!(user: @user)
        @course_career.enroll_student(@user, enrollment_state: "active")
        expect(ExperienceResolver.new(@user, nil, @root_account, @session).available_apps).to contain_exactly(
          Constants::App::CAREER_LEARNER,
          Constants::App::CAREER_LEARNING_PROVIDER
        )
      end

      it "returns ACADEMIC, CAREER_LEARNER and CAREER_LEARNING_PROVIDER when there's academic, career learner and career learning provider enrollments" do
        @course_career.enroll_teacher(@user, enrollment_state: "active")
        @course_career.enroll_student(@user, enrollment_state: "active")
        @course_academic.enroll_teacher(@user, enrollment_state: "active")
        expect(ExperienceResolver.new(@user, nil, @root_account, @session).available_apps).to contain_exactly(
          Constants::App::ACADEMIC,
          Constants::App::CAREER_LEARNER,
          Constants::App::CAREER_LEARNING_PROVIDER
        )
      end

      it "doesn't include CAREER_LEARNING_PROVIDER if account users are on academic account" do
        @root_account.account_users.create!(user: @user)
        @course_career.enroll_student(@user, enrollment_state: "active")
        expect(ExperienceResolver.new(@user, nil, @root_account, @session).available_apps).to contain_exactly(
          Constants::App::ACADEMIC,
          Constants::App::CAREER_LEARNER
        )
      end

      it "returns ACADEMIC and CAREER_LEARNING_PROVIDER when there's academic and career learning provider account users" do
        @root_account.account_users.create!(user: @user)
        @career_subaccount.account_users.create!(user: @user)
        expect(ExperienceResolver.new(@user, nil, @root_account, @session).available_apps).to contain_exactly(
          Constants::App::ACADEMIC,
          Constants::App::CAREER_LEARNING_PROVIDER
        )
      end
    end

    describe "self.career_affiliated_institution?" do
      it "returns true when root account has horizon_account_ids" do
        expect(ExperienceResolver.career_affiliated_institution?(@root_account)).to be true
      end

      it "returns false when root account has no horizon_account_ids" do
        @root_account.settings[:horizon_account_ids] = []
        @root_account.save!
        expect(ExperienceResolver.career_affiliated_institution?(@root_account)).to be false
      end

      it "returns false when root account's horizon_account_ids is nil" do
        @root_account.settings[:horizon_account_ids] = nil
        @root_account.save!
        expect(ExperienceResolver.career_affiliated_institution?(@root_account)).to be false
      end

      it "returns false when root account is nil" do
        expect(ExperienceResolver.career_affiliated_institution?(nil)).to be false
      end
    end
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe AssetUserAccess do
  describe "with course context" do
    before :once do
      @course = Account.default.courses.create!(name: "My Course")
      @assignment = @course.assignments.create!(title: "My Assignment")
      @user = User.create!

      @asset = factory_with_protected_attributes(AssetUserAccess, user: @user, context: @course, asset_code: @assignment.asset_string)
      @asset.display_name = @assignment.asset_string
      @asset.save!
    end

    it "updates existing records that have bad display names" do
      expect(@asset.display_name).to eq "My Assignment"
    end

    it "loads root account id from context" do
      expect(@asset.root_account_id).to eq(@course.root_account_id)
    end

    it "updates existing records that have changed display names" do
      @assignment.title = "My changed Assignment"
      @assignment.save!
      AssetUserAccess.log @user, @course, { level: "view", code: @assignment.asset_string }
      expect(@asset.reload.display_name).to eq "My changed Assignment"
    end

    it "works for assessment questions" do
      question = assessment_question_model(bank: AssessmentQuestionBank.create!(context: @course))
      asset = AssetUserAccess.log @user, question, { level: "view", code: @assignment.asset_string }
      expect(asset.context).to eq @course
    end

    describe "configured for log compaction" do
      it "writes to the log instead for view counts" do
        allow(AssetUserAccess).to receive(:view_counting_method).and_return("log")
        expect(AssetUserAccessLog.for_today(@asset).count).to eq(0)
        # updating view level which hasn't been set before,
        # so this one should write to the table
        cur_view_count = @asset.view_score
        AssetUserAccess.log @user, @course, { level: "view", code: @assignment.asset_string }
        expect(@asset.reload.view_score).to_not eq(cur_view_count)
        expect(AssetUserAccessLog.for_today(@asset).count).to eq(0)
        # this time it's just a bump of the views, should get
        # sent to the log
        cur_view_count = @asset.view_score
        AssetUserAccess.log @user, @course, { level: "view", code: @assignment.asset_string }
        expect(@asset.reload.view_score).to eq(cur_view_count)
        expect(AssetUserAccessLog.for_today(@asset).count).to eq(1)
      end

      describe "#eligible_for_log_path?" do
        it "is eligible only for view bumps" do
          AssetUserAccess.log @user, @course, { level: "view", code: @assignment.asset_string }
          @asset.reload
          @asset.display_name = "foo_bar"
          expect(@asset.eligible_for_log_path?).to be_falsey
          @asset.restore_attributes
          @asset.view_score = @asset.view_score + 1
          expect(@asset.eligible_for_log_path?).to be_truthy
        end
      end
    end

    describe "for_user" do
      it "works with a User object" do
        expect(AssetUserAccess.for_user(@user)).to eq [@asset]
      end

      it "works with a list of User objects" do
        expect(AssetUserAccess.for_user([@user])).to eq [@asset]
      end

      it "works with a User id" do
        expect(AssetUserAccess.for_user(@user.id)).to eq [@asset]
      end

      it "works with a list of User ids" do
        expect(AssetUserAccess.for_user([@user.id])).to eq [@asset]
      end

      it "withs with an empty list" do
        expect(AssetUserAccess.for_user([])).to eq []
      end

      it "does not find unrelated accesses" do
        expect(AssetUserAccess.for_user(User.create!)).to eq []
        expect(AssetUserAccess.for_user(@user.id + 1)).to eq []
      end
    end

    describe "#icon" do
      it "works for quizzes" do
        quiz = @course.quizzes.create!(title: "My Quiz")

        asset = factory_with_protected_attributes(AssetUserAccess, user: @user, context: @course, asset_code: quiz.asset_string)
        asset.log(@course, { category: "quizzes" })
        asset.save!

        expect(asset.icon).to eq "icon-quiz"
      end

      it "falls back with an unexpected asset_category" do
        asset = AssetUserAccess.create asset_category: "blah"
        expect(asset.icon).to eq "icon-question"
        expect(asset.readable_category).to eq ""
      end
    end
  end

  describe "with user context" do
    before :once do
      @course = Account.default.courses.create!(name: "My Course")
      @assignment = @course.assignments.create!(title: "My Assignment")
      @user = User.create!

      @asset = factory_with_protected_attributes(AssetUserAccess, user: @user, context: @user, asset_code: @assignment.asset_string)
      @asset.display_name = @assignment.asset_string
      @asset.save!
    end

    it "sets root account id to 0" do
      expect(@asset.root_account_id).to eq(0)
    end

    it "can load by user context" do
      expect(AssetUserAccess.for_context(@user)).to eq [@asset]
    end
  end

  describe "#log_action" do
    subject { asset }

    let(:scores) { {} }
    let(:asset) { AssetUserAccess.new(scores) }

    describe "when action level is nil" do
      describe "with nil scores" do
        describe "view level" do
          before { asset.log_action "view" }

          describe "#view_score" do
            subject { super().view_score }

            it { is_expected.to eq 1 }
          end

          describe "#participate_score" do
            subject { super().participate_score }

            it { is_expected.to be_nil }
          end

          describe "#action_level" do
            subject { super().action_level }

            it { is_expected.to eq "view" }
          end
        end

        describe "participate level" do
          before { asset.log_action "participate" }

          describe "#view_score" do
            subject { super().view_score }

            it { is_expected.to eq 1 }
          end

          describe "#participate_score" do
            subject { super().participate_score }

            it { is_expected.to eq 1 }
          end

          describe "#action_level" do
            subject { super().action_level }

            it { is_expected.to eq "participate" }
          end
        end

        describe "submit level" do
          before { asset.log_action "submit" }

          describe "#view_score" do
            subject { super().view_score }

            it { is_expected.to be_nil }
          end

          describe "#participate_score" do
            subject { super().participate_score }

            it { is_expected.to eq 1 }
          end

          describe "#action_level" do
            subject { super().action_level }

            it { is_expected.to eq "participate" }
          end
        end
      end

      describe "with existing scores" do
        before { asset.view_score = asset.participate_score = 3 }

        describe "view level" do
          before { asset.log_action "view" }

          describe "#view_score" do
            subject { super().view_score }

            it { is_expected.to eq 4 }
          end

          describe "#participate_score" do
            subject { super().participate_score }

            it { is_expected.to eq 3 }
          end

          describe "#action_level" do
            subject { super().action_level }

            it { is_expected.to eq "view" }
          end
        end

        describe "participate level" do
          before { asset.log_action "participate" }

          describe "#view_score" do
            subject { super().view_score }

            it { is_expected.to eq 4 }
          end

          describe "#participate_score" do
            subject { super().participate_score }

            it { is_expected.to eq 4 }
          end

          describe "#action_level" do
            subject { super().action_level }

            it { is_expected.to eq "participate" }
          end
        end

        describe "submit level" do
          before { asset.log_action "submit" }

          describe "#view_score" do
            subject { super().view_score }

            it { is_expected.to eq 3 }
          end

          describe "#participate_score" do
            subject { super().participate_score }

            it { is_expected.to eq 4 }
          end

          describe "#action_level" do
            subject { super().action_level }

            it { is_expected.to eq "participate" }
          end
        end
      end
    end

    describe "when action level is view" do
      before { asset.action_level = "view" }

      it "gets overridden by participate" do
        asset.log_action "participate"
        expect(asset.action_level).to eq "participate"
      end

      it "gets overridden by submit" do
        asset.log_action "submit"
        expect(asset.action_level).to eq "participate"
      end
    end

    it "does not overwrite the participate level with view" do
      asset.action_level = "participate"
      asset.log_action "view"
      expect(asset.action_level).to eq "participate"
    end
  end

  describe "#log" do
    subject { access }

    let(:access) { AssetUserAccess.new }
    let(:context) { User.new }

    before { allow(access).to receive :save }

    describe "attribute values directly from hash" do
      def it_sets_if_nil(attribute, hash_key = nil)
        hash_key ||= attribute
        access.log(context, { hash_key => "value" })
        expect(access.send(attribute)).to eq "value"
        access.send(:"#{attribute}=", "other")
        access.log(context, { hash_key => "value" })
        expect(access.send(attribute)).to eq "other"
      end

      specify { it_sets_if_nil(:asset_category, :category) }
      specify { it_sets_if_nil(:asset_group_code, :group_code) }
      specify { it_sets_if_nil(:membership_type) }
    end

    describe "interally set or calculated attribute values" do
      before { access.log context, { level: "view" } }

      describe "#context" do
        subject { super().context }

        it { is_expected.to eq context }
      end

      describe "#last_access" do
        subject { super().last_access }

        it { is_expected.not_to be_nil }
      end

      describe "#view_score" do
        subject { super().view_score }

        it { is_expected.to eq 1 }
      end

      describe "#participate_score" do
        subject { super().participate_score }

        it { is_expected.to be_nil }
      end

      describe "#action_level" do
        subject { super().action_level }

        it { is_expected.to eq "view" }
      end
    end

    describe "setting root account id" do
      before :once do
        @course = Account.default.courses.create!(name: "My Course")
        @user = User.create!
      end

      it "loads root account id from context" do
        assignment = @course.assignments.create!(title: "My Assignment2")
        AssetUserAccess.log @user, @course, { level: "view", code: assignment.asset_string }
        expect(AssetUserAccess.last.root_account_id).to eq(@course.root_account_id)
      end

      it "loads root account id from asset_for_root_account_id when context is a User" do
        assignment = @course.assignments.create!(title: "My Assignment2")
        AssetUserAccess.log @user, @user, { level: "view", code: assignment.asset_string, asset_for_root_account_id: assignment }
        expect(AssetUserAccess.last.root_account_id).to eq(@course.root_account_id)
      end

      it "loads root account id from asset_for_root_account_id when context is a User and asset has a resolved_root_account_id but not a root_account_id" do
        # Not sure if this really ever happens but handle it on the safe side
        @course.assignments.create!(title: "My Assignment2")
        AssetUserAccess.log @user, @user, { level: "view", code: @user.asset_string, asset_for_root_account_id: @course.root_account }
        expect(AssetUserAccess.last.root_account_id).to eq(@course.root_account_id)
      end

      it "sets root account id to 0 when context is a User and asset is a User" do
        AssetUserAccess.log @user, @user, { level: "view", code: @user.asset_string, asset_for_root_account_id: @user }
        expect(AssetUserAccess.last.root_account_id).to eq(0)
      end
    end
  end

  describe "#corrected_view_score" do
    it "deducts the participation score from the view score for a quiz" do
      subject.view_score = 10
      subject.participate_score = 4
      subject.asset_group_code = "quizzes"

      expect(subject.corrected_view_score).to eq 6
    end

    it "returns the normal view score for anything but a quiz" do
      subject.view_score = 10
      subject.participate_score = 4

      expect(subject.corrected_view_score).to eq 10
    end

    it "does not complain if there is no current score" do
      subject.view_score = nil
      subject.participate_score = 4
      allow(subject).to receive(:asset_group_code).and_return("quizzes")

      expect(subject.corrected_view_score).to eq(-4)
    end
  end

  describe "consuming plugin setting" do
    it "defaults to normal updates" do
      expect(AssetUserAccess.view_counting_method).to eq("update")
    end

    it "reads plugin setting for override" do
      ps = PluginSetting.find_or_initialize_by(name: "asset_user_access_logs")
      ps.inheritance_scope = "shard"
      ps.settings = { max_log_ids: [0, 0, 0, 0, 0, 0, 0], write_path: "log" }
      ps.save!
      expect(AssetUserAccess.view_counting_method).to eq("log")
    end
  end

  describe "delete_old_records" do
    before :once do
      @old_aua = AssetUserAccess.create! last_access: 25.months.ago
      @new_aua = AssetUserAccess.create! last_access: 13.seconds.ago
    end

    it "deletes old records" do
      AssetUserAccess.delete_old_records
      expect { @new_aua.reload }.not_to raise_error
      expect { @old_aua.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "sleeps between batches if set" do
      stub_const("AssetUserAccess::DELETE_BATCH_SIZE", 1)
      stub_const("AssetUserAccess::DELETE_BATCH_SLEEP", 0.5)
      AssetUserAccess.create! last_access: 25.months.ago
      expect(AssetUserAccess).to receive(:sleep).with(0.5).at_least(:twice)
      AssetUserAccess.delete_old_records
    end
  end
end

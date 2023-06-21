# frozen_string_literal: true

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
#

describe OutcomeProficiency do
  describe "associations" do
    it { is_expected.to have_many(:outcome_proficiency_ratings).dependent(:destroy).order("points DESC, id ASC").inverse_of(:outcome_proficiency) }
    it { is_expected.to belong_to(:context).required }
  end

  describe "validations" do
    subject { outcome_proficiency_model(account_model) }

    it { is_expected.to validate_presence_of :outcome_proficiency_ratings }
    it { is_expected.to validate_presence_of :context }
    it { is_expected.to validate_uniqueness_of(:context_id).scoped_to(:context_type) }

    describe "strictly descending points" do
      it "valid proficiency" do
        expect(subject.valid?).to be(true)
      end

      it "invalid proficiency" do
        rating1 = OutcomeProficiencyRating.new(description: "A", points: 4, mastery: false, color: "00ff00")
        rating2 = OutcomeProficiencyRating.new(description: "B", points: 3, mastery: false, color: "0000ff")
        rating3 = OutcomeProficiencyRating.new(description: "B", points: 3, mastery: false, color: "0000ff")
        rating4 = OutcomeProficiencyRating.new(description: "C", points: 2, mastery: true, color: "ff0000")
        subject.outcome_proficiency_ratings = [rating1, rating2, rating3, rating4]
        expect(subject.valid?).to be(false)
      end
    end

    it "sets the context from account" do
      account = account_model
      proficiency = outcome_proficiency_model(account)
      expect(proficiency.context_type).to eq "Account"
      expect(proficiency.context).to eq account
    end

    it "can belong to a course" do
      course = course_model
      proficiency = outcome_proficiency_model(course)
      expect(proficiency.context_type).to eq "Course"
      expect(proficiency.context).to eq course
    end
  end

  describe "before save" do
    it "sets root account id" do
      root_account = account_model
      proficiency = outcome_proficiency_model(root_account)
      expect(proficiency.root_account_id).to be(root_account.resolved_root_account_id)
    end

    it "sets root account id with passed in id" do
      root_account_1 = account_model
      root_account_2 = account_model
      rating1 = OutcomeProficiencyRating.new(description: "best", points: 10, mastery: true, color: "00ff00")
      rating2 = OutcomeProficiencyRating.new(description: "worst", points: 0, mastery: false, color: "ff0000")
      proficiency = OutcomeProficiency.create!(outcome_proficiency_ratings: [rating1, rating2],
                                               context: root_account_1,
                                               root_account_id: root_account_2.resolved_root_account_id)
      expect(proficiency.root_account_id).to be(root_account_2.resolved_root_account_id)
    end
  end

  describe "undestroy" do
    before do
      rating1 = OutcomeProficiencyRating.new(description: "best", points: 10, mastery: true, color: "00ff00")
      rating2 = OutcomeProficiencyRating.new(description: "worst", points: 0, mastery: false, color: "ff0000")
      @proficiency = OutcomeProficiency.create!(outcome_proficiency_ratings: [rating1, rating2], account: account_model)
      @proficiency.destroy
      @proficiency.undestroy
    end

    it "restores soft deleted ratings" do
      expect(OutcomeProficiencyRating.active.count).to eq 2
    end

    it "sets workflow_state to active upon undestroying" do
      expect(@proficiency.workflow_state).to eq "active"
    end
  end

  it_behaves_like "soft deletion" do
    subject { OutcomeProficiency }

    let(:first_account) { account_model }
    let(:second_account) { account_model }
    let(:rating1) { OutcomeProficiencyRating.new(description: "best", points: 10, mastery: true, color: "00ff00") }
    let(:params) { { outcome_proficiency_ratings: [rating1] } }
    let(:creation_arguments) { [params.merge(context: first_account), params.merge(context: second_account)] }
  end

  describe "ratings_hash" do
    before do
      rating1 = OutcomeProficiencyRating.new(description: "best", points: 10, mastery: true, color: "00ff00")
      @outcome_proficiency = OutcomeProficiency.create!(outcome_proficiency_ratings: [rating1], context: account_model)
    end

    it "returns the ratings in a hash with the appropriate values" do
      expect(@outcome_proficiency.ratings_hash).to eq [{ description: "best", points: 10, mastery: true, color: "00ff00" }]
    end
  end

  describe "mastery_points" do
    before do
      rating1 = OutcomeProficiencyRating.new(description: "best", points: 10, mastery: true, color: "00ff00")
      @outcome_proficiency = OutcomeProficiency.create!(outcome_proficiency_ratings: [rating1], context: account_model)
    end

    it "returns the points for the mastery rating" do
      expect(@outcome_proficiency.mastery_points).to eq 10
    end
  end

  describe "points_possible" do
    before do
      rating1 = OutcomeProficiencyRating.new(description: "best", points: 10, mastery: false, color: "00ff00")
      rating2 = OutcomeProficiencyRating.new(description: "okay", points: 5, mastery: true, color: "00ff00")
      @outcome_proficiency = OutcomeProficiency.create!(outcome_proficiency_ratings: [rating1, rating2], context: account_model)
    end

    it "returns the points for the top rating" do
      expect(@outcome_proficiency.points_possible).to eq 10
    end
  end

  describe "interaction with cache" do
    let(:account) { account_model }

    it "clears the account cache on save" do
      expect(account).to receive(:clear_downstream_caches).with(:resolved_outcome_proficiency)
      OutcomeProficiency.find_or_create_default!(account)
    end
  end

  describe "find_or_create_default!" do
    before do
      @account = account_model
      @default_ratings = OutcomeProficiency.default_ratings
    end

    it "creates the default proficiency if one doesnt exist" do
      proficiency = OutcomeProficiency.find_or_create_default!(@account)
      expect(proficiency.ratings_hash).to eq @default_ratings
      expect(proficiency.workflow_state).to eq "active"
      expect(proficiency.context).to eq @account
    end

    it "finds the proficiency if one exists" do
      proficiency = outcome_proficiency_model(@account)
      default = OutcomeProficiency.find_or_create_default!(@account)
      expect(proficiency).to eq default
    end

    it "can reset soft deleted records" do
      proficiency = outcome_proficiency_model(@account)
      proficiency.destroy
      default = OutcomeProficiency.find_or_create_default!(@account)
      proficiency = proficiency.reload
      expect(proficiency).to eq default
      expect(proficiency.workflow_state).to eq "active"
      expect(proficiency.ratings_hash).to eq @default_ratings
    end

    it "can graciously handle RecordInvalid errors" do
      proficiency = outcome_proficiency_model(@account)
      allow(OutcomeProficiency).to receive(:find_by).and_return(nil, proficiency)
      default = OutcomeProficiency.find_or_create_default!(@account)
      expect(proficiency).to eq default
    end
  end

  describe "updating rubrics" do
    before(:once) do
      account.enable_feature! :account_level_mastery_scales
    end

    let_once(:account) { account_model }
    let_once(:course) { course_model(account:) }
    let_once(:account_rubric) { outcome_with_rubric(context: account) }
    let_once(:course_rubric) { outcome_with_rubric(context: course) }
    let_once(:outcome_proficiency) { outcome_proficiency_model(account) }
    let(:ratings_hash) { outcome_proficiency.ratings_hash }

    it "updates associated rubrics when changed on an account" do
      outcome_proficiency.outcome_proficiency_ratings[0].points = 20
      outcome_proficiency.save!
      expect(account_rubric.reload.points_possible).to eq 25
      expect(course_rubric.reload.points_possible).to eq 25
    end

    it "updates associated rubrics when changed on a course" do
      ratings_hash[0][:points] = 30
      course_proficiency = OutcomeProficiency.new(context: course)
      course_proficiency.replace_ratings(ratings_hash)
      course_proficiency.save!
      expect(course_rubric.reload.points_possible).to eq 35
      # unchanged
      expect(account_rubric.reload.points_possible).to eq 15
    end

    it "does not update rubrics when not changed" do
      expect do
        outcome_proficiency.replace_ratings(ratings_hash)
        outcome_proficiency.save!
      end.not_to change { account_rubric.reload.updated_at }
    end

    it "does not update assessed rubrics" do
      student_in_course(course:)
      rubric_assessment_model(rubric: course_rubric, context: course, user: @student, purpose: "grading")
      outcome_proficiency.outcome_proficiency_ratings[0].points = 30
      outcome_proficiency.save!
      expect(course_rubric.reload.points_possible).to eq 15
      # unassessed, so updated
      expect(account_rubric.reload.points_possible).to eq 35
    end

    it "does not update rubrics associated with multiple assignments" do
      rubric_association_model(rubric: account_rubric, context: course, purpose: "grading")
      rubric_association_model(rubric: course_rubric, context: course, purpose: "grading")
      other_course = course_model(account:)
      rubric_association_model(rubric: account_rubric, context: other_course, purpose: "grading")

      outcome_proficiency.outcome_proficiency_ratings[0].points = 30
      outcome_proficiency.save!
      expect(account_rubric.reload.points_possible).to eq 15
      # associated with a single assignment, so updated
      expect(course_rubric.reload.points_possible).to eq 35
    end

    context "with subaccounts" do
      let_once(:subaccount) { account_model(parent_account: account) }
      let_once(:subaccount_course) { course_model(account: subaccount) }
      let_once(:subaccount_rubric) { outcome_with_rubric(context: subaccount) }
      let_once(:subaccount_course_rubric) { outcome_with_rubric(context: subaccount_course) }

      it "updates rubrics in subaccounts" do
        outcome_proficiency.outcome_proficiency_ratings[0].points = 30
        outcome_proficiency.save!

        expect(subaccount_rubric.reload.points_possible).to eq 35
        expect(subaccount_course_rubric.reload.points_possible).to eq 35
      end

      it "does not update rubrics from parent contexts" do
        ratings_hash[0][:points] = 30
        subaccount_proficiency = OutcomeProficiency.new(context: subaccount)
        subaccount_proficiency.replace_ratings(ratings_hash)
        subaccount_proficiency.save!

        expect(subaccount_rubric.reload.points_possible).to eq 35
        expect(subaccount_course_rubric.reload.points_possible).to eq 35
        # not affected
        expect(account_rubric.reload.points_possible).to eq 15
        expect(course_rubric.reload.points_possible).to eq 15
      end

      it "does not update rubrics when a subcontext has its own proficiency ratings" do
        subaccount_proficiency = OutcomeProficiency.new(context: subaccount)
        subaccount_proficiency.replace_ratings(ratings_hash)
        subaccount_proficiency.save!

        outcome_proficiency.outcome_proficiency_ratings[0].points = 30
        outcome_proficiency.save!

        # does not update subaccount
        expect(subaccount_rubric.reload.points_possible).to eq 15
        expect(subaccount_course_rubric.reload.points_possible).to eq 15
        # does update account
        expect(account_rubric.reload.points_possible).to eq 35
        expect(course_rubric.reload.points_possible).to eq 35
      end
    end

    it "does not update deleted rubrics" do
      account_rubric.destroy!
      outcome_proficiency.outcome_proficiency_ratings[0].points = 30
      outcome_proficiency.save!
      expect(account_rubric.reload.points_possible).to eq 15
    end

    it "updates associated rubrics when deleted and restored" do
      ratings_hash[0][:points] = 30
      course_proficiency = OutcomeProficiency.new(context: course)
      course_proficiency.replace_ratings(ratings_hash)
      course_proficiency.save!

      expect(course_rubric.reload.points_possible).to eq 35
      course_proficiency.destroy!
      expect(course_rubric.reload.points_possible).to eq 15
      course_proficiency.undestroy
      expect(course_rubric.reload.points_possible).to eq 35
    end

    it "does not update rubrics when mastery scales disabled" do
      account.disable_feature! :account_level_mastery_scales
      outcome_proficiency.outcome_proficiency_ratings[0].points = 30
      outcome_proficiency.save!
      expect(account_rubric.reload.points_possible).to eq 15
    end
  end
end

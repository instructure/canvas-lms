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

describe LearningOutcomeGroup do
  before do
    course_factory
    @root = @course.root_outcome_group
  end

  def long_text(max = 65_535)
    text = +""
    (0...max + 1).each do |num|
      text.concat(num.to_s)
    end
    text
  end

  describe "associations" do
    it { is_expected.to belong_to(:source_outcome_group).class_name("LearningOutcomeGroup").inverse_of(:destination_outcome_groups) }
    it { is_expected.to have_many(:destination_outcome_groups).class_name("LearningOutcomeGroup").inverse_of(:source_outcome_group).dependent(:nullify) }
  end

  context "object creation" do
    it "does not create multiple default groups" do
      group = @course.root_outcome_group
      expect(group).to eq @root
    end

    it "does not add itself as a child" do
      expect(@root.child_outcome_groups.count).to eq 0
      @root.adopt_outcome_group(LearningOutcomeGroup.find(@root.id))
      expect(@root.child_outcome_groups.count).to eq 0
    end

    it "does not let adopt_outcome_group cause disgusting ancestral relations" do
      group = @course.learning_outcome_groups.create!(title: "groupage")
      group2 = @course.learning_outcome_groups.create!(title: "groupage2")
      @root.adopt_outcome_group(group)
      @root.adopt_outcome_group(group2)

      group.adopt_outcome_group(group2)
      expect(group.child_outcome_groups.count).to eq 1
      expect(@root.child_outcome_groups.count).to eq 1

      # shouldn't work because group is already group2's parent
      group2.adopt_outcome_group(group)
      expect(group2.child_outcome_groups.count).to eq 0
      expect(group.child_outcome_groups.count).to eq 1
      expect(@root.child_outcome_groups.count).to eq 1
    end

    it "allows touching the context to be skipped" do
      group = @course.learning_outcome_groups.create!(title: "groupage")
      group.add_outcome @course.created_learning_outcomes.create!(title: "o1")
      group.add_outcome @course.created_learning_outcomes.create!(title: "o2")
      group.add_outcome @course.created_learning_outcomes.create!(title: "o3")

      time = 1.hour.ago
      Course.where(id: @course).update_all(updated_at: time)

      group.skip_tag_touch = true
      group.destroy

      expect(@course.reload.updated_at.to_i).to eq time.to_i
    end

    it "validates presense of title" do
      expect { @course.learning_outcome_groups.create! }.to raise_error(
        ActiveRecord::RecordInvalid, "Validation failed: Title can't be blank"
      )
    end

    it "validates length of title" do
      expect { @course.learning_outcome_groups.create!(title: long_text(255)) }.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Title is too long (maximum is 255 characters)"
      )
    end

    it "validates length of description" do
      expect { @course.learning_outcome_groups.create!(title: "foobar", description: long_text) }.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Description is too long (maximum is 65,535 characters)"
      )
    end
  end

  describe "#parent_ids" do
    it "returns non-empty array" do
      group = @course.learning_outcome_groups.create!(title: "groupage")

      expect(group.parent_ids).to be_a(Array)
      expect(group.parent_ids).not_to be_empty
    end

    it "correctly references parents" do
      group1 = @course.learning_outcome_groups.create!(title: "group1")
      group2 = @course.learning_outcome_groups.create!(title: "group2")
      child_outcome_group = group1.add_outcome_group(group2)

      expect(child_outcome_group.parent_ids).to include(group1.id)
    end
  end

  describe "#add_outcome" do
    it "creates a link between the group and an outcome" do
      group = @course.learning_outcome_groups.create!(title: "groupage")
      outcome = @course.created_learning_outcomes.create!(title: "o1")

      expect(group.child_outcome_links.map(&:content_id)).not_to include(outcome.id)
      group.add_outcome(outcome)
      expect(group.child_outcome_links.map(&:content_id)).to include(outcome.id)
    end

    it "touches context when adding outcome to group" do
      group = @course.learning_outcome_groups.create!(title: "groupage")
      outcome = @course.created_learning_outcomes.create!(title: "o1")
      expect { group.add_outcome(outcome) }.to change { group.context.reload.updated_at }
    end

    it "does not touch context if skip_touch is true" do
      group = @course.learning_outcome_groups.create!(title: "groupage")
      outcome = @course.created_learning_outcomes.create!(title: "o1")
      expect { group.add_outcome(outcome, skip_touch: true) }.not_to change { group.context.reload.updated_at }
    end

    it "no-ops if a link already exists" do
      group = @course.learning_outcome_groups.create!(title: "groupage")
      outcome = @course.created_learning_outcomes.create!(title: "o1")

      group.add_outcome(outcome)
      expect(group.child_outcome_links.count).to eq(1)

      group.add_outcome(outcome)
      expect(group.child_outcome_links.count).to eq(1)
    end
  end

  describe ".bulk_link_outcome" do
    it "creates a link between the group and an outcome" do
      group = @course.learning_outcome_groups.create!(title: "groupage")
      outcome = @course.created_learning_outcomes.create!(title: "o1")

      expect(group.child_outcome_links.map(&:content_id)).not_to include(outcome.id)
      LearningOutcomeGroup.bulk_link_outcome(outcome, LearningOutcomeGroup.where(id: group.id), root_account_id: Account.default.id)
      expect(group.reload.child_outcome_links.map(&:content_id)).to include(outcome.id)
    end

    it "triggers live event manually to create outcome edge" do
      group = @course.learning_outcome_groups.create!(title: "groupage")
      outcome = @course.created_learning_outcomes.create!(title: "o1")

      expect(group.child_outcome_links.map(&:content_id)).not_to include(outcome.id)
      expect(Canvas::LiveEvents).to receive(:learning_outcome_link_created)
      LearningOutcomeGroup.bulk_link_outcome(outcome, LearningOutcomeGroup.where(id: group.id), root_account_id: Account.default.id)
    end

    it "touches context when adding outcome to group" do
      group = @course.learning_outcome_groups.create!(title: "groupage")
      outcome = @course.created_learning_outcomes.create!(title: "o1")
      expect do
        LearningOutcomeGroup.bulk_link_outcome(outcome, LearningOutcomeGroup.where(id: group.id), root_account_id: Account.default.id)
      end.to change { group.context.reload.updated_at }
    end

    it "creates the ContentTag the same as #add_outcome" do
      group = @course.learning_outcome_groups.create!(title: "groupage")
      outcome = @course.created_learning_outcomes.create!(title: "o1")

      group.add_outcome(outcome)
      ct1 = ContentTag.last.as_json["content_tag"].except(:id, :created_at, :updated_at)
      ContentTag.last.delete

      LearningOutcomeGroup.bulk_link_outcome(outcome, LearningOutcomeGroup.where(id: group.id), root_account_id: Account.default.id)
      ct2 = ContentTag.last.as_json["content_tag"].except(:id, :created_at, :updated_at)
      expect(ct2).to eq ct1
    end
  end

  describe "#add_outcome_group" do
    before do
      @group1 = @course.learning_outcome_groups.create!(title: "group1")
      @group2 = @course.learning_outcome_groups.create!(title: "group2")
      @outcome1 = @course.created_learning_outcomes.create!(title: "o1")
      @group2.add_outcome(@outcome1)
    end

    it "adds a child outcome group and copies all contents" do
      expect(@group1.child_outcome_groups).to be_empty

      child_outcome_group = @group1.add_outcome_group(@group2)

      expect(child_outcome_group.title).to eq(@group2.title)
      expect(child_outcome_group.child_outcome_links.map(&:content_id)).to eq(
        @group2.child_outcome_links.map(&:content_id)
      )
    end

    it "touches context exactly once" do
      expect(@group1.child_outcome_groups).to be_empty
      expect(@group1.context).to receive(:touch).once.and_return true
      @group1.add_outcome_group(@group2)
    end
  end

  describe "#adopt_outcome_link" do
    it "moves an existing outcome link from to this group if groups in same context and touchs parent group" do
      group1 = @course.learning_outcome_groups.create!(title: "group1")
      group2 = @course.learning_outcome_groups.create!(title: "group2")
      outcome = @course.created_learning_outcomes.create!(title: "o1")
      outcome_link = group2.add_outcome(outcome)

      expect(outcome_link.associated_asset).to eq(group2)

      expect(group1).to receive(:touch_parent_group)
      group1.adopt_outcome_link(outcome_link)

      expect(outcome_link.associated_asset).to eq(group1)
    end

    it "no-ops if group is already owner" do
      group1 = @course.learning_outcome_groups.create!(title: "group1")
      outcome = @course.created_learning_outcomes.create!(title: "o1")
      outcome_link = group1.add_outcome(outcome)

      expect(outcome_link.associated_asset).to eq(group1)

      expect { group1.adopt_outcome_link(outcome_link) }
        .not_to change { outcome_link.associated_asset }
    end

    it "doesn't touch parent group if skip_parent_group_touch is true" do
      group1 = @course.learning_outcome_groups.create!(title: "group1")
      group2 = @course.learning_outcome_groups.create!(title: "group2")
      outcome = @course.created_learning_outcomes.create!(title: "o1")
      outcome_link = group2.add_outcome(outcome)

      expect(outcome_link.associated_asset).to eq(group2)

      expect(group1).not_to receive(:touch_parent_group)

      group1.adopt_outcome_link(outcome_link, skip_parent_group_touch: true)
    end
  end

  describe "#adopt_outcome_group" do
    it "moves an existing outcome link from to this group if groups in same context" do
      group1 = @course.learning_outcome_groups.create!(title: "group1")
      group2 = @course.learning_outcome_groups.create!(title: "group2")

      expect(group2.parent_outcome_group).not_to eq(group1)

      group1.adopt_outcome_group(group2)

      expect(group2.parent_outcome_group).to eq(group1)
    end

    it "no-ops if group is already parent" do
      group1 = @course.learning_outcome_groups.create!(title: "group1")

      expect { group1.adopt_outcome_group(group1) }
        .not_to change { group1.learning_outcome_group_id }
    end
  end

  describe ".for_context" do
    it "returns all learning outcome groups for a context" do
      group1 = @course.learning_outcome_groups.create!(title: "group1")
      expect(LearningOutcomeGroup.for_context(@course)).to include(group1)
    end
  end

  describe ".global_root_outcome_group" do
    it "finds or creates a root outcome group" do
      expect(LearningOutcomeGroup.global_root_outcome_group.title).to eq("ROOT")
      expect(LearningOutcomeGroup.global_root_outcome_group.parent_outcome_group).to be_nil
    end
  end

  describe ".find_or_create_root" do
    it "finds or creates a root outcome group of a given context" do
      root = LearningOutcomeGroup.find_or_create_root(nil, true)
      expect(root.title).to eq("ROOT")

      course_root = LearningOutcomeGroup.find_or_create_root(@course, true)
      expect(course_root.title).to eq("Unnamed Course")

      expect(root).not_to eq(course_root)
    end

    it "sends live events even when they have been otherwise disabled" do
      expect(Canvas::LiveEvents).to receive(:learning_outcome_group_created)
      ActiveRecord::Base.observers.disable LiveEventsObserver do
        new_course = course_factory
        LearningOutcomeGroup.find_or_create_root(new_course, true)
      end
    end
  end

  describe "#destroy" do
    it "destroys all children links" do
      group1 = @course.learning_outcome_groups.create!(title: "group1")
      group2 = @course.learning_outcome_groups.create!(title: "group2")
      outcome1 = @course.created_learning_outcomes.create!(title: "o1")
      outcome2 = @course.created_learning_outcomes.create!(title: "o2")

      group1.add_outcome(outcome1)
      group2.add_outcome(outcome2)
      group1.add_outcome_group(group2)

      active_child_outcomes = group1.child_outcome_links.select { |ol| ol.workflow_state == "active" }
      active_child_groups = group1.child_outcome_groups.active
      expect(active_child_outcomes).not_to be_empty
      expect(active_child_groups).not_to be_empty

      group1.destroy
      group1.reload

      active_child_outcomes = group1.child_outcome_links.select { |ol| ol.workflow_state == "active" }
      active_child_groups = group1.child_outcome_groups.active
      expect(group1.workflow_state).to eq("deleted")
      expect(active_child_outcomes).to be_empty
      expect(active_child_groups).to be_empty
    end
  end

  describe "#archive" do
    it "sets the workflow_state to archived and sets archived_at" do
      group = @course.learning_outcome_groups.create!(title: "group")
      group.archive!
      expect(group.workflow_state).to eq("archived")
      expect(group.archived_at).not_to be_nil
    end

    it "won't update an already archived group" do
      group = @course.learning_outcome_groups.create!(title: "group")
      group.archive!
      archived_at = group.archived_at
      expect(group.workflow_state).to eq("archived")
      expect(group.archived_at).not_to be_nil
      group.archive!
      expect(group.workflow_state).to eq("archived")
      expect(group.archived_at).to eq(archived_at)
    end

    it "raises an ActiveRecord::RecordNotSaved error if we try to archive a deleted group" do
      group = @course.learning_outcome_groups.create!(title: "group")
      group.destroy!
      expect(group.workflow_state).to eq("deleted")
      expect { group.archive! }.to raise_error(
        ActiveRecord::RecordNotSaved,
        "Cannot archive a deleted LearningOutcomeGroup"
      )
      expect(group.workflow_state).to eq("deleted")
      expect(group.archived_at).to be_nil
    end
  end

  describe "#unarchive" do
    it "sets the workflow_state to active and sets archived_at to nil" do
      group = @course.learning_outcome_groups.create!(title: "group")
      group.archive!
      expect(group.workflow_state).to eq("archived")
      expect(group.archived_at).not_to be_nil
      group.unarchive!
      expect(group.workflow_state).to eq("active")
      expect(group.archived_at).to be_nil
    end

    it "won't update an active group" do
      group = @course.learning_outcome_groups.create!(title: "group")
      expect(group.workflow_state).to eq("active")
      expect(group.archived_at).to be_nil
      group.unarchive!
      expect(group.workflow_state).to eq("active")
      expect(group.archived_at).to be_nil
    end

    it "raises an ActiveRecord::RecordNotSaved error if we try to unarchive a deleted group" do
      group = @course.learning_outcome_groups.create!(title: "group")
      group.destroy!
      expect(group.workflow_state).to eq("deleted")
      expect { group.unarchive! }.to raise_error(
        ActiveRecord::RecordNotSaved,
        "Cannot unarchive a deleted LearningOutcomeGroup"
      )
      expect(group.workflow_state).to eq("deleted")
      expect(group.archived_at).to be_nil
    end
  end

  context "root account resolution" do
    it "sets root_account_id using Account context" do
      group = LearningOutcomeGroup.create!(title: "group", context: Account.default)
      expect(group.root_account).to eq Account.default
    end

    it "sets root_account_id using Course context" do
      group = @course.learning_outcome_groups.create!(title: "group")
      expect(group.root_account).to eq @course.root_account
    end

    it "sets root_acount_id 0 when global (context is nil)" do
      group = LearningOutcomeGroup.create!(title: "group", context_id: nil)
      expect(group.root_account_id).to eq 0
    end
  end

  context "sync_source_group" do
    def assert_tree_exists(groups, db_parent_group)
      group_titles = db_parent_group.child_outcome_groups.active.pluck(:title)
      expect(group_titles.sort).to eql(groups.pluck(:title).sort)

      groups.each do |group|
        outcome_titles = group[:outcomes] || []
        title = group[:title]
        childs = group[:groups]

        # root_account_id should match the context of the db_parent_group.context root_account_id
        log_db_root_account_id = LearningOutcomeGroup.find_by(context: db_parent_group.context, title:).root_account_id
        expect(log_db_root_account_id).to eq(db_parent_group.context.resolved_root_account_id)

        db_group = db_parent_group.child_outcome_groups.find_by!(title:)

        db_outcomes = db_group.child_outcome_links.map(&:content)

        expect(outcome_titles.sort).to eql(db_outcomes.map(&:title).sort)

        assert_tree_exists(childs, db_group) if childs
      end
    end

    before do
      make_group_structure({
                             title: "Group A",
                             outcomes: 1,
                             groups: [{
                               title: "Group C",
                               outcomes: 1,
                               groups: [{
                                 title: "Group D",
                                 outcomes: 1
                               },
                                        {
                                          title: "Group E",
                                          outcomes: 1
                                        }]
                             }]
                           },
                           Account.default)

      group_a = LearningOutcomeGroup.find_by(title: "Group A")
      @course_group_a = LearningOutcomeGroup.create!(
        title: "Group A",
        context: @course,
        source_outcome_group: group_a
      )
    end

    it "sync all groups and outcomes from source" do
      assert_tree_exists([{
                           title: "Group A",
                           outcomes: []
                         }],
                         @root)

      @course_group_a.sync_source_group

      assert_tree_exists([{
                           title: "Group A",
                           outcomes: ["0 Group A outcome"],
                           groups: [{
                             title: "Group C",
                             outcomes: ["0 Group C outcome"],
                             groups: [{
                               title: "Group D",
                               outcomes: ["0 Group D outcome"]
                             },
                                      {
                                        title: "Group E",
                                        outcomes: ["0 Group E outcome"]
                                      }]
                           }]
                         }],
                         @root)
    end

    it "restore previous deleted group" do
      @course_group_a.sync_source_group
      group_d = LearningOutcomeGroup.find_by(title: "Group D", context: @course)
      group_d.destroy
      @course_group_a.sync_source_group
      group_d.reload
      expect(group_d.workflow_state).to eql("active")
      expect(group_d.root_account_id).to eql(@course.resolved_root_account_id)
    end
  end

  describe "scope" do
    before do
      @active = @course.learning_outcome_groups.create!(title: "active")
      @archived = @course.learning_outcome_groups.create!(title: "archived")
      @archived.archive!
      @deleted = @course.learning_outcome_groups.create!(title: "deleted")
      @deleted.destroy!
    end

    it "active does not include archived or deleted groups" do
      expect(LearningOutcomeGroup.active.include?(@active)).to be true
      expect(LearningOutcomeGroup.active.include?(@archived)).to be false
      expect(LearningOutcomeGroup.active.include?(@deleted)).to be false
    end

    it "active includes unarchived groups" do
      expect(LearningOutcomeGroup.active.include?(@archived)).to be false
      @archived.unarchive!
      expect(LearningOutcomeGroup.active.include?(@archived)).to be true
    end

    it "archived only includes archived groups" do
      expect(LearningOutcomeGroup.archived.include?(@active)).to be false
      expect(LearningOutcomeGroup.archived.include?(@archived)).to be true
      expect(LearningOutcomeGroup.archived.include?(@deleted)).to be false
    end

    it "archived does not include unarchived groups" do
      expect(LearningOutcomeGroup.archived.include?(@archived)).to be true
      @archived.unarchive!
      expect(LearningOutcomeGroup.archived.include?(@archived)).to be false
    end
  end
end

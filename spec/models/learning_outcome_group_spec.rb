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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe LearningOutcomeGroup do

  before :each do
    course_factory
    @root = @course.root_outcome_group
  end

  def long_text(max = 65535)
    text = ''
    (0...max+1).each do |num|
      text.concat(num.to_s)
    end
    text
  end

  context 'object creation' do
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
      group = @course.learning_outcome_groups.create!(:title => 'groupage')
      group2 = @course.learning_outcome_groups.create!(:title => 'groupage2')
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
      group = @course.learning_outcome_groups.create!(:title => 'groupage')
      group.add_outcome @course.created_learning_outcomes.create!(:title => 'o1')
      group.add_outcome @course.created_learning_outcomes.create!(:title => 'o2')
      group.add_outcome @course.created_learning_outcomes.create!(:title => 'o3')

      time = 1.hour.ago
      Course.where(:id => @course).update_all(:updated_at => time)

      group.skip_tag_touch = true
      group.destroy

      expect(@course.reload.updated_at.to_i).to eq time.to_i
    end

    it 'validates presense of title' do
      expect{ @course.learning_outcome_groups.create! }.to raise_error(
        ActiveRecord::RecordInvalid, "Validation failed: Title can't be blank"
      )
    end

    it 'validates length of title' do
      expect{ @course.learning_outcome_groups.create!(title: long_text(255)) }.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Title is too long (maximum is 255 characters)"
      )
    end

    it 'validates length of description' do
      expect{ @course.learning_outcome_groups.create!(title: 'foobar', description: long_text) }.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Description is too long (maximum is 65,535 characters)"
      )
    end
  end

  describe '#parent_ids' do
    it 'returns non-empty array' do
      group = @course.learning_outcome_groups.create!(:title => 'groupage')

      expect(group.parent_ids).to be_a_kind_of(Array)
      expect(group.parent_ids).not_to be_empty
    end

    it 'correctly references parents' do
      group1 = @course.learning_outcome_groups.create!(:title => 'group1')
      group2 = @course.learning_outcome_groups.create!(:title => 'group2')
      child_outcome_group = group1.add_outcome_group(group2)

      expect(child_outcome_group.parent_ids).to include(group1.id)
    end
  end

  describe '#add_outcome' do
    it 'creates a link between the group and an outcome' do
      group = @course.learning_outcome_groups.create!(:title => 'groupage')
      outcome = @course.created_learning_outcomes.create!(:title => 'o1')

      expect(group.child_outcome_links.map(&:content_id)).not_to include(outcome.id)
      group.add_outcome(outcome)
      expect(group.child_outcome_links.map(&:content_id)).to include(outcome.id)
    end

    it 'no-ops if a link already exists' do
      group = @course.learning_outcome_groups.create!(:title => 'groupage')
      outcome = @course.created_learning_outcomes.create!(:title => 'o1')

      group.add_outcome(outcome)
      expect(group.child_outcome_links.count).to eq(1)

      group.add_outcome(outcome)
      expect(group.child_outcome_links.count).to eq(1)
    end
  end

  describe '#add_outcome_group' do
    it 'adds a child outcome group and copies all contents' do
      group1 = @course.learning_outcome_groups.create!(:title => 'group1')
      group2 = @course.learning_outcome_groups.create!(:title => 'group2')
      outcome1 = @course.created_learning_outcomes.create!(:title => 'o1')
      group2.add_outcome(outcome1)

      expect(group1.child_outcome_groups).to be_empty

      child_outcome_group = group1.add_outcome_group(group2)

      expect(child_outcome_group.title).to eq(group2.title)
      expect(child_outcome_group.child_outcome_links.map(&:content_id)).to eq(
        group2.child_outcome_links.map(&:content_id)
      )
    end
  end

  describe '#adopt_outcome_link' do
    it 'moves an existing outcome link from to this group if groups in same context' do
      group1 = @course.learning_outcome_groups.create!(:title => 'group1')
      group2 = @course.learning_outcome_groups.create!(:title => 'group2')
      outcome = @course.created_learning_outcomes.create!(:title => 'o1')
      outcome_link = group2.add_outcome(outcome)

      expect(outcome_link.associated_asset).to eq(group2)

      group1.adopt_outcome_link(outcome_link)

      expect(outcome_link.associated_asset).to eq(group1)
    end

    it 'no-ops if group is already owner' do
      group1 = @course.learning_outcome_groups.create!(:title => 'group1')
      outcome = @course.created_learning_outcomes.create!(:title => 'o1')
      outcome_link = group1.add_outcome(outcome)

      expect(outcome_link.associated_asset).to eq(group1)

      expect{ group1.adopt_outcome_link(outcome_link) }.
        not_to change{ outcome_link.associated_asset }
    end
  end

  describe '#adopt_outcome_group' do
    it 'moves an existing outcome link from to this group if groups in same context' do
      group1 = @course.learning_outcome_groups.create!(:title => 'group1')
      group2 = @course.learning_outcome_groups.create!(:title => 'group2')

      expect(group2.parent_outcome_group).not_to eq(group1)

      group1.adopt_outcome_group(group2)

      expect(group2.parent_outcome_group).to eq(group1)
    end

    it 'no-ops if group is already parent' do
      group1 = @course.learning_outcome_groups.create!(:title => 'group1')

      expect{ group1.adopt_outcome_group(group1) }.
        not_to change{ group1.learning_outcome_group_id }
    end
  end

  describe '.for_context' do
    it 'returns all learning outcome groups for a context' do
      group1 = @course.learning_outcome_groups.create!(:title => 'group1')
      expect(LearningOutcomeGroup.for_context(@course)).to include(group1)
    end
  end

  describe '.global_root_outcome_group' do
    it 'finds or creates a root outcome group' do
      expect(LearningOutcomeGroup.global_root_outcome_group.title).to eq("ROOT")
      expect(LearningOutcomeGroup.global_root_outcome_group.parent_outcome_group).to be_nil
    end
  end

  describe '.find_or_create_root' do
    it 'finds or creates a root outcome group of a given context' do
      root = LearningOutcomeGroup.find_or_create_root(nil, true)
      expect(root.title).to eq("ROOT")

      course_root = LearningOutcomeGroup.find_or_create_root(@course, true)
      expect(course_root.title).to eq("Unnamed Course")

      expect(root).not_to eq(course_root)
    end
  end

  describe '#destroy' do
    it 'destroys all children links' do
      group1 = @course.learning_outcome_groups.create!(:title => 'group1')
      group2 = @course.learning_outcome_groups.create!(:title => 'group2')
      outcome1 = @course.created_learning_outcomes.create!(:title => 'o1')
      outcome2 = @course.created_learning_outcomes.create!(:title => 'o2')

      group1.add_outcome(outcome1)
      group2.add_outcome(outcome2)
      group1.add_outcome_group(group2)

      active_child_outcomes = group1.child_outcome_links.select{|ol| ol.workflow_state == "active"}
      active_child_groups = group1.child_outcome_groups.active
      expect(active_child_outcomes).not_to be_empty
      expect(active_child_groups).not_to be_empty

      group1.destroy
      group1.reload

      active_child_outcomes = group1.child_outcome_links.select{|ol| ol.workflow_state == "active"}
      active_child_groups = group1.child_outcome_groups.active
      expect(group1.workflow_state).to eq('deleted')
      expect(active_child_outcomes).to be_empty
      expect(active_child_groups).to be_empty
    end
  end

  context 'enable new guid columns' do
    before :once do
      course_factory
      @group = @course.learning_outcome_groups.create!(:title => 'groupage')
    end

    it "should read vendor_guid_2" do
      AcademicBenchmark.stubs(:use_new_guid_columns?).returns(false)
      expect(@group.vendor_guid).to be_nil
      @group.vendor_guid = "GUID-XXXX"
      @group.save!
      expect(@group.vendor_guid).to eql "GUID-XXXX"
      AcademicBenchmark.stubs(:use_new_guid_columns?).returns(true)
      expect(@group.vendor_guid).to eql "GUID-XXXX"
      @group.write_attribute('vendor_guid_2', "GUID-YYYY")
      expect(@group.vendor_guid).to eql "GUID-YYYY"
      AcademicBenchmark.stubs(:use_new_guid_columns?).returns(false)
      expect(@group.vendor_guid).to eql "GUID-XXXX"
    end

    it "should read migration_id_2" do
      AcademicBenchmark.stubs(:use_new_guid_columns?).returns(false)
      expect(@group.migration_id).to be_nil
      @group.migration_id = "GUID-XXXX"
      @group.save!
      expect(@group.migration_id).to eql "GUID-XXXX"
      AcademicBenchmark.stubs(:use_new_guid_columns?).returns(true)
      expect(@group.migration_id).to eql "GUID-XXXX"
      @group.write_attribute('migration_id_2', "GUID-YYYY")
      expect(@group.migration_id).to eql "GUID-YYYY"
      AcademicBenchmark.stubs(:use_new_guid_columns?).returns(false)
      expect(@group.migration_id).to eql "GUID-XXXX"
    end
  end
end

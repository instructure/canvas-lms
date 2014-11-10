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

describe StickySisFields do
  it 'should set sis stickiness for changed fields' do
    ac = AbstractCourse.create!(:name => "1",
                                :short_name => "2",
                                :account => Account.default,
                                :root_account => Account.default,
                                :enrollment_term => Account.default.default_enrollment_term)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.name = "3"
    ac.sis_source_id = "4"
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.short_name = "5"
    ac.name = "1"
    expect(ac.stuck_sis_fields).to eq [:short_name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:short_name].to_set
    ac.reload
    expect(ac.stuck_sis_fields).to eq [:short_name].to_set
    ac.name = "3"
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.reload
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.clear_sis_stickiness(:short_name)
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.reload
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.clear_sis_stickiness(:name, :crap)
    ac.add_sis_stickiness(:name)
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.reload
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.add_sis_stickiness(:name, :crap)
    ac.clear_sis_stickiness(:name)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.reload
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.stuck_sis_fields = [:name, :short_name, :crap]
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.reload
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
  end

  it 'should set sis stickiness for changed fields without reloading' do
    ac = AbstractCourse.create!(:name => "1",
                                :short_name => "2",
                                :account => Account.default,
                                :root_account => Account.default,
                                :enrollment_term => Account.default.default_enrollment_term)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.name = "3"
    ac.sis_source_id = "4"
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.short_name = "5"
    ac.name = "1"
    expect(ac.stuck_sis_fields).to eq [:short_name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:short_name].to_set
    ac.name = "3"
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.clear_sis_stickiness(:short_name)
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.clear_sis_stickiness(:name, :crap)
    ac.add_sis_stickiness(:name)
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.add_sis_stickiness(:name, :crap)
    ac.clear_sis_stickiness(:name)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [].to_set
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.stuck_sis_fields = [:name, :short_name, :crap]
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
  end

  it 'should set sis stickiness for changed fields with new models' do
    ac = AbstractCourse.create!(:name => "1",
                                :short_name => "2",
                                :account => Account.default,
                                :root_account => Account.default,
                                :enrollment_term => Account.default.default_enrollment_term)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.name = "3"
    ac.sis_source_id = "4"
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.short_name = "5"
    ac.name = "1"
    expect(ac.stuck_sis_fields).to eq [:short_name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:short_name].to_set
    ac = AbstractCourse.find(ac.id)
    expect(ac.stuck_sis_fields).to eq [:short_name].to_set
    ac.name = "3"
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac = AbstractCourse.find(ac.id)
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.clear_sis_stickiness(:short_name)
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac = AbstractCourse.find(ac.id)
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.clear_sis_stickiness(:name, :crap)
    ac.add_sis_stickiness(:name)
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac = AbstractCourse.find(ac.id)
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.add_sis_stickiness(:name, :crap)
    ac.clear_sis_stickiness(:name)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac = AbstractCourse.find(ac.id)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.stuck_sis_fields = [:name, :short_name, :crap]
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac = AbstractCourse.find(ac.id)
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
  end

  context 'clear_sis_stickiness' do
    it 'should clear out fields that are in the saved list' do
      ac = AbstractCourse.create!(:name => "1",
                                  :short_name => "2",
                                  :account => Account.default,
                                  :root_account => Account.default,
                                  :enrollment_term => Account.default.default_enrollment_term)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.name = "ac name"
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.clear_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [].to_set
    end

    it 'should clear out fields that are in the stuck list' do
      ac = AbstractCourse.create!(:name => "1",
                                  :short_name => "2",
                                  :account => Account.default,
                                  :root_account => Account.default,
                                  :enrollment_term => Account.default.default_enrollment_term)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.add_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.clear_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [].to_set
    end

    it 'should ignore fields that already unstuck' do
      ac = AbstractCourse.create!(:name => "1",
                                  :short_name => "2",
                                  :account => Account.default,
                                  :root_account => Account.default,
                                  :enrollment_term => Account.default.default_enrollment_term)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.name = "ac name"
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.clear_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.clear_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.clear_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [].to_set
    end
  end

  context 'add_sis_stickiness' do
    it 'should ignore fields that are in the saved list' do
      ac = AbstractCourse.create!(:name => "1",
                                  :short_name => "2",
                                  :account => Account.default,
                                  :root_account => Account.default,
                                  :enrollment_term => Account.default.default_enrollment_term)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.name = "ac name"
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.add_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
    end

    it 'should ignore fields that are in the stuck list' do
      ac = AbstractCourse.create!(:name => "1",
                                  :short_name => "2",
                                  :account => Account.default,
                                  :root_account => Account.default,
                                  :enrollment_term => Account.default.default_enrollment_term)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.add_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.add_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
    end

    it 'should add fields that are in the unstuck list' do
      ac = AbstractCourse.create!(:name => "1",
                                  :short_name => "2",
                                  :account => Account.default,
                                  :root_account => Account.default,
                                  :enrollment_term => Account.default.default_enrollment_term)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.name = "ac name"
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.clear_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.add_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
    end

    it "should add fields that aren't anywhere yet" do
      ac = AbstractCourse.create!(:name => "1",
                                  :short_name => "2",
                                  :account => Account.default,
                                  :root_account => Account.default,
                                  :enrollment_term => Account.default.default_enrollment_term)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.add_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
    end
  end

  it "should only write to the database when there's a change" do
    ac = AbstractCourse.create!(:name => "1",
                                :short_name => "2",
                                :account => Account.default,
                                :root_account => Account.default,
                                :enrollment_term => Account.default.default_enrollment_term)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.stubs(:write_attribute).with(any_parameters)
    ac.expects(:write_attribute).with(:stuck_sis_fields, anything).never
    ac.save!
    ac.add_sis_stickiness(:name)
    ac.clear_sis_stickiness(:name)
    ac.save!
    ac.add_sis_stickiness(:name)
    ac.expects(:write_attribute).with(:stuck_sis_fields, 'name').once
    ac.save!
  end

  it "should always return an empty list and not run callbacks when just overriding" do
    ac = AbstractCourse.create!(:name => "1",
                                :short_name => "2",
                                :account => Account.default,
                                :root_account => Account.default,
                                :enrollment_term => Account.default.default_enrollment_term)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.name = "ac name"
    ac.save!
    expect(AbstractCourse.find(ac.id).stuck_sis_fields).to eq [:name].to_set
    AbstractCourse.process_as_sis :override_sis_stickiness => true do
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [].to_set
      expect(ac.send(:calculate_currently_stuck_sis_fields)).to eq [:name].to_set
      ac.short_name = "ac short name"
      expect(ac.stuck_sis_fields).to eq [].to_set
      expect(ac.send(:calculate_currently_stuck_sis_fields)).to eq [:name, :short_name].to_set
      ac.save!
    end
    expect(AbstractCourse.find(ac.id).stuck_sis_fields).to eq [:name].to_set
  end

  it "should always return an empty list and run callbacks when overriding and adding" do
    ac = AbstractCourse.create!(:name => "1",
                                :short_name => "2",
                                :account => Account.default,
                                :root_account => Account.default,
                                :enrollment_term => Account.default.default_enrollment_term)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.name = "ac name"
    ac.save!
    expect(AbstractCourse.find(ac.id).stuck_sis_fields).to eq [:name].to_set
    AbstractCourse.process_as_sis :override_sis_stickiness => true, :add_sis_stickiness => true do
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [].to_set
      expect(ac.send(:calculate_currently_stuck_sis_fields)).to eq [:name].to_set
      ac.short_name = "ac short name"
      expect(ac.stuck_sis_fields).to eq [].to_set
      expect(ac.send(:calculate_currently_stuck_sis_fields)).to eq [:name, :short_name].to_set
      ac.save!
    end
    expect(AbstractCourse.find(ac.id).stuck_sis_fields).to eq [:name, :short_name].to_set
  end

  it "should always return an empty list and run callbacks when overriding and clearing" do
    ac = AbstractCourse.create!(:name => "1",
                                :short_name => "2",
                                :account => Account.default,
                                :root_account => Account.default,
                                :enrollment_term => Account.default.default_enrollment_term)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.name = "ac name"
    ac.save!
    expect(AbstractCourse.find(ac.id).stuck_sis_fields).to eq [:name].to_set
    AbstractCourse.process_as_sis :override_sis_stickiness => true, :clear_sis_stickiness => true do
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [].to_set
      expect(ac.send(:calculate_currently_stuck_sis_fields)).to eq [:name].to_set
      ac.short_name = "ac short name"
      expect(ac.stuck_sis_fields).to eq [].to_set
      expect(ac.send(:calculate_currently_stuck_sis_fields)).to eq [:name, :short_name].to_set
      ac.save!
    end
    expect(AbstractCourse.find(ac.id).stuck_sis_fields).to eq [].to_set
  end

  it "should allow setting via stuck_sis_fields=" do
    ac = AbstractCourse.create!(:name => "1",
                                :short_name => "2",
                                :account => Account.default,
                                :root_account => Account.default,
                                :enrollment_term => Account.default.default_enrollment_term)
    ac.stuck_sis_fields = [:name]
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.save!
    ac = AbstractCourse.find(ac.id)
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.stuck_sis_fields = []
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.save!
    ac = AbstractCourse.find(ac.id)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.stuck_sis_fields = [:name]
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.save!
    ac = AbstractCourse.find(ac.id)
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.stuck_sis_fields = [:short_name]
    expect(ac.stuck_sis_fields).to eq [:short_name].to_set
    ac.save!
    ac = AbstractCourse.find(ac.id)
    expect(ac.stuck_sis_fields).to eq [:short_name].to_set
  end

  context "clear_sis_stickiness option" do
    it "should clear out the saved list" do
      ac = AbstractCourse.create!(:name => "1",
                                  :short_name => "2",
                                  :account => Account.default,
                                  :root_account => Account.default,
                                  :enrollment_term => Account.default.default_enrollment_term)
      ac.stuck_sis_fields = [:name]
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      AbstractCourse.process_as_sis :clear_sis_stickiness => true do
        AbstractCourse.find(ac.id).save!
      end
      expect(AbstractCourse.find(ac.id).stuck_sis_fields).to eq [].to_set
    end

    it "should clear out the work lists and cache" do
      ac = AbstractCourse.create!(:name => "1",
                                  :short_name => "2",
                                  :account => Account.default,
                                  :root_account => Account.default,
                                  :enrollment_term => Account.default.default_enrollment_term)
      ac.add_sis_stickiness :name
      ac.save!
      ac.stuck_sis_fields = [:short_name]
      expect(ac.instance_variable_get(:@sis_fields_to_stick)).to eq [:short_name].to_set
      expect(ac.instance_variable_get(:@sis_fields_to_unstick)).to eq [:name].to_set
      expect(ac.send(:load_stuck_sis_fields_cache)).to eq [:name].to_set
      AbstractCourse.process_as_sis :clear_sis_stickiness => true do
        ac.save!
      end
      expect(ac.instance_variable_get(:@sis_fields_to_stick)).to eq [].to_set
      expect(ac.instance_variable_get(:@sis_fields_to_unstick)).to eq [].to_set
      expect(ac.send(:load_stuck_sis_fields_cache)).to eq [].to_set
      expect(ac.stuck_sis_fields).to eq [].to_set
    end
  end

  it "should only process changed fields marked as sticky" do
    old_sticky_sis_fields = AbstractCourse.sticky_sis_fields
    begin
      ac = AbstractCourse.create!(:name => "1",
                                  :short_name => "2",
                                  :account => Account.default,
                                  :root_account => Account.default,
                                  :enrollment_term => Account.default.default_enrollment_term)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.save!
      ac.reload
      ac.name = "name 2"
      ac.short_name = "name 3"
      ac.sis_source_id = "name 4"
      expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
      ac.save!
      ac.reload
      expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
      ac.stuck_sis_fields = [].to_set
      ac.save!
      ac.reload
      expect(ac.stuck_sis_fields).to eq [].to_set
      AbstractCourse.are_sis_sticky :name, :short_name, :sis_source_id
      expect(AbstractCourse.sticky_sis_fields).to eq [:name, :short_name, :sis_source_id].to_set
      ac.name = "name 5"
      ac.short_name = "name 6"
      ac.sis_source_id = "name 7"
      expect(ac.stuck_sis_fields).to eq [:name, :short_name, :sis_source_id].to_set
    ensure
      AbstractCourse.sticky_sis_fields = old_sticky_sis_fields
      expect(AbstractCourse.sticky_sis_fields).to eq old_sticky_sis_fields
    end
  end

  it "should leave fields (that may be invalid) in the db alone if untouched" do
    old_sticky_sis_fields = AbstractCourse.sticky_sis_fields
    begin
      ac = AbstractCourse.create!(:name => "1",
                                  :short_name => "2",
                                  :account => Account.default,
                                  :root_account => Account.default,
                                  :enrollment_term => Account.default.default_enrollment_term)
      AbstractCourse.are_sis_sticky :name, :short_name, :sis_source_id
      expect(AbstractCourse.sticky_sis_fields).to eq [:name, :short_name, :sis_source_id].to_set
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.save!
      ac.reload
      ac.name = "name 3"
      ac.sis_source_id = "name 4"
      expect(ac.stuck_sis_fields).to eq [:name, :sis_source_id].to_set
      ac.save!
      AbstractCourse.are_sis_sticky :name, :short_name
      ac.reload
      expect(ac.stuck_sis_fields).to eq [:name, :sis_source_id].to_set
      ac.short_name = "name 2"
      expect(ac.stuck_sis_fields).to eq [:name, :short_name, :sis_source_id].to_set
      ac.clear_sis_stickiness :name
      expect(ac.stuck_sis_fields).to eq [:short_name, :sis_source_id].to_set
      ac.save!
      ac = AbstractCourse.find ac.id
      expect(ac.stuck_sis_fields).to eq [:short_name, :sis_source_id].to_set
    ensure
      AbstractCourse.sticky_sis_fields = old_sticky_sis_fields
      expect(AbstractCourse.sticky_sis_fields).to eq old_sticky_sis_fields
    end
  end

  it "should allow removing changed fields" do
    ac = AbstractCourse.create!(:name => "1",
                                :short_name => "2",
                                :account => Account.default,
                                :root_account => Account.default,
                                :enrollment_term => Account.default.default_enrollment_term)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.name = "name 2"
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.clear_sis_stickiness :name
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.save!
    ac = AbstractCourse.find ac.id
    expect(ac.stuck_sis_fields).to eq [].to_set
  end

  it "should allow removing changed and added fields" do
    ac = AbstractCourse.create!(:name => "1",
                                :short_name => "2",
                                :account => Account.default,
                                :root_account => Account.default,
                                :enrollment_term => Account.default.default_enrollment_term)
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.add_sis_stickiness :name
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.name = "name 2"
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.clear_sis_stickiness :name
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.save!
    ac = AbstractCourse.find ac.id
    expect(ac.stuck_sis_fields).to eq [].to_set
  end

  context "process_as_sis" do
    it "should work nested (should save and restore options)" do
      old_sis_stickiness_options = {}
      begin
        AbstractCourse.sis_stickiness_options = {}
        AbstractCourse.process_as_sis do
          expect(AbstractCourse.sis_stickiness_options).to eq({:override_sis_stickiness => nil, :clear_sis_stickiness => nil})
          AbstractCourse.process_as_sis :override_sis_stickiness => true do
            expect(AbstractCourse.sis_stickiness_options).to eq({:override_sis_stickiness => true, :clear_sis_stickiness => nil})
            AbstractCourse.process_as_sis :clear_sis_stickiness => true do
              expect(AbstractCourse.sis_stickiness_options).to eq({:clear_sis_stickiness => true, :override_sis_stickiness => nil})
            end
            expect(AbstractCourse.sis_stickiness_options).to eq({:override_sis_stickiness => true, :clear_sis_stickiness => nil})
          end
          expect(AbstractCourse.sis_stickiness_options).to eq({:override_sis_stickiness => nil, :clear_sis_stickiness => nil})
        end
        expect(AbstractCourse.sis_stickiness_options).to eq({})
      ensure
        AbstractCourse.sis_stickiness_options = old_sis_stickiness_options
        expect(AbstractCourse.sis_stickiness_options).to eq old_sis_stickiness_options
      end
    end

    it "should fire the callback in the right scenarios" do
      class AbstractCourse
        cattr_accessor :callback_counts
        def self.count_callback(callback)
          self.callback_counts ||= {}
          method = instance_method(callback)
          begin
            remove_method(callback)
            should_redefine_original_callback = true
          rescue NameError => e
            raise e unless "#{e}" =~ /method `#{Regexp.escape callback.to_s}' not defined in #{Regexp.escape self.name}/
            should_redefine_original_callback = false
          end
          self.callback_counts[callback] = 0
          define_method(callback) do
            self.callback_counts[callback] += 1
          end
          begin
            yield
          ensure
            remove_method(callback)
            define_method(callback, method) if should_redefine_original_callback
          end
        end
      end

      ac = AbstractCourse.create!(:name => "1",
                                  :short_name => "2",
                                  :account => Account.default,
                                  :root_account => Account.default,
                                  :enrollment_term => Account.default.default_enrollment_term)
      AbstractCourse.count_callback(:set_sis_stickiness) do
        ac.save!
        expect(AbstractCourse.callback_counts[:set_sis_stickiness]).to eq 1
        AbstractCourse.process_as_sis do
          ac.save!
        end
        expect(AbstractCourse.callback_counts[:set_sis_stickiness]).to eq 1
        AbstractCourse.process_as_sis :override_sis_stickiness => true do
          ac.save!
        end
        expect(AbstractCourse.callback_counts[:set_sis_stickiness]).to eq 1
        AbstractCourse.process_as_sis :clear_sis_stickiness => true do
          ac.save!
        end
        expect(AbstractCourse.callback_counts[:set_sis_stickiness]).to eq 2
        AbstractCourse.process_as_sis :add_sis_stickiness => true do
          ac.save!
        end
        expect(AbstractCourse.callback_counts[:set_sis_stickiness]).to eq 3
      end
    end
  end

end

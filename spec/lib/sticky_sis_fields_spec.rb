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

describe StickySisFields do
  def create_abstract_course
    AbstractCourse.process_as_sis do
      AbstractCourse.create!(name: "1",
                             short_name: "2",
                             account: Account.default,
                             root_account: Account.default,
                             enrollment_term: Account.default.default_enrollment_term)
    end
  end

  it "sets sis stickiness for changed fields" do
    ac = create_abstract_course
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
    ac.stuck_sis_fields = %i[name short_name crap]
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.reload
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
  end

  it "sets sis stickiness for changed fields without reloading" do
    ac = create_abstract_course
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
    ac.stuck_sis_fields = %i[name short_name crap]
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
  end

  it "sets sis stickiness for changed fields with new models" do
    ac = create_abstract_course
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
    ac.stuck_sis_fields = %i[name short_name crap]
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac.save!
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
    ac = AbstractCourse.find(ac.id)
    expect(ac.stuck_sis_fields).to eq [:name, :short_name].to_set
  end

  context "clear_sis_stickiness" do
    it "clears out fields that are in the saved list" do
      ac = create_abstract_course
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

    it "clears out fields that are in the stuck list" do
      ac = create_abstract_course
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.add_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.clear_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [].to_set
    end

    it "ignores fields that already unstuck" do
      ac = create_abstract_course
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

  context "add_sis_stickiness" do
    it "ignores fields that are in the saved list" do
      ac = create_abstract_course
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

    it "ignores fields that are in the stuck list" do
      ac = create_abstract_course
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.add_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.add_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
    end

    it "adds fields that are in the unstuck list" do
      ac = create_abstract_course
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

    it "adds fields that aren't anywhere yet" do
      ac = create_abstract_course
      expect(ac.stuck_sis_fields).to eq [].to_set
      ac.add_sis_stickiness(:name)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
    end
  end

  it "doesn't write to the database when there's not a change" do
    ac = create_abstract_course
    expect(ac.stuck_sis_fields).to eq [].to_set
    expect(ac).not_to receive(:write_attribute).with(:stuck_sis_fields, anything)
    ac.save!
    ac.add_sis_stickiness(:name)
    ac.clear_sis_stickiness(:name)
    ac.save!
  end

  it "writes to the database when there's a change" do
    ac = create_abstract_course
    ac.add_sis_stickiness(:name)
    expect(ac).to receive(:write_attribute).with(:workflow_state, "active")
    allow(ac).to receive(:write_attribute).with("root_account_id", Account.default.id)
    allow(ac).to receive(:write_attribute).with("account_id", Account.default.id)
    allow(ac).to receive(:write_attribute).with("enrollment_term_id", Account.default.default_enrollment_term.id)
    expect(ac).to receive(:write_attribute).with(:stuck_sis_fields, "name")
    ac.save!
  end

  it "always returns an empty list and not run callbacks when just overriding" do
    ac = create_abstract_course
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.name = "ac name"
    ac.save!
    expect(AbstractCourse.find(ac.id).stuck_sis_fields).to eq [:name].to_set
    AbstractCourse.process_as_sis override_sis_stickiness: true do
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

  it "always returns an empty list and run callbacks when overriding and adding" do
    ac = create_abstract_course
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.name = "ac name"
    ac.save!
    expect(AbstractCourse.find(ac.id).stuck_sis_fields).to eq [:name].to_set
    AbstractCourse.process_as_sis override_sis_stickiness: true, add_sis_stickiness: true do
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

  it "always returns an empty list and run callbacks when overriding and clearing" do
    ac = create_abstract_course
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.name = "ac name"
    ac.save!
    expect(AbstractCourse.find(ac.id).stuck_sis_fields).to eq [:name].to_set
    AbstractCourse.process_as_sis override_sis_stickiness: true, clear_sis_stickiness: true do
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

  it "allows setting via stuck_sis_fields=" do
    ac = create_abstract_course
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
    it "clears out the saved list" do
      ac = create_abstract_course
      ac.stuck_sis_fields = [:name]
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      ac.save!
      ac = AbstractCourse.find(ac.id)
      expect(ac.stuck_sis_fields).to eq [:name].to_set
      AbstractCourse.process_as_sis clear_sis_stickiness: true do
        AbstractCourse.find(ac.id).save!
      end
      expect(AbstractCourse.find(ac.id).stuck_sis_fields).to eq [].to_set
    end

    it "clears out the work lists and cache" do
      ac = create_abstract_course
      ac.add_sis_stickiness :name
      ac.save!
      ac.stuck_sis_fields = [:short_name]
      expect(ac.instance_variable_get(:@sis_fields_to_stick)).to eq [:short_name].to_set
      expect(ac.instance_variable_get(:@sis_fields_to_unstick)).to eq [:name].to_set
      expect(ac.send(:load_stuck_sis_fields_cache)).to eq [:name].to_set
      AbstractCourse.process_as_sis clear_sis_stickiness: true do
        ac.save!
      end
      expect(ac.instance_variable_get(:@sis_fields_to_stick)).to eq [].to_set
      expect(ac.instance_variable_get(:@sis_fields_to_unstick)).to eq [].to_set
      expect(ac.send(:load_stuck_sis_fields_cache)).to eq [].to_set
      expect(ac.stuck_sis_fields).to eq [].to_set
    end
  end

  it "only processes changed fields marked as sticky" do
    old_sticky_sis_fields = AbstractCourse.sticky_sis_fields
    begin
      ac = create_abstract_course
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
      expect(AbstractCourse.sticky_sis_fields).to eq %i[name short_name sis_source_id].to_set
      ac.name = "name 5"
      ac.short_name = "name 6"
      ac.sis_source_id = "name 7"
      expect(ac.stuck_sis_fields).to eq %i[name short_name sis_source_id].to_set
    ensure
      AbstractCourse.sticky_sis_fields = old_sticky_sis_fields
      expect(AbstractCourse.sticky_sis_fields).to eq old_sticky_sis_fields
    end
  end

  it "leaves fields (that may be invalid) in the db alone if untouched" do
    old_sticky_sis_fields = AbstractCourse.sticky_sis_fields
    begin
      ac = create_abstract_course
      AbstractCourse.are_sis_sticky :name, :short_name, :sis_source_id
      expect(AbstractCourse.sticky_sis_fields).to eq %i[name short_name sis_source_id].to_set
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
      expect(ac.stuck_sis_fields).to eq %i[name short_name sis_source_id].to_set
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

  it "allows removing changed fields" do
    ac = create_abstract_course
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.name = "name 2"
    expect(ac.stuck_sis_fields).to eq [:name].to_set
    ac.clear_sis_stickiness :name
    expect(ac.stuck_sis_fields).to eq [].to_set
    ac.save!
    ac = AbstractCourse.find ac.id
    expect(ac.stuck_sis_fields).to eq [].to_set
  end

  it "allows removing changed and added fields" do
    ac = create_abstract_course
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
    it "works nested (should save and restore options)" do
      old_sis_stickiness_options = {}
      begin
        AbstractCourse.sis_stickiness_options = {}
        AbstractCourse.process_as_sis do
          expect(AbstractCourse.sis_stickiness_options).to eq({})
          AbstractCourse.process_as_sis override_sis_stickiness: true do
            expect(AbstractCourse.sis_stickiness_options).to eq({ override_sis_stickiness: true })
            AbstractCourse.process_as_sis clear_sis_stickiness: true do
              expect(AbstractCourse.sis_stickiness_options).to eq({ clear_sis_stickiness: true })
            end
            expect(AbstractCourse.sis_stickiness_options).to eq({ override_sis_stickiness: true })
          end
          expect(AbstractCourse.sis_stickiness_options).to eq({})
        end
        expect(AbstractCourse.sis_stickiness_options).to eq({})
      ensure
        AbstractCourse.sis_stickiness_options = old_sis_stickiness_options
        expect(AbstractCourse.sis_stickiness_options).to eq old_sis_stickiness_options
      end
    end

    describe "callback firing" do
      before(:once) do
        @ac = AbstractCourse.create!(
          name: "1",
          short_name: "2",
          account: Account.default,
          root_account: Account.default,
          enrollment_term: Account.default.default_enrollment_term
        )
      end

      it "fires on normal save" do
        expect(@ac).to receive(:set_sis_stickiness).once
        @ac.save!
      end

      it "doesn't fire processing_as_sis with default args" do
        expect(@ac).not_to receive(:set_sis_stickiness)
        AbstractCourse.process_as_sis do
          @ac.save!
        end
      end

      it "doesn't fire processing_as_sis with sis_stickiness" do
        expect(@ac).not_to receive(:set_sis_stickiness)
        AbstractCourse.process_as_sis override_sis_stickiness: true do
          @ac.save!
        end
      end

      it "fires processing_as_sis and clearing sis_stickiness" do
        expect(@ac).to receive(:set_sis_stickiness).once
        AbstractCourse.process_as_sis clear_sis_stickiness: true do
          @ac.save!
        end
      end

      it "fires processing_as_sis and adding sis_stickiness" do
        expect(@ac).to receive(:set_sis_stickiness).once
        AbstractCourse.process_as_sis add_sis_stickiness: true do
          @ac.save!
        end
      end
    end
  end
end

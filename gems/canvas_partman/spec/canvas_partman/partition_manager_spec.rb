# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe CanvasPartman::PartitionManager do
  describe '.create' do
    it 'should whine if the target class is not Partitioned' do
      expect {
        CanvasPartman::PartitionManager.create(Object)
      }.to raise_error(ArgumentError, /can only work on models that are partitioned/i)
    end
  end

  context :by_date do
    subject { CanvasPartman::PartitionManager.create(Animal) }

    describe '#create_partition' do
      context 'precision = :months' do
        it 'creates a partition suffixed by YYYY_MM' do
          expect {
            subject.create_partition(Time.new(2014, 11))
          }.not_to raise_error

          expect(SchemaHelper.table_exists?('partman_animals_2014_11')).to be true
        end

        it 'creates multiple partitions' do
          subject.create_partition(Time.new(2014, 11, 5))
          subject.create_partition(Time.new(2014, 12, 5))

          expect(SchemaHelper.table_exists?('partman_animals_2014_11')).to be true
          expect(SchemaHelper.table_exists?('partman_animals_2014_12')).to be true
        end
      end

      it "brings along foreign keys" do
        subject.create_partition(Time.new(2014, 11))
        parent_foreign_key = Animal.connection.foreign_keys("partman_animals")[0]
        foreign_key = Animal.connection.foreign_keys("partman_animals_2014_11")[0]
        expect(foreign_key.to_table).to eq("partman_zoos")
        expect(foreign_key.options.except(:name)).to eq(parent_foreign_key.options.except(:name))
      end
    end

    describe "#ensure_partitions" do
      it "should create the proper number of partitions" do
        expect(subject).to receive(:partition_exists?).at_least(:once).and_return(false)
        expect(Time).to receive(:now).and_return(Time.utc(2015, 05, 02))
        expect(subject).to receive(:create_partition).with(Time.utc(2015, 05, 01))
        expect(subject).to receive(:create_partition).with(Time.utc(2015, 06, 01))

        subject.ensure_partitions(1)
      end
    end

    describe "#prune_partitions" do
      it "should prune the proper number of partitions" do
        expect(Time).to receive(:now).and_return(Time.utc(2015, 05, 02))
        expect(subject).to receive(:partition_tables).and_return(%w{
          partman_animals_2014_9
          partman_animals_2014_10
          partman_animals_2014_11
          partman_animals_2014_12
          partman_animals_2015_1
          partman_animals_2015_2
          partman_animals_2015_3
          partman_animals_2015_4
          partman_animals_2015_5
          partman_animals_2015_6
        })

        expect(subject.base_class.connection).to receive(:drop_table).with('partman_animals_2014_9')
        expect(subject.base_class.connection).to receive(:drop_table).with('partman_animals_2014_10')
        subject.prune_partitions(6)
      end

      it "prunes weekly partitions too" do
        expect(Time).to receive(:now).and_return(Time.utc(2015, 02, 05))
        allow(Animal).to receive(:partitioning_interval).and_return(:weeks)
        expect(subject).to receive(:partition_tables).and_return(%w{
          partman_animals_2015_01
          partman_animals_2015_02
          partman_animals_2015_03
          partman_animals_2015_04
          partman_animals_2015_05
          partman_animals_2015_06
        })

        expect(subject.base_class.connection).to receive(:drop_table).with('partman_animals_2015_01')
        expect(subject.base_class.connection).to receive(:drop_table).with('partman_animals_2015_02')
        subject.prune_partitions(3)
      end
    end
  end

  context "by_date + weeks" do
    subject { CanvasPartman::PartitionManager.create(WeekEvent) }

    describe '#create_partition' do
      it 'creates partitions suffixed by year and week number' do
        expect {
          subject.create_partition(Time.new(2018, 12, 24))
          subject.create_partition(Time.new(2018, 12, 31)) # beginning of next year's first week
          subject.create_partition(Time.new(2021, 1, 1)) # part of last year's 53rd week
        }.not_to raise_error

        expect(SchemaHelper.table_exists?('partman_week_events_2018_52')).to be true
        expect(SchemaHelper.table_exists?('partman_week_events_2019_01')).to be true
        expect(SchemaHelper.table_exists?('partman_week_events_2020_53')).to be true
      end
    end
  end

  context :by_id do
    subject { CanvasPartman::PartitionManager.create(Trail) }

    describe '#create_partition' do
      it 'creates multiple partitions' do
        subject.create_partition(0)
        subject.create_partition(5)

        expect(SchemaHelper.table_exists?('partman_trails_0')).to be true
        expect(SchemaHelper.table_exists?('partman_trails_1')).to be true
      end

      it "brings along foreign keys" do
        subject.create_partition(0)
        parent_foreign_key = Trail.connection.foreign_keys("partman_trails")[0]
        foreign_key = Trail.connection.foreign_keys("partman_trails_0")[0]
        expect(foreign_key.to_table).to eq("partman_zoos")
        expect(foreign_key.options.except(:name)).to eq(parent_foreign_key.options.except(:name))
      end

      it "uses timeout protection" do
        timeout_count = 0
        allow(Trail.connection).to receive(:execute) do |statement|
          timeout_count += 1 if statement =~ /SET LOCAL statement_timeout=90000/
        end
        subject.create_partition(0)
        expect(timeout_count).to eq(1)
      end
    end

    describe "#create_initial_partitions" do
      it "creates sufficient partitions" do
        expect(subject.base_class).to receive(:maximum).and_return(13)
        expect(subject).to receive(:create_partition).with(0, graceful: true)
        expect(subject).to receive(:create_partition).with(5, graceful: true)
        expect(subject).to receive(:create_partition).with(10, graceful: true)
        expect(subject).to receive(:create_partition).with(15, graceful: true)
        expect(subject).to receive(:create_partition).with(20, graceful: true)

        subject.create_initial_partitions(2)
      end
    end

    describe "#ensure_partitions" do
      it "creates the proper number of partitions" do
        expect(subject).to receive(:partition_tables).and_return([])
        expect(Zoo).to receive(:maximum).and_return(nil)
        expect(subject).to receive(:create_partition).with(0)
        expect(subject).to receive(:create_partition).with(5)

        subject.ensure_partitions(2)
      end

      it "detects when enough partitions already exist" do
        expect(subject).to receive(:partition_tables).and_return(['partman_trails_0', 'partman_trails_1'])
        expect(Zoo).to receive(:maximum).and_return(nil)
        expect(subject).to receive(:create_partition).never

        subject.ensure_partitions(2)
      end

      it "detects how many partitions are needed based on the foreign key table" do
        expect(subject).to receive(:partition_tables).and_return([])
        expect(Zoo).to receive(:maximum).and_return(7)

        expect(subject).to receive(:create_partition).with(0)
        expect(subject).to receive(:create_partition).with(5) # catches up
        expect(subject).to receive(:create_partition).with(10)
        expect(subject).to receive(:create_partition).with(15) # and adds two more

        subject.ensure_partitions(2)
      end
    end
  end

  describe '#with_timeout_protection' do
    it 'errors if the query goes beyond the timeout' do
      pm = CanvasPartman::PartitionManager.create(Trail)
      expect do
        pm.with_statement_timeout(timeout_override: 1) do
          pm.send(:execute, "select pg_sleep(5)")
        end
      end.to raise_error(ActiveRecord::QueryCanceled)
    end
  end
end

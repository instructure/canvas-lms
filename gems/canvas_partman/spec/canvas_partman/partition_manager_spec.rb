require 'spec_helper'
require 'fixtures/zoo'
require 'fixtures/animal'

describe CanvasPartman::PartitionManager do
  Zoo = CanvasPartmanTest::Zoo
  Animal = CanvasPartmanTest::Animal

  before :all do
    [ Zoo, Animal ].each(&:create_schema)
  end

  after :all do
    [ Zoo, Animal ].each(&:drop_schema)
  end

  subject { described_class.new(Animal) }

  describe '#initialize' do
    it 'should whine if the target class is not Partitioned' do
      expect {
        described_class.new(Object)
      }.to raise_error(ArgumentError, /can only work on models that are partitioned/i)
    end
  end

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
    end # precision = :months

    describe '#schema_builder' do
      it 'yields the adapter table and the table name' do
        subject.create_partition(Time.new(2014, 11)) do |t, table_name|
          expect(t).to respond_to(:integer)
          expect(t).to respond_to(:datetime)
          expect(t).to respond_to(:index)

          expect(table_name).to eq 'partman_animals_2014_11'
        end
      end

      it 'allows modification of partition tables' do
        subject.create_partition(Time.new(2014, 11, 8)) do |t|
          t.index :created_at, name: 'partman_animals_created_at'
        end

        index = find_index({
          name: 'partman_animals_created_at',
          table: 'partman_animals_2014_11'
        })

        expect(index).to be_present
      end

      it 'has no side-effects if the schema builder fails' do
        expect {
          subject.create_partition(Time.new(2014, 11)) do |t|
            raise 'something'
          end
        }.to raise_error

        expect(find_tables('partman_animals_2014_11').length).to be 0
      end
    end
  end
end
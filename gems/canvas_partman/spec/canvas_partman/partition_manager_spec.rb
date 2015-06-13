describe CanvasPartman::PartitionManager do
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
    end

    describe 'building schema' do
      require 'fixtures/db/20141103000000_add_foo_to_partman_animals'
      require 'fixtures/db/20141103000001_add_bar_to_partman_animals'
      require 'fixtures/db/20141103000002_remove_foo_from_partman_animals'

      it 'should apply all migrations' do
        expect(CanvasPartman).to receive(:migrations_path)
          .at_least(:once)
          .and_return('spec/fixtures/db')

        expect(CanvasPartman).to receive(:migrations_scope)
          .at_least(:once)
          .and_return('')

        subject.create_partition(Time.new(2014, 11, 5))

        expect(
          connection.column_exists?('partman_animals_2014_11', 'bar')
        ).to be_truthy
      end
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
  end
end
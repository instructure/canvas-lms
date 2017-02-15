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

  context :by_id do
    subject { CanvasPartman::PartitionManager.create(Trail) }

    describe '#create_partition' do
      it 'creates multiple partitions' do
        subject.create_partition(0)
        subject.create_partition(5)

        expect(SchemaHelper.table_exists?('partman_trails_0')).to be true
        expect(SchemaHelper.table_exists?('partman_trails_1')).to be true
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
        expect(subject).to receive(:create_partition).with(0)
        expect(subject).to receive(:create_partition).with(5)

        subject.ensure_partitions(2)
      end

      it "detects when enough partitions already exist" do
        expect(subject).to receive(:partition_tables).and_return(['partman_trails_0', 'partman_trails_1'])
        expect(subject.base_class).to receive(:from).twice.and_return(Trail.none)
        expect(subject).to receive(:create_partition).never

        subject.ensure_partitions(2)
      end
    end
  end
end

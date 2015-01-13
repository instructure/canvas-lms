describe CanvasPartman::Concerns::Partitioned do
  subject { CanvasPartman::PartitionManager.new(Animal) }

  describe 'creating records' do
    it 'should fail if the target partition does not exist' do
      expect {
        Animal.create!
      }.to raise_error ActiveRecord::StatementInvalid, /PG::UndefinedTable/
    end

    it 'creates multiple records in the proper partition tables' do
      subject.create_partition(Time.new(2014, 11))
      subject.create_partition(Time.new(2014, 12))

      Animal.create({ created_at: Time.new(2014, 11, 8) })
      Animal.create({ created_at: Time.new(2014, 11, 15) })
      Animal.create({ created_at: Time.new(2014, 12, 4) })

      expect(Animal.count).to eq 3

      expect(count_records('partman_animals')).to eq 3
      expect(count_records('partman_animals_2014_11')).to eq 2
      expect(count_records('partman_animals_2014_12')).to eq 1
    end

    context 'with UTC timestamps' do
      before do
        @original_tz = Time.zone
        Time.zone = "MST"
      end

      after do
        Time.zone = @original_tz
      end

      it 'should locate the correct partition table' do
        subject.create_partition(Time.new(2014, 12))
        subject.create_partition(Time.new(2015, 1))

        expect {
          # this would be at new years of 2015 in UTC: 1/1/2015 00:00:00
          Animal.create({
            created_at: Time.zone.local(2014, 12, 31, 17, 0, 0, 0)
          })
        }.not_to raise_error
      end
    end

    context 'via an association scope' do
      it 'works' do
        subject.create_partition(Time.new(2014, 11))
        subject.create_partition(Time.new(2014, 12))

        zoo = Zoo.create!

        monkey = zoo.animals.create!({
          race: 'monkey',
          created_at: Time.new(2014, 11, 5)
        })

        parrot = zoo.animals.create({
          race: 'parrot',
          created_at: Time.new(2014, 12, 5)
        })

        expect(count_records('partman_animals')).to eq 2
        expect(count_records('partman_animals_2014_11')).to eq 1
        expect(count_records('partman_animals_2014_12')).to eq 1

        expect(zoo.animals.count).to eq 2
        expect(monkey.zoo).to eq zoo
        expect(parrot.zoo).to eq zoo
      end
    end
  end

  describe 'updating records' do
    before do
      subject.create_partition(Time.new(2014, 11, 1))

      @pt = Animal.create({
        created_at: Time.new(2014, 11, 8),
        race: 'monkey'
      })
    end

    it 'works using #save' do
      @pt.race = 'bird'
      @pt.save!
      @pt.reload

      expect(@pt.race).to eq 'bird'
    end

    it 'works using #update_attribute' do
      @pt.update_attribute('race', 'gorilla')
      @pt.reload

      expect(@pt.race).to eq 'gorilla'
    end
  end

  describe 'removing records' do
    it 'works using #destroy! or scope#destroy_all' do
      subject.create_partition(Time.new(2014, 11, 1))
      subject.create_partition(Time.new(2014, 12, 1))

      pt1 = Animal.create({ created_at: Time.new(2014, 11, 8) })
      pt2 = Animal.create({ created_at: Time.new(2014, 11, 15) })
      pt3 = Animal.create({ created_at: Time.new(2014, 12, 4) })
      pt4 = Animal.create({ created_at: Time.new(2014, 12, 4) })

      expect(Animal.count).to eq 4

      expect(pt1.destroy).to be_truthy

      expect(Animal.count).to eq 3

      expect(Animal.where(id: pt4.id).destroy_all).to be_truthy

      expect(Animal.count).to eq 2
    end
  end
end
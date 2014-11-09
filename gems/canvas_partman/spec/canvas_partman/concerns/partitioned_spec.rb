require 'spec_helper'
require 'fixtures/zoo'
require 'fixtures/animal'

describe CanvasPartman::Concerns::Partitioned do
  Zoo = CanvasPartmanTest::Zoo
  Animal = CanvasPartmanTest::Animal

  before :all do
    [ Zoo, Animal ].each(&:create_schema)
  end

  after :all do
    [ Zoo, Animal ].each(&:drop_schema)
  end

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

      expect(find_records(table: 'partman_animals').length).to eq 3
      expect(find_records(table: 'partman_animals_2014_11').length).to eq 2
      expect(find_records(table: 'partman_animals_2014_12').length).to eq 1
    end

    context 'via an association scope' do
      it 'works' do
        subject.create_partition(Time.new(2014, 11))
        subject.create_partition(Time.new(2014, 12))

        zoo = Zoo.create!

        monkey = zoo.animals.create!({ race: 'monkey' })
        parrot = zoo.animals.create({
          race: 'parrot',
          created_at: Time.new(2014, 12, 5)
        })

        expect(find_records(table: 'partman_animals').length).to eq 2
        expect(find_records(table: 'partman_animals_2014_11').length).to eq 1
        expect(find_records(table: 'partman_animals_2014_12').length).to eq 1

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
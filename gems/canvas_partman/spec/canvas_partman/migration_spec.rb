describe CanvasPartman::Migration do
  require 'fixtures/db/20141103000000_add_foo_to_partman_animals'
  require 'fixtures/db/20141103000001_add_bar_to_partman_animals'
  require 'fixtures/db/20141103000002_remove_foo_from_partman_animals'
  require 'fixtures/db/20141103000003_add_another_thing_to_partman_animals'
  require 'fixtures/db/20141103000004_add_race_index_to_partman_animals'

  it 'should do nothing with no partitions' do
    Animal.transaction do
      AddFooToPartmanAnimals.new.migrate(:up)

      expect(
        connection.column_exists?('partman_animals', 'foo')
      ).to be_falsy

      AddFooToPartmanAnimals.new.migrate(:down)
    end
  end

  it 'should apply a migration on all partition tables' do
    partman = CanvasPartman::PartitionManager.new(Animal)
    partman.create_partition(Time.new(2014, 11))

    Animal.transaction do
      AddFooToPartmanAnimals.new.migrate(:up)

      expect(
        connection.column_exists?('partman_animals_2014_11', 'foo')
      ).to be_truthy

      AddFooToPartmanAnimals.new.migrate(:down)
    end
  end

  it 'should apply multiple migrations' do
    partman = CanvasPartman::PartitionManager.new(Animal)
    partman.create_partition(Time.new(2014, 11))

    Animal.transaction do
      AddFooToPartmanAnimals.new.migrate(:up)
      expect(
        connection.column_exists?('partman_animals_2014_11', 'foo')
      ).to be_truthy

      AddBarToPartmanAnimals.new.migrate(:up)
      expect(
        connection.column_exists?('partman_animals_2014_11', 'bar')
      ).to be_truthy

      RemoveFooFromPartmanAnimals.new.migrate(:up)
      expect(
        connection.column_exists?('partman_animals_2014_11', 'foo')
      ).to be_falsy

      RemoveFooFromPartmanAnimals.new.migrate(:down)
      expect(
        connection.column_exists?('partman_animals_2014_11', 'foo')
      ).to be_truthy

      AddBarToPartmanAnimals.new.migrate(:down)
      expect(
        connection.column_exists?('partman_animals_2014_11', 'bar')
      ).to be_falsy

      AddFooToPartmanAnimals.new.migrate(:down)
      expect(
        connection.column_exists?('partman_animals_2014_11', 'foo')
      ).to be_falsy
    end
  end

  it 'should apply multiple migrations on multiple partitions' do
    partman = CanvasPartman::PartitionManager.new(Animal)
    partman.create_partition(Time.new(2014, 11))
    partman.create_partition(Time.new(2014, 12))

    Animal.transaction do
      AddFooToPartmanAnimals.new.migrate(:up)
      expect(
        connection.column_exists?('partman_animals_2014_11', 'foo')
      ).to be_truthy
      expect(
        connection.column_exists?('partman_animals_2014_12', 'foo')
      ).to be_truthy

      AddBarToPartmanAnimals.new.migrate(:up)
      expect(
        connection.column_exists?('partman_animals_2014_11', 'bar')
      ).to be_truthy
      expect(
        connection.column_exists?('partman_animals_2014_12', 'bar')
      ).to be_truthy

      RemoveFooFromPartmanAnimals.new.migrate(:up)
      expect(
        connection.column_exists?('partman_animals_2014_11', 'foo')
      ).to be_falsy
      expect(
        connection.column_exists?('partman_animals_2014_12', 'foo')
      ).to be_falsy

      RemoveFooFromPartmanAnimals.new.migrate(:down)
      expect(
        connection.column_exists?('partman_animals_2014_11', 'foo')
      ).to be_truthy
      expect(
        connection.column_exists?('partman_animals_2014_12', 'foo')
      ).to be_truthy

      AddBarToPartmanAnimals.new.migrate(:down)
      expect(
        connection.column_exists?('partman_animals_2014_11', 'bar')
      ).to be_falsy
      expect(
        connection.column_exists?('partman_animals_2014_12', 'bar')
      ).to be_falsy

      AddFooToPartmanAnimals.new.migrate(:down)
      expect(
        connection.column_exists?('partman_animals_2014_11', 'foo')
      ).to be_falsy
      expect(
        connection.column_exists?('partman_animals_2014_12', 'foo')
      ).to be_falsy
    end
  end

  it 'should accept an explicitly specified base class' do
    partman = CanvasPartman::PartitionManager.new(CanvasPartmanTest::AnimalAlias)
    partman.create_partition(Time.new(2014, 11))

    Animal.transaction do
      AddAnotherThingToPartmanAnimals.new.migrate(:up)

      expect(
        connection.column_exists?('partman_animals_2014_11', 'another_thing')
      ).to be_truthy

      AddAnotherThingToPartmanAnimals.new.migrate(:down)
    end
  end

  it 'should add/remove indices just fine' do
    partman = CanvasPartman::PartitionManager.new(Animal)
    partman.create_partition(Time.new(2014, 11))

    Animal.transaction do
      AddRaceIndexToPartmanAnimals.new.migrate(:up)

      expect(
        connection.index_exists?('partman_animals_2014_11', :race)
      ).to be_truthy

      AddRaceIndexToPartmanAnimals.new.migrate(:down)
    end
  end
end
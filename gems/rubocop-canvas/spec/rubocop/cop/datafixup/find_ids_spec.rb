describe RuboCop::Cop::Datafixup::FindIds do
  subject(:cop) { described_class.new }

  context "class has 'unscoped'" do
    it 'allows find_ids_in_batches' do
      inspect_source(cop, %{
        class User
          unscoped
        end
        module DataFixup::RecomputeUnreadConversationsCount
          def self.run
            User.find_ids_in_batches do |ids|
              puts ids
            end
          end
        end
      })
      expect(cop.offenses.size).to eq(0)
    end

    it 'allows find_ids_in_range' do
      inspect_source(cop, %{
        class Assignment
          with_exclusive_scope
        end
        module DataFixup::InitializeSubmissionCachedDueDate
          def self.run
            Assignment.find_ids_in_ranges do |min, max|
              DueDateCacher.recompute_batch(min.to_i..max.to_i)
            end
          end
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "class has 'with_exclusive_scope'" do
    it 'allows find_ids_in_batches' do
      inspect_source(cop, %{
        class User
          with_exclusive_scope
        end
        module DataFixup::RecomputeUnreadConversationsCount
          def self.run
            User.find_ids_in_batches do |ids|
              puts ids
            end
          end
        end
      })
      expect(cop.offenses.size).to eq(0)
    end

    it 'allows find_ids_in_range' do
      inspect_source(cop, %{
        class Assignment
          with_exclusive_scope
        end
        module DataFixup::InitializeSubmissionCachedDueDate
          def self.run
            Assignment.find_ids_in_ranges do |min, max|
              DueDateCacher.recompute_batch(min.to_i..max.to_i)
            end
          end
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  it 'disallows find_ids_in_batches' do
    inspect_source(cop, %{
        class User
        end
        module DataFixup::RecomputeUnreadConversationsCount
          def self.run
            User.find_ids_in_batches do |ids|
              puts ids
            end
          end
        end
      })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/find_ids_in/)
  end

  it 'disallows find_ids_in_range' do
    inspect_source(cop, %{
        class Assignment
        end
        module DataFixup::InitializeSubmissionCachedDueDate
          def self.run
            Assignment.find_ids_in_ranges do |min, max|
              DueDateCacher.recompute_batch(min.to_i..max.to_i)
            end
          end
        end
      })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/find_ids_in/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end

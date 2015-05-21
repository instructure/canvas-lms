describe RuboCop::Cop::Lint::FreezeConstants do
  subject(:cop) { described_class.new }

  it 'doesnt care about single literals' do
    inspect_source(cop, %{ MAX_SOMETHING = 5 })
    expect(cop.offenses.size).to eq(0)
  end

  it 'warns about unfrozen arrays' do
    inspect_source(cop, %{ BLAH = [1,2,3,4] })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/should be frozen/)
  end

  it 'likes frozen arrays' do
    inspect_source(cop, %{ BLAH = [1,2,3,4].freeze })
    expect(cop.offenses.size).to eq(0)
  end

  it 'warns for unfrozen hashes' do
    inspect_source(cop, %{ FOO = {one: 'two', three: 'four'} })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/should be frozen/)
  end

  it 'is ok with frozen hashes' do
    inspect_source(cop, %{ FOO = {one: 'two', three: 'four'}.freeze })
    expect(cop.offenses.size).to eq(0)
  end

  it 'catches nested arrays within a hash' do
    inspect_source(cop, %{ FOO = {one: 'two', three: ['a', 'b']}.freeze })
    expect(cop.offenses.size).to eq(1)
  end

  it 'will go several levels deep with one offense for each structure' do
    inspect_source(cop, %{
      FOO = {
        one: {
          two: {
            three: {
              four: 5
            }
          }
        }
      }
    })
    expect(cop.offenses.size).to eq(4)
  end

  it 'also catches unfrozen nested arrays' do
    inspect_source(cop, %{ MATRIX = [[[1,2], [3,4]], [[5,6], [7,8]]] })
    expect(cop.offenses.size).to eq(7)
  end

  it 'doesnt interrupt code with no constant assignments' do
    inspect_source(cop, %{
      class TestMigration < ActiveRecord::Migration

        def up
          add_index :my_index
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it "isn't offended by non-array/hash structures" do
    inspect_source(cop, %{
      module Autoextend
        Extension = Struct.new(:module_name, :method, :block) do
          def extend(klass)
            if block
              block.call(klass)
            else
              klass.send(method, Autoextend.const_get(module_name.to_s))
            end
          end
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it "doesnt bomb on multiple constant assignments" do
    source = %{
      class Group < ActiveRecord::Base
        include Context
        include Workflow
        include CustomValidations

        TAB_HOME, TAB_PAGES, TAB_PEOPLE, TAB_DISCUSSIONS, TAB_FILES,
          TAB_CONFERENCES, TAB_ANNOUNCEMENTS, TAB_PROFILE, TAB_SETTINGS, TAB_COLLABORATIONS = *1..20

      end

    }
    inspect_source(cop, source)
    expect(cop.offenses.size).to eq(0)
  end
end

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe RuboCop::Cop::Lint::FreezeConstants do
  subject(:cop) { described_class.new }

  it 'doesnt care about single literals' do
    inspect_source(%{ MAX_SOMETHING = 5 })
    expect(cop.offenses.size).to eq(0)
  end

  it 'warns about unfrozen arrays' do
    inspect_source(%{ BLAH = [1,2,3,4] })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/should be frozen/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'likes frozen arrays' do
    inspect_source(%{ BLAH = [1,2,3,4].freeze })
    expect(cop.offenses.size).to eq(0)
  end

  it 'warns for unfrozen hashes' do
    inspect_source(%{ FOO = {one: 'two', three: 'four'} })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/should be frozen/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'is ok with frozen hashes' do
    inspect_source(%{ FOO = {one: 'two', three: 'four'}.freeze })
    expect(cop.offenses.size).to eq(0)
  end

  it 'catches nested arrays within a hash' do
    inspect_source(%{ FOO = {one: 'two', three: ['a', 'b']}.freeze })
    expect(cop.offenses.size).to eq(1)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'will go several levels deep with one offense for each structure' do
    inspect_source(%{
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
    expect(cop.offenses.all? { |off| off.severity.name == :warning })
  end

  it "doesnt care about integers" do
    inspect_source("THIS_ENV = ENV['TEST_ENV_NUMBER'].to_i")
    expect(cop.offenses.size).to eq(0)
  end

  it "doesnt care about regex literal" do
    inspect_source("REGEX = /someregex/")
    expect(cop.offenses.size).to eq(0)
  end

  it "doesnt care about regex object" do
    inspect_source("REGEX = Regexp.new('^someregex$')")
    expect(cop.offenses.size).to eq(0)
  end

  it "will not flag regexes with a non-string value as the last param" do
    inspect_source("R = Regexp.new('case-insensitive value', true)")
    expect(cop.offenses.size).to eq(0)
  end

  it "doesnt care about frozen regex literal" do
    inspect_source("REGEX = /someregex/.freeze")
    expect(cop.offenses.size).to eq(0)
  end

  it "doesnt care about frozen regex object" do
    inspect_source("REGEX = Regexp.new('^someregex$').freeze")
    expect(cop.offenses.size).to eq(0)
  end

  it "recognizes freezing the result of a ||" do
    inspect_source("WEBSERVER = (ENV['WEBSERVER'] || 'thin').freeze")
    expect(cop.offenses.size).to eq(0)
  end

  it "doesnt care about regular classes" do
    inspect_source("STRUCT = Struct.new(:grading_type)")
    expect(cop.offenses.size).to eq(0)
  end

  it 'also catches unfrozen nested arrays' do
    inspect_source(%{ MATRIX = [[[1,2], [3,4]], [[5,6], [7,8]]] })
    expect(cop.offenses.size).to eq(7)
    expect(cop.offenses.all? { |off| off.severity.name == :warning })
  end

  it 'doesnt interrupt code with no constant assignments' do
    inspect_source(%{
      class TestMigration < ActiveRecord::Migration

        def up
          add_index :my_index
        end
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it "isn't offended by non-array/hash structures" do
    inspect_source(%{
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
    inspect_source(source)
    expect(cop.offenses.size).to eq(0)
  end
end

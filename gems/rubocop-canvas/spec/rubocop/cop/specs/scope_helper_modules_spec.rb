# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe RuboCop::Cop::Specs::ScopeHelperModules do
  subject(:cop) { described_class.new }

  context "within class" do
    it "allows defs" do
      inspect_source(<<~RUBY)
        class CombatArmband
          def laserbeams
            "PEWPEWPEPWEPWPEW"
          end
        end
      RUBY
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "within context" do
    it "allows defs" do
      inspect_source(<<~RUBY)
        context "Jumpity JumpStick" do
          def jump_and_jab
            puts "heeeeeya!"
          end
        end
      RUBY
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "within describe" do
    it "allows defs" do
      inspect_source(<<~RUBY)
        describe JumpStick do
          def zappy_zap
            puts "yarrwafeiowhf"
          end
        end
      RUBY
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "within module" do
    it "allows defs" do
      inspect_source(<<~RUBY)
        module JumpStick
          def jumpy
            puts "vroom"
            puts "vroom"
          end
        end
      RUBY
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "within shared_context" do
    it "allows defs" do
      inspect_source(<<~RUBY)
        shared_context "in-process server selenium tests" do
          def bat_poo
            "splat!"
          end
        end
      RUBY
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "within shared_examples" do
    it "allows defs" do
      inspect_source(<<~RUBY)
        shared_examples '[:correct]' do
          def pirates
            "attaaaaaaaack!"
          end
        end
      RUBY
      expect(cop.offenses.size).to eq(0)
    end
  end

  it "disallows defs on Object" do
    inspect_source(<<~RUBY)
      def crow_tornado_so_op
        puts "yoo"
      end
    RUBY
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/Define all helper/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end

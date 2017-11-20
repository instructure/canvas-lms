#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe RuboCop::Cop::Specs::DeterministicDescribedClasses do
  subject(:cop) { described_class.new }

  shared_examples "relative describe constants" do
    before do
      inspect_source(source)
    end

    let(:preamble) { "" }
    let(:message) { cop.offenses.first.message }
    let(:full_const) { nesting + "::" + described_thing }
    let(:full_path) { full_const.underscore }

    context "with a matching require_dependency" do
      let(:preamble) { "require_dependency #{full_path.inspect}" }

      it "allows it" do
        expect(cop.offenses.size).to eq(0)
      end
    end

    context "without a matching require_dependency" do
      it "disallows it" do
        expect(cop.offenses.size).to eq(1)
      end

      it "identifies the offending constant" do
        expect(message).to include "`#{described_thing}` appears"
      end

      it "identifies the nesting" do
        expect(message).to include "nested in `#{nesting}`"
      end

      it "suggests two alternatives" do
        expect(message).to include "describe #{full_const}"
        expect(message).to include "require_dependency #{full_path.inspect}"
      end
    end
  end

  context "with a relative describe constant" do
    context "inside a module" do
      let(:source) do
        %{
          #{preamble}

          module Foo
            describe Bar
          end
        }
      end
      let(:nesting) { "Foo" }
      let(:described_thing) { "Bar" }

      include_examples "relative describe constants"
    end

    context "inside multiple nested modules and classes" do
      let(:source) do
        %{
          #{preamble}

          module Foo
            module Bar::Baz
              class Lol
                describe Wtf::Sad
              end
            end
          end
        }
      end

      let(:nesting) { "Foo::Bar::Baz::Lol" }
      let(:described_thing) { "Wtf::Sad" }

      include_examples "relative describe constants"
    end
  end

  context "at the top level" do
    it 'allows describe constants' do
      inspect_source(%{
        describe Foo
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  it "allows describe strings inside a module" do
    inspect_source(%{
      module Foo
        describe "bar"
      end
    })
    expect(cop.offenses.size).to eq(0)
  end

  it "allows top-level describe constants inside a module" do
    inspect_source(%{
      module Foo
        describe ::Bar
      end
    })
    expect(cop.offenses.size).to eq(0)
  end
end

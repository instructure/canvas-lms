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

describe RuboCop::Cop::Specs::EnsureSpecExtension do
  subject(:cop) { described_class.new }

  context "named as *_spec.rb" do
    before(:each) do
      allow(cop).to receive(:file_name).and_return("dragoon_spec.rb")
    end

    context "top level context" do
      it 'does not warn for *_spec.rb extension' do
        inspect_source(%{
          context AuthenticationProvider::BlueDragoon do
            describe '#fire' do
              it 'rains fire' do
                expect(1).to eq(1)
              end
            end
          end
        })
        expect(cop.offenses.size).to eq(0)
      end
    end

    context "top level describe" do
      it 'does not warn for *_spec.rb extension' do
        inspect_source(%{
          describe AuthenticationProvider::GreenDragoon do
            describe '#green' do
              it 'smells bad' do
                expect(1).to eq(1)
              end
            end
          end
        })
        expect(cop.offenses.size).to eq(0)
      end
    end
  end

  context "not named as *_spec.rb" do
    before(:each) do
      allow(cop).to receive(:file_name).and_return("dragoon.rb")
    end

    context "top level context" do
      it 'warns for *_spec.rb extension' do
        inspect_source(%{
          context AuthenticationProvider::BlueDragoon do
            describe '#fire' do
              it 'rains fire' do
                expect(1).to eq(1)
              end
            end
          end
        })
        expect(cop.offenses.size).to eq(1)
        expect(cop.messages.first).to match(/Spec files need to end with "_spec.rb"/)
        expect(cop.offenses.first.severity.name).to eq(:warning)
      end
    end

    context "top level describe" do
      it 'warns for *_spec.rb extension' do
        inspect_source(%{
          describe AuthenticationProvider::GreenDragoon do
            describe '#green' do
              it 'smells bad' do
                expect(1).to eq(1)
              end
            end
          end
        })
        expect(cop.offenses.size).to eq(1)
        expect(cop.messages.first).to match(/Spec files need to end with "_spec.rb"/)
        expect(cop.offenses.first.severity.name).to eq(:warning)
      end
    end
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'spec_helper'

module I18nTasks
  module I18n
    describe I18nImport do
      subject(:import) {  I18nImport.new({'en' => {}}, {'ja' => {}}) }

      describe '#fix_plural_keys' do
        it 'copies over the other key if there is no one key' do
          hash = {'some.key.other' => 'value'}
          import.fix_plural_keys(hash)
          expect(hash).to eq({'some.key.other' => 'value', 'some.key.one' => 'value'})
        end

        it 'leaves the one key alone if it already exists' do
          hash = {
              'some.key.other' => 'value',
              'some.key.one' => 'other value'
          }
          import.fix_plural_keys(hash)
          expect(hash).to eq({'some.key.other' => 'value', 'some.key.one' => 'other value'})
        end
      end

      describe "#markdown_and_wrappers" do
        it 'finds links' do
          expect(import.markdown_and_wrappers('[hello](http://foo.bar)')).to eq(['link:http://foo.bar'])
        end

        it 'finds escaped chars' do
          expect(import.markdown_and_wrappers('3 \* 3')).to eq(['\*'])
        end

        it 'finds wrappers' do
          expect(import.markdown_and_wrappers('hello *world*')).to eq(['*-wrap'])
        end

        it 'finds wrappers with whitespace' do
          expect(import.markdown_and_wrappers('hello * world *')).to eq(['*-wrap'])
        end

        it 'finds nested wrappers' do
          expect(import.markdown_and_wrappers('hello * **world** *')).to eq(['**-wrap', '*-wrap'])
        end

        context 'a single-line string' do
          it 'doesn\'t find headings' do
            expect(import.markdown_and_wrappers("# users")).to eq([])
          end

          it 'doesn\'t find hr\'s' do
            expect(import.markdown_and_wrappers("---")).to eq([])
          end

          it 'doesn\'t find lists' do
            expect(import.markdown_and_wrappers("1. do something")).to eq([])
            expect(import.markdown_and_wrappers("* do something")).to eq([])
            expect(import.markdown_and_wrappers("+ do something")).to eq([])
            expect(import.markdown_and_wrappers("- do something")).to eq([])
          end
        end

        context 'a multi-line string' do
          it 'finds headings' do
            expect(import.markdown_and_wrappers("# users\n")).to eq(['h1'])
            expect(import.markdown_and_wrappers("users\n====")).to eq(['h1'])
          end

          it 'finds hr\'s' do
            expect(import.markdown_and_wrappers("---\n")).to eq(['hr'])
          end

          it 'finds lists' do
            expect(import.markdown_and_wrappers("1. do something\n")).to eq(["1."])
            expect(import.markdown_and_wrappers("* do something\n")).to eq(["*"])
            expect(import.markdown_and_wrappers("+ do something\n")).to eq(["*"])
            expect(import.markdown_and_wrappers("- do something\n")).to eq(["*"])
          end
        end
      end
    end
  end
end

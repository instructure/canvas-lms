#
# Copyright (C) 2018 - present Instructure, Inc.
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
#
require_relative '../../spec_helper'
require_relative 'swagger_helper'
require 'response_field_view'

describe ResponseFieldView do
  let(:tag) do
    double(tag_name: 'response_field', text: 'foo A description.', types: ['String'])
  end

  let(:view) { ResponseFieldView.new(tag) }

  it '#deprecated? returns false' do
    expect(view).not_to be_deprecated
  end

  it 'sets types' do
    expect(view.types).to eq tag.types
  end

  describe '#to_swagger' do
    it 'includes "name"' do
      expect(view.to_swagger.fetch('name')).to eq 'foo'
    end

    it 'includes "description"' do
      expect(view.to_swagger.fetch('description')).to eq 'A description.'
    end

    it 'includes "deprecated"' do
      expect(view.to_swagger.fetch('deprecated')).to be false
    end
  end

  context 'line parser' do
    it 'raises on missing param name and missing description' do
      expect { view.parse_line('') }.to raise_error(ArgumentError)
    end

    it 'raises on missing description' do
      expect {
        view.parse_line('foo')
      }.to raise_error(ArgumentError, /Expected a description to be present, but it was not provided./)
    end
  end

  describe '#name' do
    it 'returns the name' do
      expect(view.name).to eq 'foo'
    end

    it 'forces the encoding of the name to UTF-8' do
      response_field_view = ResponseFieldView.new(
        double(
          tag_name: 'response_field',
          text: 'foo A description.'.force_encoding('binary'),
          types: ['String']
        )
      )

      expect(response_field_view.name.encoding.name).to eq 'UTF-8'
    end
  end

  describe '#description' do
    it 'returns the description' do
      expect(view.description).to eq 'A description.'
    end

    it 'forces the encoding of the description to UTF-8' do
      response_field_view = ResponseFieldView.new(
        double(
          tag_name: 'response_field',
          text: 'foo A description.'.force_encoding('binary'),
          types: ['String']
        )
      )

      expect(response_field_view.description.encoding.name).to eq 'UTF-8'
    end
  end

  context 'Deprecated ResponseFieldView' do
    let(:deprecated_tag) do
      double(
        tag_name: 'deprecated_response_field',
        text: "foo NOTICE 2018-01-02 EFFECTIVE 2018-04-30\nA description \non multiple lines.",
        types: ['String']
      )
    end

    let(:deprecated_view) { ResponseFieldView.new(deprecated_tag) }

    it '#deprecated? returns true' do
      expect(deprecated_view).to be_deprecated
    end

    it '#to_swagger returns true for "deprecated"' do
      expect(deprecated_view.to_swagger.fetch('deprecated')).to be true
    end

    describe '#parse_line' do
      it 'parses the argument name' do
        argument_name = deprecated_view.parse_line(deprecated_tag.text).first
        expect(argument_name).to eq 'foo'
      end

      it 'parses the description' do
        argument_type = deprecated_view.parse_line(deprecated_tag.text).second
        expect(argument_type).to eq "A description \non multiple lines."
      end

      it 'parses the effective deprecation date' do
        deprecated_view.parse_line(deprecated_tag.text)
        expect(deprecated_view.effective_date).to eq '2018-04-30'
      end

      it 'parses the deprecation notice date' do
        deprecated_view.parse_line(deprecated_tag.text)
        expect(deprecated_view.notice_date).to eq '2018-01-02'
      end

      it 'parses the effective deprecation date when it comes before the notice date' do
        text = deprecated_tag.text.gsub('NOTICE 2018-01-02 EFFECTIVE 2018-04-30', 'EFFECTIVE 2018-04-30 NOTICE 2018-01-02')
        deprecated_view.parse_line(text)
        expect(deprecated_view.effective_date).to eq '2018-04-30'
      end

      it 'parses the deprecation notice date when it comes after the effective date' do
        text = deprecated_tag.text.gsub('NOTICE 2018-01-02 EFFECTIVE 2018-04-30', 'EFFECTIVE 2018-04-30 NOTICE 2018-01-02')
        deprecated_view.parse_line(text)
        expect(deprecated_view.notice_date).to eq '2018-01-02'
      end

      context 'validations' do
        it 'is invalid when the text "NOTICE" is omitted' do
          tag = double(
            tag_name: 'deprecated_response_field',
            text: deprecated_tag.text.gsub('NOTICE ', ''),
            types: ['String']
          )
          expect {
            ResponseFieldView.new(tag)
          }.to raise_error(ArgumentError, /Expected argument `NOTICE`/)
        end

        it 'is invalid when the NOTICE date is omitted' do
          tag = double(
            tag_name: 'deprecated_response_field',
            text: deprecated_tag.text.gsub('2018-01-02 ', ''),
            types: ['String']
          )
          expect {
            ResponseFieldView.new(tag)
          }.to raise_error(ArgumentError, /Expected date .+ for key `NOTICE` to be in ISO 8601 format/)
        end

        it 'is invalid when the text "NOTICE" and the NOTICE date are omitted' do
          tag = double(
            tag_name: 'deprecated_response_field',
            text: deprecated_tag.text.gsub('NOTICE 2018-01-02 ', ''),
            types: ['String']
          )
          expect {
            ResponseFieldView.new(tag)
          }.to raise_error(ArgumentError, /Expected argument `NOTICE`/)
        end

        it 'is invalid when the NOTICE date is not in YYYY-MM-DD format' do
          tag = double(
            tag_name: 'deprecated_response_field',
            text: deprecated_tag.text.gsub('2018-01-02', '01-02-2018'),
            types: ['String']
          )
          expect {
            ResponseFieldView.new(tag)
          }.to raise_error(ArgumentError, /Expected date `01-02-2018` for key `NOTICE` to be in ISO 8601 format/)
        end

        it 'is invalid when the text "EFFECTIVE" is omitted' do
          tag = double(
            tag_name: 'deprecated_response_field',
            text: deprecated_tag.text.gsub('EFFECTIVE ', ''),
            types: ['String']
          )
          expect {
            ResponseFieldView.new(tag)
          }.to raise_error(ArgumentError, /Expected argument `EFFECTIVE`/)
        end

        it 'is invalid when the EFFECTIVE date is omitted' do
          tag = double(
            tag_name: 'deprecated_response_field',
            text: deprecated_tag.text.gsub('2018-04-30', ''),
            types: ['String']
          )
          expect {
            ResponseFieldView.new(tag)
          }.to raise_error(ArgumentError, /Expected a value to be present for argument `EFFECTIVE`, but it was blank./)
        end

        it 'is invalid when the text "EFFECTIVE" and the EFFECTIVE date are omitted' do
          tag = double(
            tag_name: 'deprecated_response_field',
            text: deprecated_tag.text.gsub(' EFFECTIVE 2018-04-30', ''),
            types: ['String']
          )
          expect {
            ResponseFieldView.new(tag)
          }.to raise_error(ArgumentError, /Expected argument `EFFECTIVE`/)
        end

        it 'is invalid when the EFFECTIVE date is not in YYYY-MM-DD format' do
          tag = double(
            tag_name: 'deprecated_response_field',
            text: deprecated_tag.text.gsub('2018-04-30', '04-30-2018'),
            types: ['String']
          )
          expect {
            ResponseFieldView.new(tag)
          }.to raise_error(ArgumentError, /Expected date `04-30-2018` for key `EFFECTIVE` to be in ISO 8601 format/)
        end

        it 'is invalid when the EFFECTIVE date is < 90 days after the NOTICE date' do
          tag = double(
            tag_name: 'deprecated_response_field',
            text: deprecated_tag.text.gsub('2018-04-30', '2018-02-26'),
            types: ['String']
          )
          expect {
            ResponseFieldView.new(tag)
          }.to raise_error(
            ArgumentError,
            /Expected >= 90 days between the `NOTICE` \(2018-01-02\) and `EFFECTIVE` \(2018-02-26\) dates/
          )
        end

        it 'is invalid when a description is not provided' do
          tag = double(
            tag_name: 'deprecated_response_field',
            text: deprecated_tag.text.gsub("\nA description \non multiple lines.", ''),
            types: ['String']
          )
          expect {
            ResponseFieldView.new(tag)
          }.to raise_error(
            ArgumentError,
            /Expected two lines: a tag declaration line with deprecation arguments, and a description line/
          )
        end

        it 'is invalid when the description is on the same line as the other content' do
          tag = double(
            tag_name: 'deprecated_response_field',
            text: deprecated_tag.text.gsub("\nA description \non multiple lines.", ' A description.'),
            types: ['String']
          )
          expect {
            ResponseFieldView.new(tag)
          }.to raise_error(
            ArgumentError,
            /Expected two lines: a tag declaration line with deprecation arguments, and a description line/
          )
        end
      end
    end
  end
end

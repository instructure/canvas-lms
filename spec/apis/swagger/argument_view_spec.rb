#
# Copyright (C) 2013 - present Instructure, Inc.
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
require 'spec_helper'
require_relative 'swagger_helper'
require 'argument_view'

describe ArgumentView do
  it '#deprecated? returns false' do
    view = ArgumentView.new("foo [String]")
    expect(view).not_to be_deprecated
  end

  context "type splitter" do
    let(:view) { ArgumentView.new "arg [String]" }

    it "accepts no type" do
      expect(view.split_type_desc("")).to eq(
        [ArgumentView::DEFAULT_TYPE, ArgumentView::DEFAULT_DESC]
      )
    end

    it "parses type with no desc" do
      expect(view.split_type_desc("[String]")).to eq(
        ["[String]", ArgumentView::DEFAULT_DESC]
      )
    end

    it "parses type and desc" do
      expect(view.split_type_desc("[String] desc ription")).to eq(
        ["[String]", "desc ription"]
      )
    end

    it "parses complex types" do
      expect(view.split_type_desc("[[String], [Date]]")).to eq(
        ["[[String], [Date]]", ArgumentView::DEFAULT_DESC]
      )
    end
  end

  context "line parser" do
    let(:view) { ArgumentView.new "arg [String]" }

    it "raises on missing param name and missing type" do
      expect { view.parse_line("") }.to raise_error(ArgumentError)
    end

    # This is probably not ideal — I'm just documenting existing behavior.
    it "does not raise on missing param name when type is present" do
      expect { view.parse_line("[String]") }.not_to raise_error
    end

    it "parses without desc" do
      parsed = view.parse_line("arg [String]")
      expect(parsed).to eq ["arg [String]", "arg", "[String]", ArgumentView::DEFAULT_DESC]
    end

    it "parses without type or desc" do
      parsed = view.parse_line("arg")
      expect(parsed).to eq ["arg", "arg", ArgumentView::DEFAULT_TYPE, ArgumentView::DEFAULT_DESC]
    end
  end

  context "with types, enums, description" do
    let(:view) { ArgumentView.new %{arg [Optional, String, "val1"|"val2"] argument} }

    it "has enums" do
      expect(view.enums).to eq ["val1", "val2"]
    end

    it "has types" do
      expect(view.types).to eq ["String"]
    end

    it "has a description" do
      expect(view.desc).to eq "argument"
    end
  end

  context "with optional arg" do
    let(:view) { ArgumentView.new %{arg [String]} }

    it "is optional" do
      expect(view.optional?).to be_truthy
    end
  end

  context "with required arg" do
    let(:view) { ArgumentView.new %{arg [Required, String]} }

    it "is required" do
      expect(view.required?).to be_truthy
    end
  end

  describe '#to_swagger' do
    let(:view) { ArgumentView.new("foo [String]") }

    it 'includes a "deprecated" key' do
      expect(view.to_swagger).to have_key 'deprecated'
    end

    it 'returns false for "deprecated"' do
      expect(view.to_swagger.fetch('deprecated')).to be false
    end
  end

  context 'Deprecated ArgumentView' do
    let(:valid_text) { "foo [Boolean] NOTICE 2018-01-02 EFFECTIVE 2018-04-30\nA description \non multiple lines." }
    let(:view) { ArgumentView.new(valid_text, deprecated: true) }

    it '#deprecated? returns true' do
      expect(view).to be_deprecated
    end

    it '#to_swagger returns true for "deprecated"' do
      expect(view.to_swagger.fetch('deprecated')).to be true
    end

    describe '#parse_line' do
      it 'parses the argument name' do
        argument_name = view.parse_line(valid_text).second
        expect(argument_name).to eq 'foo'
      end

      it 'parses the argument type' do
        argument_type = view.parse_line(valid_text).third
        expect(argument_type).to eq '[Boolean]'
      end

      it 'parses the description' do
        argument_type = view.parse_line(valid_text).fourth
        expect(argument_type).to eq "A description \non multiple lines."
      end

      it 'parses the effective deprecation date' do
        view.parse_line(valid_text)
        expect(view.effective_date).to eq '2018-04-30'
      end

      it 'parses the deprecation notice date' do
        view.parse_line(valid_text)
        expect(view.notice_date).to eq '2018-01-02'
      end

      it 'parses the effective deprecation date when it comes before the notice date' do
        text = valid_text.gsub('NOTICE 2018-01-02 EFFECTIVE 2018-04-30', 'EFFECTIVE 2018-04-30 NOTICE 2018-01-02')
        view.parse_line(text)
        expect(view.effective_date).to eq '2018-04-30'
      end

      it 'parses the deprecation notice date when it comes after the effective date' do
        text = valid_text.gsub('NOTICE 2018-01-02 EFFECTIVE 2018-04-30', 'EFFECTIVE 2018-04-30 NOTICE 2018-01-02')
        view.parse_line(text)
        expect(view.notice_date).to eq '2018-01-02'
      end

      # This is probably not ideal — I'm just documenting existing behavior.
      it 'uses the argument type as the name if name is not provided' do
        text = valid_text.gsub('foo ', '')
        view = ArgumentView.new(text, deprecated: true)
        argument_name = view.parse_line(text).second
        expect(argument_name).to eq '[Boolean]'
      end

      context 'when a type is not provided' do
        let(:text) { valid_text.gsub('[Boolean] ', '') }
        let(:view) { ArgumentView.new(text, deprecated: true) }

        it 'parses the argument name' do
          argument_name = view.parse_line(text).second
          expect(argument_name).to eq 'foo'
        end

        it 'uses String as the default type' do
          argument_type = view.parse_line(text).third
          expect(argument_type).to eq '[String]'
        end

        it 'parses the description' do
          argument_type = view.parse_line(text).fourth
          expect(argument_type).to eq "A description \non multiple lines."
        end

        it 'sets the effective deprecation date' do
          view.parse_line(text)
          expect(view.effective_date).to eq '2018-04-30'
        end

        it 'sets the deprecation notice date' do
          view.parse_line(text)
          expect(view.notice_date).to eq '2018-01-02'
        end
      end

      context 'validations' do
        it 'is invalid when the text "NOTICE" is omitted' do
          expect {
            ArgumentView.new(valid_text.gsub('NOTICE ', ''), deprecated: true)
          }.to raise_error(ArgumentError, /Expected argument `NOTICE`/)
        end

        it 'is invalid when the NOTICE date is omitted' do
          expect {
            ArgumentView.new(valid_text.gsub('2018-01-02 ', ''), deprecated: true)
          }.to raise_error(ArgumentError, /Expected date .+ for key `NOTICE` to be in ISO 8601 format/)
        end

        it 'is invalid when the text "NOTICE" and the NOTICE date are omitted' do
          expect {
            ArgumentView.new(valid_text.gsub('NOTICE 2018-01-02 ', ''), deprecated: true)
          }.to raise_error(ArgumentError, /Expected argument `NOTICE`/)
        end

        it 'is invalid when the NOTICE date is not in YYYY-MM-DD format' do
          expect {
            ArgumentView.new(valid_text.gsub('2018-01-02', '01-02-2018'), deprecated: true)
          }.to raise_error(ArgumentError, /Expected date `01-02-2018` for key `NOTICE` to be in ISO 8601 format/)
        end

        it 'is invalid when the text "EFFECTIVE" is omitted' do
          expect {
            ArgumentView.new(valid_text.gsub('EFFECTIVE ', ''), deprecated: true)
          }.to raise_error(ArgumentError, /Expected argument `EFFECTIVE`/)
        end

        it 'is invalid when the EFFECTIVE date is omitted' do
          expect {
            ArgumentView.new(valid_text.gsub('2018-04-30', ''), deprecated: true)
          }.to raise_error(ArgumentError, /Expected a value to be present for argument `EFFECTIVE`, but it was blank./)
        end

        it 'is invalid when the text "EFFECTIVE" and the EFFECTIVE date are omitted' do
          expect {
            ArgumentView.new(valid_text.gsub(' EFFECTIVE 2018-04-30', ''), deprecated: true)
          }.to raise_error(ArgumentError, /Expected argument `EFFECTIVE`/)
        end

        it 'is invalid when the EFFECTIVE date is not in YYYY-MM-DD format' do
          expect {
            ArgumentView.new(valid_text.gsub('2018-04-30', '04-30-2018'), deprecated: true)
          }.to raise_error(ArgumentError, /Expected date `04-30-2018` for key `EFFECTIVE` to be in ISO 8601 format/)
        end

        it 'is invalid when the EFFECTIVE date is < 90 days after the NOTICE date' do
          expect {
            ArgumentView.new(valid_text.gsub('2018-04-30', '2018-02-26'), deprecated: true)
          }.to raise_error(
            ArgumentError,
            /Expected >= 90 days between the `NOTICE` \(2018-01-02\) and `EFFECTIVE` \(2018-02-26\) dates/
          )
        end

        it 'is invalid when a description is not provided' do
          expect {
            ArgumentView.new(valid_text.gsub("\nA description \non multiple lines.", ''), deprecated: true)
          }.to raise_error(
            ArgumentError,
            /Expected two lines: a tag declaration line with deprecation arguments, and a description line/
          )
        end

        it 'is invalid when the description is on the same line as the other content' do
          text = valid_text.gsub("\nA description \non multiple lines.", ' A description.')
          expect {
            ArgumentView.new(text, deprecated: true)
          }.to raise_error(
            ArgumentError,
            /Expected two lines: a tag declaration line with deprecation arguments, and a description line/
          )
        end
      end
    end
  end
end

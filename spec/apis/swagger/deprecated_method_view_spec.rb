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
require 'deprecated_method_view'

describe DeprecatedMethodView do
  let(:valid_text) { "foo [Boolean] NOTICE 2018-01-02 EFFECTIVE 2018-04-30\nA description \non multiple lines." }

  it 'parses the effective deprecation date' do
    view = DeprecatedMethodView.new(double(text: valid_text))
    expect(view.effective_date).to eq '2018-04-30'
  end

  it 'parses the deprecation notice date' do
    view = DeprecatedMethodView.new(double(text: valid_text))
    expect(view.notice_date).to eq '2018-01-02'
  end

  it 'parses the description' do
    view = DeprecatedMethodView.new(double(text: valid_text))
    expect(view.description).to eq "A description \non multiple lines."
  end

  it 'parses the effective deprecation date when it comes before the notice date' do
    text = valid_text.gsub('NOTICE 2018-01-02 EFFECTIVE 2018-04-30', 'EFFECTIVE 2018-04-30 NOTICE 2018-01-02')
    view = DeprecatedMethodView.new(double(text: text))
    expect(view.effective_date).to eq '2018-04-30'
  end

  it 'parses the deprecation notice date when it comes after the effective date' do
    text = valid_text.gsub('NOTICE 2018-01-02 EFFECTIVE 2018-04-30', 'EFFECTIVE 2018-04-30 NOTICE 2018-01-02')
    view = DeprecatedMethodView.new(double(text: text))
    expect(view.notice_date).to eq '2018-01-02'
  end

  context 'validations' do
    it 'is invalid when the text "NOTICE" is omitted' do
      text = valid_text.gsub('NOTICE ', '')
      expect {
        DeprecatedMethodView.new(double(text: text))
      }.to raise_error(ArgumentError, /Expected argument `NOTICE`/)
    end

    it 'is invalid when the NOTICE date is omitted' do
      text = valid_text.gsub('2018-01-02 ', '')
      expect {
        DeprecatedMethodView.new(double(text: text))
      }.to raise_error(ArgumentError, /Expected date .+ for key `NOTICE` to be in ISO 8601 format/)
    end

    it 'is invalid when the text "NOTICE" and the NOTICE date are omitted' do
      text = valid_text.gsub('NOTICE 2018-01-02 ', '')
      expect {
        DeprecatedMethodView.new(double(text: text))
      }.to raise_error(ArgumentError, /Expected argument `NOTICE`/)
    end

    it 'is invalid when the NOTICE date is not in YYYY-MM-DD format' do
      text = valid_text.gsub('2018-01-02', '01-02-2018')
      expect {
        DeprecatedMethodView.new(double(text: text))
      }.to raise_error(ArgumentError, /Expected date `01-02-2018` for key `NOTICE` to be in ISO 8601 format/)
    end

    it 'is invalid when the text "EFFECTIVE" is omitted' do
      text = valid_text.gsub('EFFECTIVE ', '')
      expect {
        DeprecatedMethodView.new(double(text: text))
      }.to raise_error(ArgumentError, /Expected argument `EFFECTIVE`/)
    end

    it 'is invalid when the EFFECTIVE date is omitted' do
      text = valid_text.gsub('2018-04-30', '')
      expect {
        DeprecatedMethodView.new(double(text: text))
      }.to raise_error(ArgumentError, /Expected a value to be present for argument `EFFECTIVE`, but it was blank./)
    end

    it 'is invalid when the text "EFFECTIVE" and the EFFECTIVE date are omitted' do
      text = valid_text.gsub(' EFFECTIVE 2018-04-30', '')
      expect {
        DeprecatedMethodView.new(double(text: text))
      }.to raise_error(ArgumentError, /Expected argument `EFFECTIVE`/)
    end

    it 'is invalid when the EFFECTIVE date is not in YYYY-MM-DD format' do
      text = valid_text.gsub('2018-04-30', '04-30-2018')
      expect {
        DeprecatedMethodView.new(double(text: text))
      }.to raise_error(ArgumentError, /Expected date `04-30-2018` for key `EFFECTIVE` to be in ISO 8601 format/)
    end

    it 'is invalid when the EFFECTIVE date is < 90 days after the NOTICE date' do
      text = valid_text.gsub('2018-04-30', '2018-02-26')
      expect {
        DeprecatedMethodView.new(double(text: text))
      }.to raise_error(
        ArgumentError,
        /Expected >= 90 days between the `NOTICE` \(2018-01-02\) and `EFFECTIVE` \(2018-02-26\) dates/
      )
    end

    it 'is invalid when a description is not provided' do
      text = valid_text.gsub("\nA description \non multiple lines.", '')
      expect {
        DeprecatedMethodView.new(double(text: text))
      }.to raise_error(
        ArgumentError,
        /Expected two lines: a tag declaration line with deprecation arguments, and a description line/
      )
    end

    it 'is invalid when the description is on the same line as the other content' do
      text = valid_text.gsub("\nA description \non multiple lines.", ' A description.')
      expect {
        DeprecatedMethodView.new(double(text: text))
      }.to raise_error(
        ArgumentError,
        /Expected two lines: a tag declaration line with deprecation arguments, and a description line/
      )
    end
  end
end

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_dependency "lti/variable_expansion"

module Lti
  describe VariableExpansion do

    class TestExpander
      attr_accessor :one, :two, :three

      def initialize
        @one = 1
        @two = 2
        @three = 3
      end
    end

    subject { expander.expand(TestExpander.new) }

    let(:setup_data) { ['test', [], -> { @one + @two + @three }] }
    let(:expander) { described_class.new(*setup_data) }

    it { is_expected.to eq 6 }

    context 'with multiple guards' do
      context 'with result true' do
        let(:setup_data) { ['test', [], -> { @one + @two + @three }, -> { true }, -> { true }] }

        it { is_expected.to eq 6 }
      end

      context 'with result false' do
        let(:setup_data) { ['test', [], -> { @one + @two + @three }, -> { false }, -> { true }] }

        it { is_expected.to be_nil }
      end
    end

    context 'with empty result' do
      let(:setup_data) { ['test', [], -> { nil }] }

      it { is_expected.to eq '' }
    end

    context 'with default_name' do
      let(:setup_data) { ['test', [], -> { 'test' }, -> { true }, default_name: 'test_name'] }

      it 'accepts and sets default_name' do
        expect(expander.default_name).to eq 'test_name'
      end
    end

    context 'with single guard' do
      let(:setup_data) { ['test', [], -> { @one + @two + @three }, -> {false}] }

      it { is_expected.to be_nil }
    end
  end
end

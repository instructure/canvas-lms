#
# Copyright (C) 2015 Instructure, Inc.
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

    it 'expands variables' do
      var_exp = described_class.new('test', [], -> { @one + @two + @three } )
      expect(var_exp.expand(TestExpander.new)).to eq 6
    end

    it 'does not expand if the guard evals false' do
      var_exp = described_class.new('test', [], -> { @one + @two + @three }, -> {false} )
      expect(var_exp.expand(TestExpander.new)).to eq '$test'
    end


  end
end
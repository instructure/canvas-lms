# frozen_string_literal: true

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

module Lti
  describe VariableExpansion do
    let(:klass) do
      Class.new do
        attr_accessor :one, :two, :three

        def initialize
          @one = 1
          @two = 2
          @three = 3
        end
      end
    end

    it "must accept multiple guards and combine their results with a logical AND" do
      var_exp = described_class.new("test", [], -> { @one + @two + @three }, -> { true }, -> { true })
      expect(var_exp.expand(klass.new)).to eq 6

      var_exp = described_class.new("test", [], -> { @one + @two + @three }, -> { false }, -> { true })
      expect(var_exp.expand(klass.new)).to eq "$test"
    end

    it "accepts and sets default_name" do
      var_exp = described_class.new("test", [], -> { "test" }, -> { true }, default_name: "test_name")
      expect(var_exp.default_name).to eq "test_name"
    end

    it "expands variables" do
      var_exp = described_class.new("test", [], -> { @one + @two + @three })
      expect(var_exp.expand(klass.new)).to eq 6
    end

    it "does not expand if the guard evals false" do
      var_exp = described_class.new("test", [], -> { @one + @two + @three }, -> { false })
      expect(var_exp.expand(klass.new)).to eq "$test"
    end
  end
end

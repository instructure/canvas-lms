# frozen_string_literal: true

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

describe RuboCop::Cop::Specs::ScopeIncludes do
  subject(:cop) { described_class.new }

  context "within describe" do
    it "allows includes" do
      offenses = inspect_source(%(
        describe JumpStick do
          include Foo
        end
      ))
      expect(offenses.size).to eq(0)
    end
  end

  context "within module" do
    it "allows includes" do
      offenses = inspect_source(%(
        module JumpStick
          include Foo
        end
      ))
      expect(offenses.size).to eq(0)
    end
  end

  it "disallows defs on Object" do
    offenses = inspect_source(%(
      include Foo
    ))
    expect(offenses.size).to eq(1)
    expect(offenses.first.message).to match(/Never `include`/)
    expect(offenses.first.severity.name).to eq(:error)
  end
end

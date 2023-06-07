# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class MockModel
  include MaterialChanges
  attr_accessor :saved_changes

  def initialize(fake_changes)
    @saved_changes = fake_changes
  end
end

describe MaterialChanges do
  it "returns false when the attribute isn't changed" do
    expect(MockModel.new({ baz: [nil, 1] }).saved_material_changes_to?(:foo)).to be false
  end

  it "recognizes a change from nil" do
    expect(MockModel.new({ foo: [nil, 1] }).saved_material_changes_to?(:foo)).to be true
  end

  it "recognizes a change to nil" do
    expect(MockModel.new({ foo: [1, nil] }).saved_material_changes_to?(:foo)).to be true
  end

  it "returns true if any change is above the threshold" do
    expect(MockModel.new({ foo: [1, 1.2], bar: [2.1, 2.11] }).saved_material_changes_to?(:foo, :bar, threshold: 0.1)).to be true
  end

  it "reeturns false if all changes are below the threshold" do
    expect(MockModel.new({ foo: [1, 1.2], bar: [2.1, 2.11] }).saved_material_changes_to?(:foo, :bar, threshold: 0.5)).to be false
  end
end

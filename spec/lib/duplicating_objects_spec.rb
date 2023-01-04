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
#

describe DuplicatingObjects do
  include DuplicatingObjects

  describe "normalize_title" do
    it "test it" do
      expect(normalize_title("ThIs has 3 spaces")).to eq "this-has-3-spaces"
    end
  end

  describe "get_copy_title" do
    let(:klass) do
      Class.new do
        def initialize(title)
          @title = title
        end

        def get_potentially_conflicting_titles(_title_base)
          ["Foo", "assignment Copy", "Foo Copy", "Foo Copy 1", "Foo Copy 2", "Foo Copy 5"].to_set
        end

        attr_accessor :title
      end
    end

    it 'copy treated as "Copy" but case is respected' do
      entity = klass.new("assignment copy")
      expect(get_copy_title(entity, "Copy", entity.title)).to eq("assignment copy 2")
    end

    it "no conflicts" do
      entity = klass.new("Bar")
      expect(get_copy_title(entity, "Copy", entity.title)).to eq "Bar Copy"
    end

    it "conflict not ending in suffix" do
      entity = klass.new("Foo")
      expect(get_copy_title(entity, "Copy", entity.title)).to eq "Foo Copy 3"
    end

    it "conflict ending in suffix" do
      entity = klass.new("Foo Copy 1")
      expect(get_copy_title(entity, "Copy", entity.title)).to eq "Foo Copy 3"
    end

    it "increments from given number" do
      entity = klass.new("Foo Copy 5")
      expect(get_copy_title(entity, "Copy", entity.title)).to eq "Foo Copy 6"
    end
  end
end

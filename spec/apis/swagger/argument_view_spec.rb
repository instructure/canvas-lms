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

require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'argument_view'

describe ArgumentView do
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

    it "raises on missing param name" do
      expect { view.parse_line("") }.to raise_error(ArgumentError)
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
end

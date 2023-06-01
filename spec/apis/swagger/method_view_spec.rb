# frozen_string_literal: true

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
require_relative "../../spec_helper"
require_relative "swagger_helper"
require "method_view"

describe MethodView do
  let(:argument_tag) do
    text = "foo [String]\nA description."
    double(tag_name: "argument", text:)
  end

  let(:deprecated_argument_tag) do
    text = "foo NOTICE 2018-01-05 EFFECTIVE 2018-05-05\nA description."
    double(tag_name: "deprecated_argument", text:)
  end

  let(:response_field_tag) do
    double(tag_name: "response_field", text: "bar A description.")
  end

  let(:deprecated_response_field_tag) do
    double(tag_name: "deprecated_response_field", text: "baz NOTICE 2018-01-05 EFFECTIVE 2018-05-05\nA description.")
  end

  let(:deprecated_method_tag) do
    text = "NOTICE 2018-01-05 EFFECTIVE 2018-05-05\nA description."
    double(tag_name: "deprecated_method", text:)
  end

  describe "#deprecated?" do
    it "returns true when there is a deprecated method tag" do
      view = MethodView.new(double(tags: [argument_tag, deprecated_method_tag]))
      expect(view).to be_deprecated
    end

    it "returns false when there is not a deprecated method tag" do
      view = MethodView.new(double(tags: [argument_tag]))
      expect(view).not_to be_deprecated
    end
  end

  describe "#deprecation_description" do
    it "returns an empty string when there is not a deprecated method tag" do
      view = MethodView.new(double(tags: [argument_tag]))
      expect(view.deprecation_description).to eq ""
    end

    it "returns the deprecation description when there is a deprecated method tag" do
      view = MethodView.new(double(tags: [argument_tag, deprecated_method_tag]))
      expect(view.deprecation_description).to eq "A description."
    end
  end

  describe "#raw_arguments" do
    it "excludes tags that are not arguments" do
      view = MethodView.new(double(tags: [response_field_tag]))
      expect(view.raw_arguments).not_to include response_field_tag
    end

    it "includes argument tags" do
      view = MethodView.new(double(tags: [argument_tag]))
      expect(view.raw_arguments).to include argument_tag
    end

    it "includes deprecated argument tags" do
      view = MethodView.new(double(tags: [deprecated_argument_tag]))
      expect(view.raw_arguments).to include deprecated_argument_tag
    end
  end

  describe "#raw_response_fields" do
    it "excludes tags that are not response fields" do
      view = MethodView.new(double(tags: [argument_tag]))
      expect(view.raw_response_fields).not_to include argument_tag
    end

    it "includes response_field tags" do
      view = MethodView.new(double(tags: [response_field_tag]))
      expect(view.raw_response_fields).to include response_field_tag
    end

    it "includes deprecated response_field tags" do
      view = MethodView.new(double(tags: [deprecated_response_field_tag]))
      expect(view.raw_response_fields).to include deprecated_response_field_tag
    end
  end
end

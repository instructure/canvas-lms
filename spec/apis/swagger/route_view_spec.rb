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
require "argument_view"
require "route_view"
require "method_view"
require "response_field_view"

describe RouteView do
  let(:raw_route) do
    instance_double(ActionDispatch::Journey::Route, verb: "GET", path: instance_double(ActionDispatch::Journey::Path::Pattern, spec: "foo"))
  end

  describe "#query_args" do
    let(:argument_tag) do
      text = "foo [String]\nA description."
      instance_double(YARD::Tags::Tag, tag_name: "argument", text:)
    end

    let(:deprecated_argument_tag) do
      text = "foo NOTICE 2018-01-05 EFFECTIVE 2018-05-05\nA description."
      instance_double(YARD::Tags::Tag, tag_name: "deprecated_argument", text:)
    end

    it "argument views it returns respond with false to deprecated?" do
      view = RouteView.new(raw_route, instance_double(MethodView, raw_arguments: [argument_tag]))
      expect(view.query_args.first).not_to be_deprecated
    end

    it "deprecated argument views it returns respond with true to deprecated?" do
      view = RouteView.new(raw_route, instance_double(MethodView, raw_arguments: [deprecated_argument_tag]))
      expect(view.query_args.first).to be_deprecated
    end
  end

  describe "#response_fields" do
    let(:response_field_tag) do
      instance_double(YARD::Tags::Tag, tag_name: "response_field", text: "bar A description.", types: ["String"])
    end

    let(:deprecated_response_field_tag) do
      text = "baz NOTICE 2018-01-05 EFFECTIVE 2018-05-05\nA description."
      instance_double(YARD::Tags::Tag, tag_name: "deprecated_response_field", text:, types: ["String"])
    end

    it "returns response fields" do
      view = RouteView.new(raw_route, instance_double(MethodView, raw_response_fields: [response_field_tag]))
      field = view.response_fields.first
      expect(field).to eq({ "name" => "bar", "description" => "A description.", "deprecated" => false })
    end

    it "returns deprecated response fields" do
      view = RouteView.new(raw_route, instance_double(MethodView, raw_response_fields: [deprecated_response_field_tag]))
      field = view.response_fields.first
      expect(field).to eq({ "name" => "baz", "description" => "A description.", "deprecated" => true })
    end
  end
end

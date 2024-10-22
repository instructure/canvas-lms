# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require "lti_advantage"

module LtiAdvantage::Serializers
  RSpec.describe JwtMessageSerializer do
    let(:object) do
      obj = Class.new do
        include ActiveModel::Model
        attr_accessor :context, :errors, :validation_context, :custom
      end.new(context: "some_context", errors: {}, validation_context: "ctx", custom: "some_custom")
      obj.validate!
      obj
    end
    let(:serializer) { described_class.new(object) }

    describe "#serializable_hash" do
      context "when without_validation_fields is true" do
        it "applies claim prefixes and removes unwanted claims" do
          result = serializer.serializable_hash(without_validation_fields: true)
          expect(result).to eq({
                                 "https://purl.imsglobal.org/spec/lti/claim/context" => "some_context",
                                 "https://purl.imsglobal.org/spec/lti/claim/custom" => "some_custom"
                               })
        end
      end

      context "when without_validation_fields is false" do
        it "applies claim prefixes without removing unwanted claims" do
          result = serializer.serializable_hash(without_validation_fields: false)
          expect(result).to eq({
                                 "https://purl.imsglobal.org/spec/lti/claim/context" => "some_context",
                                 "https://purl.imsglobal.org/spec/lti/claim/custom" => "some_custom",
                                 "errors" => {},
                                 "validation_context" => "ctx"
                               })
        end
      end
    end
  end
end

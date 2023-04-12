# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "spec_helper"

describe LtiOutbound::VariableSubstitutor do
  describe "#substitute" do
    it "leaves the value unchanged for unkown keys" do
      data_hash = { "canvas_course_id" => "$Invalid.key" }
      expect(subject.substitute!(data_hash)["canvas_course_id"]).to eq "$Invalid.key"
    end

    it "substitutes nil values" do
      data_hash = { "canvas_course_id" => "$My.custom.variable" }
      subject.add_substitution "$My.custom.variable", nil

      expect(subject.substitute!(data_hash)["canvas_course_id"]).to be_nil
    end

    it "leaves the value unchanged for missing models" do
      data_hash = { "canvas_course_id" => "$Canvas.account.id" }
      expect(subject.substitute!(data_hash)["canvas_course_id"]).to eq "$Canvas.account.id"
    end

    describe "variable_substitutions" do
      it "can accept variable substitutions" do
        subject.add_substitution "$My.custom.variable", "blah"
        data_hash = { custom_var: "$My.custom.variable" }
        subject.substitute!(data_hash)

        expect(data_hash).to eq({ custom_var: "blah" })
      end

      it "can evaluate a proc" do
        subject.add_substitution("$My.custom.proc", proc { "blah" })
        data_hash = { custom_var: "$My.custom.proc" }
        subject.substitute!(data_hash)

        expect(data_hash).to eq({ custom_var: "blah" })
      end
    end

    it "#key?" do
      subject.add_substitution "$My.custom.variable", "value"

      expect(subject).to have_key("$My.custom.variable")
      expect(subject).not_to have_key("$My.fake.variable")
    end
  end
end

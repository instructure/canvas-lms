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
#

module Schemas
  class BaseSpecsTest < Base
    def schema
      {
        type: "object",
        properties: {
          some_str: { type: "string", enum: %w[foo bar] },
          some_num: { type: "number" },
          some_bool: { type: "boolean" },
        },
        required: %w[some_str some_num],
      }
    end
  end

  describe Base do
    let(:bad_str_and_num) do
      { "some_str" => "waz", "some_num" => "not a number" }
    end

    describe ".simple_validation_errors" do
      describe "when values are of the wrong type/enum value" do
        subject { BaseSpecsTest.simple_validation_errors(bad_str_and_num) }

        it "returns one string for each error" do
          str_err = subject.grep(/some_str/).first
          num_err = subject.grep(/some_num/).first
          expect([str_err, num_err].sort).to eq(subject.sort)
        end

        it "includes the enum values and wrong value" do
          str_err = subject.grep(/some_str/).first
          %w[foo bar waz].each do |val|
            expect(str_err).to include(val)
          end
        end

        it "includes the required type" do
          num_err = subject.grep(/some_num/).first
          expect(num_err).to include("number")
        end
      end

      describe "when values are missing" do
        it "lists the missing keys" do
          res = BaseSpecsTest.simple_validation_errors({})
          expect(res.join).to include("some_str", "some_num")
        end
      end
    end

    describe "simple_validation_first_error" do
      it "returns nil if there are no errors" do
        good = { "some_str" => "foo", "some_num" => 42 }
        expect(BaseSpecsTest.simple_validation_first_error(good)).to be_nil
      end

      it "returns one error string" do
        res = BaseSpecsTest.simple_validation_first_error(bad_str_and_num)
        expect(res).to be_a(String)
      end

      describe "with error_format: :hash" do
        it "returns a hash with the error details" do
          res = BaseSpecsTest.simple_validation_first_error(bad_str_and_num, error_format: :hash)
          expect(res).to be_a(Hash)
          expect(res.keys).to contain_exactly(*%i[error field schema])
        end

        it "returns a hash with the error details if required fields are missing" do
          res = BaseSpecsTest.simple_validation_first_error({}, error_format: :hash)
          expect(res).to be_a(Hash)
          expect(res.keys).to contain_exactly(*%i[error schema details])
        end
      end
    end
  end
end

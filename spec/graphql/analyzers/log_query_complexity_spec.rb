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
describe Analyzers::LogQueryComplexity do
  let(:schema) do
    Class.new(GraphQL::Schema) do
      query(Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
        field :hello, String, null: false

        def hello
          "world"
        end
      end)
    end
  end

  let(:query_string) { "{ hello }" }
  let(:query) { GraphQL::Query.new(schema, query_string) }
  let(:analyzer) { described_class.new(query) }

  describe "#result" do
    it "logs the computed query complexity" do
      expect(Rails.logger).to receive(:info)
      analyzer.result
    end
  end
end

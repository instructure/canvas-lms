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

describe UrlHelper do
  describe ".add_query_params" do
    it "adds query parameters to a URL string" do
      url = "http://example.com"
      params = { foo: "bar", baz: "qux" }
      expect(UrlHelper.add_query_params(url, params)).to eq("http://example.com?foo=bar&baz=qux")
    end

    it "handles URLs with existing query parameters" do
      url = "http://example.com?foo=bar"
      query_params = { baz: "qux" }
      expect(UrlHelper.add_query_params(url, query_params)).to eq("http://example.com?foo=bar&baz=qux")
    end

    it "stringifies query param values" do
      url = "http://example.com"
      query_params = { foo: false, baz: 2 }
      expect(UrlHelper.add_query_params(url, query_params)).to eq("http://example.com?foo=false&baz=2")
    end

    it "accepts query parameters with string keys" do
      url = "http://example.com"
      query_params = { "foo" => "bar", "baz" => "qux" }
      expect(UrlHelper.add_query_params(url, query_params)).to eq("http://example.com?foo=bar&baz=qux")
    end

    it "accepts query parameters as an array of key-value pairs" do
      url = "http://example.com"
      query_params = [[:foo, "bar"], [:baz, "qux"]]
      expect(UrlHelper.add_query_params(url, query_params)).to eq("http://example.com?foo=bar&baz=qux")
    end
  end
end

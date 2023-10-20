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

require "spec_helper"

describe LegacyMultipart::Post do
  def parse_params(query, header)
    Rack::Multipart.parse_multipart({ "CONTENT_TYPE" => header["Content-type"], "CONTENT_LENGTH" => query.size, "rack.input" => StringIO.new(query) })
  end

  it "prepare_queries with a File" do
    file = Tempfile.new(["test", "txt"])
    file.write("file on disk")
    file.rewind
    query, header = subject.prepare_query(a: "string", b: file)
    params = parse_params(query, header)
    expect(params["a"]).to eq("string")
    expect(params["b"][:filename]).to eq(File.basename(file.path))
    expect(params["b"][:tempfile].read).to eq("file on disk")
  end

  it "prepare_queries with a StringIO" do
    query, header = subject.prepare_query(a: "string", b: StringIO.new("file in mem"))
    params = parse_params(query, header)
    expect(params["a"]).to eq("string")
    expect(params["b"][:filename]).to eq("b")
    expect(params["b"][:tempfile].read).to eq("file in mem")
  end

  it "prepare_query_streams with a File" do
    file = Tempfile.new(["test", "txt"])
    file.write("file on disk")
    file.rewind
    stream, header = subject.prepare_query_stream(:a => "string", "test.txt" => file)
    params = parse_params(stream.read, header)
    expect(params["a"]).to eq("string")
    expect(params["test.txt"][:filename]).to eq(File.basename(file.path))
    expect(params["test.txt"][:tempfile].read).to eq("file on disk")
    expect(params["test.txt"][:head]).to include("Content-Type: text/plain")
  end

  it "prepare_query_streams with a StringIO" do
    file = Tempfile.new(["test", "txt"])
    file.write("file in mem")
    file.rewind
    stream, header = subject.prepare_query_stream(a: "string", b: file)
    params = parse_params(stream.read, header)
    expect(params["a"]).to eq("string")
    expect(params["b"][:filename]).to eq(File.basename(file.path))
    expect(params["b"][:tempfile].read).to eq("file in mem")
  end
end

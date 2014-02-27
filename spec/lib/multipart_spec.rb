#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "Multipart" do
  let(:multi) { Multipart::MultipartPost.new }

  def parse_params(query, header)
    Rack::Utils::Multipart.parse_multipart({ 'CONTENT_TYPE' => header['CONTENT_TYPE'], 'CONTENT_LENGTH' => query.size, 'rack.input' => StringIO.new(query) })
  end

  it "should prepare_query with a File" do
    file = Tempfile.new(["test","txt"])
    file.write("file on disk")
    file.rewind
    query, header = multi.prepare_query(:a => "string", :b => file)
    params = parse_params(query, header)
    params["a"].should == "string"
    params["b"][:filename].should == File.basename(file.path)
    params["b"][:tempfile].read.should == "file on disk"
  end

  it "should prepare_query with a StringIO" do
    query, header = multi.prepare_query(:a => "string", :b => StringIO.new("file in mem"))
    params = parse_params(query, header)
    params["a"].should == "string"
    params["b"][:filename].should == "b"
    params["b"][:tempfile].read.should == "file in mem"
  end
end

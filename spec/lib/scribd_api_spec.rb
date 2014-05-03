#
# Copyright (C) 2011 Instructure, Inc.
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

describe ScribdAPI do
  it "should be able to upload a file" do
    Scribd::Document.expects(:upload).returns('dispatched')
    ScribdAPI.upload('filename.txt', 'txt')
  end
  
  it "should only upload if the file actually exists" do
    Scribd::API.expects(:upload).never
    ErrorReport.expects(:log_error).returns(true)
    ScribdAPI.upload('not_a_file')
  end
end

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

def emails
  %[david@example.com
  "david" <david2@example.com>
  "david"<david3@example.com>]
end

def entry_emails(entries)
  entries.map {|entry| entry[:email]}
end

def entry_names(entries)
  entries.map {|entry| entry[:name]}
end

describe TmailParser do
  it "should understand commented email entries" do
    @parser = TmailParser.new(emails)
    @entries = @parser.parse
    entry_names(@entries).should eql([nil, 'david', 'david'])
    entry_emails(@entries).should eql(%w(david@example.com david2@example.com david3@example.com))
  end
end

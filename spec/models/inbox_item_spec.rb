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

require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe InboxItem do
  it "should truncate its title to 255 characters on validation" do
    long_subject = ' Re: Re: ' + (0..299).map { 'a' }.join('')
    inbox_item   = InboxItem.new(:subject => long_subject)
    inbox_item.valid?
    expect(inbox_item.subject).to match(/^a{255}$/)
  end
end

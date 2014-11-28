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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'erb_escaping' do
  it "should escape html for facebook" do
    Dir.mktmpdir do |path|
      Canvas::MessageHelper.add_message_path(path)
      
      File.open(File.join(path, 'erb_escaping.facebook.erb'), 'w') do |f|
        f.write("<b><%= '<escaped>' %></b><%= '<i>not escaped</i>'.html_safe %>\n\nescaped: <%= asset.title %>")
      end
  
      assignment_model(:title => "Quiz 1 & stuff")
      generate_message(:erb_escaping, :facebook, @assignment)
      expect(@message.body).to eql "<b>&lt;escaped&gt;</b><i>not escaped</i>\n\nescaped: Quiz 1 &amp; stuff"
    end
  end

  it "should not escape html for other message types" do
    Dir.mktmpdir do |path|
      Canvas::MessageHelper.add_message_path(path)
      
      File.open(File.join(path, 'erb_escaping.twitter.erb'), 'w') do |f|
        f.write("<b><%= '<not escaped>' %></b><%= '<i>not escaped</i>'.html_safe %>\n\nstill not escaped: <%= asset.title %>")
      end
  
      assignment_model(:title => "Quiz 1 & stuff")
      generate_message(:erb_escaping, :twitter, @assignment)
      expect(@message.body).to eql "<b><not escaped></b><i>not escaped</i>\n\nstill not escaped: Quiz 1 & stuff"
    end
  end
end

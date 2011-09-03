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

describe 'new_wiki_page.summary' do
  it "should render" do
    wiki_page_model
    @object = @page
    @object.reload
    @object.wiki.should_not be_nil
    @object.wiki_with_participants.should_not be_nil
    @object.wiki_with_participants.wiki_namespaces.should_not be_empty
    @object.wiki_with_participants.wiki_namespaces.first.context.participants.should be_include(@user)
    @object.wiki.wiki_namespaces.should_not be_empty
    @object.find_namespace_for_user(@user).should_not be_nil
    @object.find_namespace_for_user(@user).context.should_not be_nil
    generate_message(:new_wiki_page, :summary, @object, :user => @user)
  end
end

#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

shared_examples_for "cassandra page views" do
  before do
    if Canvas::Cassandra::DatabaseBuilder.configured?('page_views')
      Setting.set('enable_page_views', 'cassandra')
    else
      pending "needs cassandra page_views configuration"
    end
  end
end

shared_examples_for "cassandra audit logs" do
  before do
    unless Canvas::Cassandra::DatabaseBuilder.configured?('auditors')
      pending "needs cassandra auditors configuration"
    end
  end
end

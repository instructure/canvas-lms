#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "accounts/_sis_batch_counts.html.erb" do

  it "should render sis count data" do
    data = {counts: {xlists: 2, enrollments: 3, courses: 5, users: 6, terms: 6,
                     group_memberships: 7, group_categories: 2, groups: 8,
                     sections: 9, accounts: 10, admins: 1, user_observers: 3,
                     change_sis_ids: 3}}
    report = double()
    expect(report).to receive(:data).and_return(data)
    render :partial => 'accounts/sis_batch_counts', :object => report

    map = {xlists: "Crosslists", group_memberships: "Group Enrollments",
           user_observers: "User Observers", change_sis_ids: "Change SIS IDs",
           group_categories: "Group Categories",}

    data[:counts].each_pair do |type, count|
      name = map[type] || type.to_s.capitalize
      expect(response.body).to match(/#{name}: #{count}/)
    end
  end
end

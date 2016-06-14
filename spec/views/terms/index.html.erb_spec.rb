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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/terms/index" do
  it "should allow deletion of terms with only deleted courses" do
    assigns[:context] = assigns[:root_account] = Account.default
    term = Account.default.enrollment_terms.create!
    term.courses.create! { |c| c.workflow_state = 'deleted' }
    assigns[:terms] = Account.default.enrollment_terms.active.sort_by{|t| t.start_at || t.created_at }.reverse
    assigns[:course_counts_by_term] = EnrollmentTerm.course_counts(assigns[:terms])
    assigns[:user_counts_by_term] = EnrollmentTerm.user_counts(Account.default, assigns[:terms])
    render "terms/index"
    page = Nokogiri('<document>' + response.body + '</document>')
    expect(page.css(".delete_term_link")[0]['href']).to eq '#'
  end
end

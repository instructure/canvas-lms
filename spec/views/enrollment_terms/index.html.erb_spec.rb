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

describe "terms/_term.html.erb" do
  describe "sis_source_id edit box" do
    before do
      @account = Account.default
      @term = @account.enrollment_terms.create(:name=>"test term")
      @term.sis_source_id = "sis_this_fool"
      
      assigns[:context] = @account
      assigns[:account] = @account
      assigns[:root_account] = @account
      assigns[:course_counts_by_term] = EnrollmentTerm.course_counts([@term])
      assigns[:user_counts_by_term] = EnrollmentTerm.user_counts(@account, [@term])
    end

    it "should show to sis admin" do
      admin = account_admin_user
      view_context(@account, admin)
      assigns[:current_user] = admin
      render :partial => "terms/term.html.erb", :locals => {:term => @term}
      expect(response).to have_tag("input#enrollment_term_sis_source_id")
    end

    it "should not show to non-sis admin" do
      admin = account_admin_user_with_role_changes(:role_changes => {'manage_sis' => false})
      view_context(@account, admin)
      assigns[:current_user] = admin
      render :partial => "terms/term.html.erb", :locals => {:term => @term}
      expect(response).not_to have_tag("input#enrollment_term_sis_source_id")
      expect(response).to have_tag("span.sis_source_id", @term.sis_source_id)
    end
  end
end

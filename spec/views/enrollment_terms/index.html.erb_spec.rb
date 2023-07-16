# frozen_string_literal: true

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

require_relative "../views_helper"

describe "terms_api/_term" do
  describe "sis_source_id edit box" do
    before do
      @account = Account.default
      @term = @account.enrollment_terms.create(name: "test term")
      @term.sis_source_id = "sis_this_fool"

      assign(:context, @account)
      assign(:account, @account)
      assign(:root_account, @account)
      assign(:course_counts_by_term, EnrollmentTerm.course_counts([@term]))
    end

    it "shows to sis admin" do
      admin = account_admin_user
      view_context(@account, admin)
      assign(:current_user, admin)
      render partial: "terms_api/term", locals: { term: @term }
      expect(response).to have_tag("input#enrollment_term_sis_source_id_#{@term.id}")
    end

    it "does not show to non-sis admin" do
      admin = account_admin_user_with_role_changes(role_changes: { "manage_sis" => false })
      view_context(@account, admin)
      assign(:current_user, admin)
      render partial: "terms_api/term", locals: { term: @term }
      expect(response).not_to have_tag("input#enrollment_term_sis_source_id_#{@term.id}")
      expect(response).to have_tag("span.sis_source_id", @term.sis_source_id)
    end
  end
end

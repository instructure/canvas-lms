# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe TermsApiController do
  context "pagination" do
    before do
      account_model
      account_admin_user(account: @account)
      user_session(@user)
    end

    it "gets the default term (non-paginated)" do
      get "index", params: { account_id: @account.id }

      terms = assigns[:terms]
      expect(terms).to eq @account.enrollment_terms
      expect(terms.length).to eq 1
    end

    it "gets the first and second page of terms" do
      terms_per_page_count = TermsApiController::PER_PAGE
      new_terms_count = 25
      default_term_count = 1

      get "index", params: { account_id: @account.id }
      expect(response).to be_successful

      # create new terms
      new_terms_count.times do |i|
        @account.enrollment_terms.create!(name: "term #{i}")
      end

      # get the first page of term results
      get "index", params: { account_id: @account.id }
      expect(response).to be_successful
      expect(assigns[:terms].length).to eq terms_per_page_count

      # get the second page of term results
      get "index", params: { account_id: @account.id,
                             page: 2 }
      expect(response).to be_successful
      expect(assigns[:terms].length).to eq (new_terms_count - terms_per_page_count) + default_term_count
    end
  end

  context "search" do
    before do
      account_model
      account_admin_user(account: @account)
      user_session(@user)
    end

    it "searches for a term" do
      terms = Array.new(3) do |i|
        @account.enrollment_terms.create!(name: "term #{i}")
      end

      get "index", params: { account_id: @account.id,
                             term_name: "term 2" }
      expect(response).to be_successful
      expect(assigns[:terms]).to eq [terms[2]]
    end

    it "searches for a term that does not exist" do
      get "index", params: { account_id: @account.id,
                             term_name: "term 2" }
      expect(response).to be_successful
      expect(assigns[:terms]).to eq []
    end
  end
end

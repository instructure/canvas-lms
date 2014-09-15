#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe TermsApiController, type: :request do
  describe "index" do
    before :once do
      @account = Account.create(name: 'new')
      account_admin_user(account: @account)
      @account.enrollment_terms.scoped.delete_all
      @term1 = @account.enrollment_terms.create(name: "Term 1")
      @term2 = @account.enrollment_terms.create(name: "Term 2")
    end

    def get_terms(options={})
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/terms",
               { controller: 'terms_api', action: 'index', format: 'json', account_id: @account.to_param },
               options)
      json['enrollment_terms']
    end

    describe "filtering by state" do
      it "should list all active terms by default" do
        @term2.destroy

        json = get_terms
        names = json.map{ |t| t['name'] }
        names.should include(@term1.name)
        names.should_not include(@term2.name)
      end

      it "should list active terms with state=active" do
        @term2.destroy

        json = get_terms(workflow_state: 'active')
        names = json.map{ |t| t['name'] }
        names.should include(@term1.name)
        names.should_not include(@term2.name)
      end

      it "should list deleted terms with state=deleted" do
        @term2.destroy

        json = get_terms(workflow_state: 'deleted')
        names = json.map{ |t| t['name'] }
        names.should_not include(@term1.name)
        names.should include(@term2.name)
      end

      it "should list all terms, active and deleted, with state=all" do
        @term2.destroy

        json = get_terms(workflow_state: 'all')
        names = json.map{ |t| t['name'] }
        names.should include(@term1.name)
        names.should include(@term2.name)
      end

      it "should list all terms, active and deleted, with state=[all]" do
        @term2.destroy

        json = get_terms(workflow_state: ['all'])
        names = json.map{ |t| t['name'] }
        names.should include(@term1.name)
        names.should include(@term2.name)
      end
    end

    describe "ordering" do
      it "should order by start_at first" do
        @term1.update_attributes(start_at: 1.day.ago, end_at: 5.days.from_now)
        @term2.update_attributes(start_at: 2.days.ago, end_at: 6.days.from_now)

        json = api_call(:get, "/api/v1/accounts/#{@account.id}/terms",
                        { controller: 'terms_api', action: 'index', format: 'json', account_id: @account.to_param })

        json['enrollment_terms'].first['name'].should == @term2.name
        json['enrollment_terms'].last['name'].should == @term1.name
      end

      it "should order by end_at second" do
        start_at = 1.day.ago
        @term1.update_attributes(start_at: start_at, end_at: 6.days.from_now)
        @term2.update_attributes(start_at: start_at, end_at: 5.days.from_now)

        json = api_call(:get, "/api/v1/accounts/#{@account.id}/terms",
                        { controller: 'terms_api', action: 'index', format: 'json', account_id: @account.to_param })

        json['enrollment_terms'].first['name'].should == @term2.name
        json['enrollment_terms'].last['name'].should == @term1.name
      end

      it "should order by id last" do
        start_at = 1.day.ago
        end_at = 5.days.from_now
        @term1.update_attributes(start_at: start_at, end_at: end_at)
        @term2.update_attributes(start_at: start_at, end_at: end_at)

        json = api_call(:get, "/api/v1/accounts/#{@account.id}/terms",
                        { controller: 'terms_api', action: 'index', format: 'json', account_id: @account.to_param })

        json['enrollment_terms'].first['name'].should == @term1.name
        json['enrollment_terms'].last['name'].should == @term2.name
      end
    end

    it "should paginate" do
      json = get_terms(per_page: 1)
      json.size.should == 1
      response.headers.should include('Link')
      response.headers['Link'].should match(/rel="next"/)
    end
  end
end

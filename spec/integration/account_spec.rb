#
# Copyright (C) 2012 - present Instructure, Inc.
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

require 'nokogiri'

describe AccountsController do

  context "SAML meta data" do
    before(:each) do
      skip("requires SAML extension") unless AccountAuthorizationConfig::SAML.enabled?
      @account = Account.create!(:name => "test")
    end

    it 'should render for non SAML configured accounts' do
      get "/saml2"
      expect(response).to be_success
      expect(response.body).not_to eq ""
    end

    it "should use the correct entity_id" do
      HostUrl.stubs(:default_host).returns('bob.cody.instructure.com')
      @aac = @account.authentication_providers.create!(:auth_type => "saml")

      get "/saml2"
      expect(response).to be_success
      doc = Nokogiri::XML(response.body)
      expect(doc.at_xpath("md:EntityDescriptor", SAML2::Namespaces::ALL)['entityID']).to eq "http://bob.cody.instructure.com/saml2"
    end

    it "renders valid schema" do
      allow(HostUrl).to receive(:context_hosts).and_return(['bob.cody.instructure.com'])
      get "/saml2"
      expect(response).to be_success

      entity = SAML2::Entity.parse(response.body)
      expect(entity).to be_valid_schema
    end
  end

  context "section tabs" do
    it "should change in response to role override changes" do
      enable_cache do
        # cache permissions and tabs for a user
        @account = Account.default
        account_admin_user account: @account
        user_session @admin
        Timecop.freeze(61.minutes.ago) do
          get "/accounts/#{@account.id}"
          expect(response).to be_ok
          doc = Nokogiri::HTML(response.body)
          expect(doc.at_css('#section-tabs .section .outcomes')).not_to be_nil
        end

        # change a permission on the user's role
        @account.role_overrides.create! role: admin_role, permission: 'manage_outcomes',
                                        enabled: false

        # ensure the change is reflected once the user's cached permissions expire
        get "/accounts/#{@account.id}"
        expect(response).to be_ok
        doc = Nokogiri::HTML(response.body)
        expect(doc.at_css('#section-tabs .section .outcomes')).to be_nil
      end
    end
  end

  it "should show the correct students counts" do
    account_model
    account_admin_user(:account => @account)
    user_session(@user)

    course_with_student(:active_all => true, :account => @account)
    @course.student_view_student # shouldn't count

    get "/accounts/#{@account.id}"

    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css(".course .details").text).to include("1 Student")
  end

  it 'shows special master/blueprint course stuff in course index' do
    @domain_root_account = Account.default
    Account.default.enable_feature!(:master_courses)
    account_admin_user
    user_session(@user)

    bc = course_factory(:course_name => "blooprint")
    template = MasterCourses::MasterTemplate.set_as_master_course(bc)
    2.times do
      template.add_child_course!(course_factory)
    end
    time = DateTime.parse("2016-05-12 22:00 UTC")
    template.master_migrations.create!(:imports_completed_at => time, :workflow_state => 'completed')

    get "/accounts/#{Account.default.id}?only_master_courses=1"

    doc = Nokogiri::HTML(response.body)
    text = doc.at_css(".course .details").text
    expect(text).to include("Blueprint Course")
    expect(text).to include("Last Pushed Update: May 12")
    expect(text).to include("2 Associated Courses")
  end
end

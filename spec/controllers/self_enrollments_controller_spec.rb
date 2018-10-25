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

describe SelfEnrollmentsController do
  describe "GET 'new'" do
    before do
      Account.default.allow_self_enrollment!
      course_factory(active_all: true)
      @course.update_attribute(:self_enrollment, true)
    end

    it "should render if the course is open for enrollment" do
      get 'new', params: {:self_enrollment_code => @course.self_enrollment_code}
      expect(response).to be_successful
    end

    it "should do the delegated auth dance" do
      account = account_with_cas({:account => Account.default})

      get 'new', params: {:self_enrollment_code => @course.self_enrollment_code}
      expect(response).to redirect_to login_url
    end

    it "forwards authentication_provider param" do
      account_with_cas(account: Account.default)

      get 'new', params: {self_enrollment_code: @course.self_enrollment_code, authentication_provider: 'facebook'}
      expect(response).to redirect_to login_url(authentication_provider: 'facebook')
    end

    it "redirects to login if auth_discovery_url is present and authentication_provider isn't specified" do
      account_with_cas(account: Account.default)
      Account.default.tap{|a| a.settings[:auth_discovery_url] = "http://www.example.com/discovery"; a.save!}

      get 'new', params: {self_enrollment_code: @course.self_enrollment_code}
      expect(response).to redirect_to login_url
    end

    it "renders directly if auth_discovery_url is present and canvas authentication_provider is specified" do
      account_with_cas(account: Account.default)
      Account.default.tap{|a| a.settings[:auth_discovery_url] = "http://www.example.com/discovery"; a.save!}

      get 'new', params: {self_enrollment_code: @course.self_enrollment_code, authentication_provider: 'canvas'}
      expect(response).to be_successful
    end

    it "renders directly if authentication_provider=canvas" do
      account_with_cas(account: Account.default)

      get 'new', params: {self_enrollment_code: @course.self_enrollment_code, authentication_provider: 'canvas'}
      expect(response).to be_successful
    end

    it "should not render for an incorrect code" do
      assert_page_not_found do
        get 'new', params: {:self_enrollment_code => 'abc'}
      end
    end

    it "should render even if self_enrollment is disabled" do
      code = @course.self_enrollment_code
      @course.update_attribute(:self_enrollment, false)

      get 'new', params: {:self_enrollment_code => code}
      expect(response).to be_successful
    end

    it "should default assign login_label_name to 'email'" do
      get 'new', params: {:self_enrollment_code => @course.self_enrollment_code}
      expect(assigns(:login_label_name)).to eq("Email")
    end

    it "should change login_label_name when set on domain_root_account" do
      custom_label = "batman is the best"
      allow_any_instance_of(Account).to receive(:login_handle_name).and_return(custom_label)

      get 'new', params: {:self_enrollment_code => @course.self_enrollment_code}
      expect(assigns(:login_label_name)).to eq(custom_label)
    end
  end
end

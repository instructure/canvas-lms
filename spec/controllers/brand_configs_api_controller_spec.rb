#
# Copyright (C) 2016 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BrandConfigsApiController do
  describe '#show' do

    it "should redirect to the default when nothing is set" do
      get :show
      expect(response).to redirect_to("#{Canvas::Cdn.config.host}/#{BrandableCSS.public_default_path('json')}")
    end

    it "should redirect to the one for @domain_root_account's brand config if set" do
      brand_config = Account.default.create_brand_config!(variables: {"ic-brand-primary" => "#321"})
      get :show
      expect(response).to redirect_to("#{Canvas::Cdn.config.host}/#{brand_config.public_json_path}")
    end

    it "should set CORS headers" do
      brand_config = Account.default.create_brand_config!(variables: {"ic-brand-primary" => "#321"})
      get :show
      expect(response.header["Access-Control-Allow-Origin"]).to eq "*"
    end
  end
end

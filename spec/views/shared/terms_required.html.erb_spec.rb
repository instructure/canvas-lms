#
# Copyright (C) 2015 Instructure, Inc.
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

describe "/shared/terms_required" do
  context "with custom stylesheet on account" do
    before do
      assigns[:domain_root_account] = Account.default
      expect(Account.default.feature_enabled?(:use_new_styles)).to be_falsey
      expect(Account.default.feature_enabled?(:k12)).to be_falsey
      Account.default.settings = {global_includes: true, global_stylesheet: '/custom_stylesheet.css'}
      Account.default.save!
    end

    it "should still include application stylesheet" do
      render template: "shared/terms_required", layout: "layouts/application"
      expect(response).to match(%r{<link href="[^"]*bundles/login-[^"]*\.css"})
    end

    it "should not include custom stylesheet" do
      render template: "shared/terms_required", layout: "layouts/application"
      expect(response).not_to match(%r{<link href="/custom_stylesheet\.css"})
    end
  end
end

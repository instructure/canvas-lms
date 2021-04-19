# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Authenticity Tokens" do
  include_context "in-process server selenium tests"

  it "should change the masked authenticity token on each request but not the unmasked token", priority: "1", test_id: 296921 do
    user_logged_in
    get('/')
    token = driver.execute_script "return $.cookie('_csrf_token')"
    get('/')
    token2 = driver.execute_script "return $.cookie('_csrf_token')"
    expect(token).not_to eq token2
    expect(CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token)).to eq(
      CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token2)
    )
  end

  it "should change the unmasked token on logout", priority: "1", test_id: 296922 do
    user_logged_in
    get('/')
    token = driver.execute_script "return $.cookie('_csrf_token')"
    expect_new_page_load(:accept_alert) { expect_logout_link_present.click }
    token2 = driver.execute_script "return $.cookie('_csrf_token')"
    expect(token).not_to eq token2
    expect(CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token)).not_to eq(
        CanvasBreachMitigation::MaskingSecrets.send(:unmasked_token, token2)
    )
  end
end

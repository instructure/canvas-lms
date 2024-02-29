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

require_relative "../common"

describe "jquery" do
  include_context "in-process server selenium tests"

  # jquery keeps breaking attr() ... see http://bugs.jquery.com/ticket/10278
  # should be fixed in 1.7 (or 1.6.5?)
  it "returns the correct value for attr" do
    skip_if_chrome("Fragile in chrome")
    get("/login")
    driver.execute_script("$(document.body).append('<input type=\"checkbox\" checked=\"checked\" id=\"checkbox_test\">')")

    checkbox = f("#checkbox_test")
    expect(driver.execute_script("return $('#checkbox_test').attr('checked');")).to eq "checked"

    checkbox.click
    expect(driver.execute_script("return $('#checkbox_test').attr('checked');")).to be_nil
  end

  it "handles $.attr(method, post|delete|put|get) by adding a hidden input" do
    get("/login")
    expect(driver.execute_script("return $('form').attr('method', 'delete').attr('method')").downcase).to eq "post"
    expect(driver.execute_script("return $('form input[name=_method]').val()")).to eq "delete"
  end

  it "is able to handle ':hidden' and ':visible' pseudo-selector on document body" do
    get("/login")
    expect(driver.execute_script("return $(document.body).is(':visible')")).to be true
    expect(driver.execute_script("return $(document.body).is(':hidden')")).to be false
  end
end

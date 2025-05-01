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

shared_examples_for "module show all or less" do
  it "has a working Show More/Show Less buttons on a paginated module" do
    go_to_modules
    wait_for_dom_ready
    expect(context_module(@module.id)).to be_displayed
    expect(ff(module_items_selector(@module.id)).size).to eq(10)
    expect(show_all_button).to be_displayed
    show_all_button.click
    expect(show_less_button).to be_displayed
    expect(ff(module_items_selector(@module.id)).size).to eq(11)
    show_less_button.click
    expect(show_all_button).to be_displayed
    expect(ff(module_items_selector(@module.id)).size).to eq(10)
  end

  it "has neither button on a collapsed module" do
    go_to_modules
    wait_for_dom_ready
    collapse_module_link(@module.id).click
    expect(context_module(@module.id)).not_to contain_css(show_all_or_less_button_selector)
  end

  context "with one less item" do
    before do
      @module.content_tags.last.destroy
    end

    it "has neither button on a collapsed module" do
      go_to_modules
      wait_for_dom_ready
      expect(context_module(@module.id)).not_to contain_css(show_all_or_less_button_selector)
    end
  end
end

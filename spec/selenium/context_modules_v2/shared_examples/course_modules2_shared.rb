# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

shared_examples_for "module unlock dates" do
  it "displays the will unlock label when unlock date is in the future" do
    @module1.unlock_at = 1.week.from_now
    @module1.save!

    go_to_modules
    wait_for_ajaximations

    will_unlock_at_label = module_header_will_unlock_label(@module1.id)
    expect(will_unlock_at_label).to be_present
    expect(will_unlock_at_label.text).to include("Will unlock")

    module_header_expand_toggles.first.click
    wait_for_ajaximations

    # Still exists after expanding
    expect(will_unlock_at_label).to be_present
    expect(will_unlock_at_label.text).to include("Will unlock")
  end

  it "does not display the will unlock label when unlock date is in the past" do
    @module1.unlock_at = 1.week.ago
    @module1.save!

    go_to_modules
    wait_for_ajaximations
    expect(element_exists?(module_header_will_unlock_selector(@module1.id))).to be_falsey
  end
end

shared_examples_for "module collapse and expand" do |context|
  before do
    case context
    when :context_modules
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}/modules"
    when :canvas_for_elementary
      @mod_course = @subject_course
      @mod_url = "/courses/#{@mod_course.id}#modules"
    when :course_homepage
      @mod_course = @course
      @mod_url = "/courses/#{@mod_course.id}"
    end
  end

  it "start with all modules collapsed" do
    get @mod_url

    expect(module_header_expand_toggles.length).to eq(3)
    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")
  end

  it "collapses and expands the module" do
    get @mod_url

    expect(module_header_expand_toggles.first.text).to include("Expand module")

    module_header_expand_toggles.first.click

    expect(module_header_expand_toggles.first.text).to include("Collapse module")

    module_header_expand_toggles.first.click

    expect(module_header_expand_toggles.first.text).to include("Expand module")
  end

  it "expand and collapse module status retained after refresh" do
    get @mod_url

    expect(module_header_expand_toggles.first.text).to include("Expand module")

    module_header_expand_toggles.first.click

    expect(module_header_expand_toggles.first.text).to include("Collapse module")

    refresh_page

    expect(module_header_expand_toggles.first.text).to include("Collapse module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")
  end

  it "expands all modules when clicking the expand all button" do
    get @mod_url

    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")

    expand_all_modules_button.click

    expect(module_header_expand_toggles.first.text).to include("Collapse module")
    expect(module_header_expand_toggles.last.text).to include("Collapse module")
  end

  it "collapses all modules when clicking the collapse all button" do
    get @mod_url

    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")

    expand_all_modules_button.click

    expect(module_header_expand_toggles.first.text).to include("Collapse module")
    expect(module_header_expand_toggles.last.text).to include("Collapse module")

    collapse_all_modules_button.click

    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")
  end

  it "expand all is retained after refresh" do
    get @mod_url

    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")

    expand_all_modules_button.click

    expect(module_header_expand_toggles.first.text).to include("Collapse module")
    expect(module_header_expand_toggles.last.text).to include("Collapse module")

    refresh_page

    expect(module_header_expand_toggles.first.text).to include("Collapse module")
    expect(module_header_expand_toggles.last.text).to include("Collapse module")
  end

  it "collapse all is retained after refresh" do
    get @mod_url

    expand_all_modules_button.click

    expect(module_header_expand_toggles.first.text).to include("Collapse module")
    expect(module_header_expand_toggles.last.text).to include("Collapse module")

    collapse_all_modules_button.click

    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")

    refresh_page

    expect(module_header_expand_toggles.first.text).to include("Expand module")
    expect(module_header_expand_toggles.last.text).to include("Expand module")
  end
end

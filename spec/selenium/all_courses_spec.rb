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

describe "course catalog" do
  include_context "in-process server selenium tests"

  def catalog_url
    "/search/all_courses"
  end

  def visit_catalog
    get catalog_url
    wait_for_ajaximations
  end

  def course_elements
    ff('#course_summaries > li')
  end

  def catalog_setup
    Account.default.settings[:enable_course_catalog] = true
    Account.default.save!
    # create_courses factory returns id's of courses unless you specify return_type
    create_courses([ public_indexed_course_attrs ], {return_type: :record}).first
  end

  def public_indexed_course_attrs
     {
      name: 'Intro to Testing',
      public_description: 'An overview of testing with Selenium',
      is_public: true,
      indexed: true,
      self_enrollment: true,
      workflow_state: 'available'
    }
  end

  before do
    catalog_setup
    visit_catalog
  end

  it "should list indexed courses" do
    expect(course_elements.size).to eql 1
  end

  it "should work without course catalog" do
    Account.default.settings[:enable_course_catalog] = false
    Account.default.save!
    expect(course_elements.size).to eql 1
  end

  it "should list a next button when >12 courses are in the index and public", priority: "1", test_id: 2963672 do
      create_courses(13.times.map{ |i| public_indexed_course_attrs.merge(name: "#{i}") })
      refresh_page
      expect(f('#next-link').displayed?).to be(true)
  end
end

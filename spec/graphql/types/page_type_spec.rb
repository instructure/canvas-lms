# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
require_relative "../graphql_spec_helper"

describe Types::PageType do
  let_once(:course) { course_with_teacher(active_all: true); @course }
  let_once(:wiki) { course.create_wiki! has_no_front_page: false, title: "asdf" }
  let_once(:page) { wiki.front_page.tap(&:save!) }
  let(:page_type) { GraphQLTypeTester.new(page, current_user: @teacher) }

  it "works" do
    expect(page_type.resolve("title")).to eq page.title
  end

  it "has modules" do
    module1 = course.context_modules.create!(name: 'Module 1')
    module2 = course.context_modules.create!(name: 'Module 2')
    page.context_module_tags.create!(context_module: module1, context: course, tag_type: 'context_module')
    page.context_module_tags.create!(context_module: module2, context: course, tag_type: 'context_module')
    expect(page_type.resolve("modules { _id }").sort).to eq [module1.id.to_s, module2.id.to_s]
  end
end

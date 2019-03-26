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

describe Types::ExternalUrlType do
  let_once(:course) { course_with_teacher(active_all: true); @course }
  let_once(:context_module) { course.context_modules.create! name: 'Module 1' }
  let_once(:module_item) {
    context_module.content_tags.create!(
      content_id: 0,
      tag_type: 'context_module',
      content_type: 'ExternalUrl',
      context_id: course.id,
      context_type: 'Course',
      title: 'Test Title',
      url: 'https://google.com'
    )
  }

  it "works" do
    expected = { "data" => { "moduleItem" => { "content" => { "url" => module_item.url } } } }
    result = CanvasSchema.execute(<<~GQL, context: {current_user: @teacher})
      query {
        moduleItem(id: "#{module_item.id}") {
          content {
            ... on ExternalUrl {
              url
            }
          }
        }
      }
    GQL
    expect(result.to_h).to eq expected
  end

  it "has modules" do
    expected = {
      "data" => {
        "moduleItem" => {
          "content" => {
            "modules" => [{"_id" => context_module.id.to_s}]
          }
        }
      }
    }
    result = CanvasSchema.execute(<<~GQL, context: {current_user: @teacher})
      query {
        moduleItem(id: "#{module_item.id}") {
          content {
            ... on ExternalUrl {
              modules {
                _id
              }
            }
          }
        }
      }
    GQL
    expect(result.to_h).to eq expected
  end
end

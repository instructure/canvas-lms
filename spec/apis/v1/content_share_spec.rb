# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "../../spec_helper"

describe ContentShare do
  include Api::V1::ContentShare

  before :once do
    course_with_teacher
    @export = @course.content_exports.create!
    @cs = @teacher.sent_content_shares.create! name: "test", content_export: @export, read_state: "read"
  end

  let(:export_settings) do
    {
      "assignment" => { "assignments" => { "blah" => "1" } },
      "attachment" => { "attachments" => { "blah" => "1" } },
      "discussion_topic" => { "discussion_topics" => { "blah" => "1" } },
      "page" => { "wiki_pages" => { "blah" => "1" } },
      "quiz" => { "quizzes" => { "blah" => "1" } },
      "module_item" => { "wiki_pages" => { "bap" => "1" }, "content_tags" => { "blah" => "1" } },
      "module" => { "content_tags" => { "bar" => "1", "baz" => "1" },
                    "context_modules" => { "foo" => "1" },
                    "assignments" => { "bip" => "1" },
                    "wiki_pages" => { "bap" => "1" } }
    }
  end

  it "detects an assignment export" do
    detect_export("assignment")
  end

  it "detects an attachment export" do
    detect_export("attachment")
  end

  it "detects a discussion topic export" do
    detect_export("discussion_topic")
  end

  it "detects a page export" do
    detect_export("page")
  end

  it "detects a quiz export" do
    detect_export("quiz")
  end

  it "detects a module item export" do
    detect_export("module_item")
  end

  it "detects a module export" do
    detect_export("module")
  end

  def detect_export(type)
    @export.settings = { "selected_content" => export_settings[type] }
    @export.save!
    thing = content_share_json(@cs, nil, {})
    expect(thing["content_type"]).to eq type
  end
end

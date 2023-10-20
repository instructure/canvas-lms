# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe AttachmentSerializer do
  subject do
    AttachmentSerializer.new(attachment, {
                               controller:,
                               scope: User.new
                             })
  end

  let :context do
    Course.new.tap do |course|
      course.id = 1
      course.save!
    end
  end

  let :quiz do
    context.quizzes.build(title: "banana split").tap do |quiz|
      quiz.id = 2
      quiz.save!
    end
  end

  let :attachment do
    stats = quiz.current_statistics_for("student_analysis")
    stats.generate_csv
    stats.reload
    stats.csv_attachment
  end

  let(:host_name) { "example.com" }

  let :controller do
    options = {
      accepts_jsonapi: false,
      stringify_json_ids: false
    }

    ActiveModel::FakeController.new(options).tap do |controller|
      allow(controller).to receive_messages(session: Object.new, context:)
    end
  end

  let :json do
    @json ||= subject.as_json[:attachment].stringify_keys
  end

  it "includes the output of the legacy serializer" do
    expected_keys = %w[
      id
      content-type
      display_name
      filename
      url
      size
      created_at
      updated_at
      unlock_at
      locked
      hidden
      lock_at
      hidden_for_user
      thumbnail_url
    ]

    expect(json.keys.map(&:to_s) & expected_keys).to match_array expected_keys
  end
end

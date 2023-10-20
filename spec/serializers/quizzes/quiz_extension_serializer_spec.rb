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

describe Quizzes::QuizExtensionSerializer do
  let :context do
    Course.new.tap do |course|
      course.id = 1
      course.save!
    end
  end

  let(:user) { User.new }
  let(:session) { double }
  let(:host_name) { "example.com" }

  let :controller do
    options = {
      accepts_jsonapi: true,
      stringify_json_ids: false
    }

    ActiveModel::FakeController.new(options).tap do |controller|
      allow(controller).to receive_messages(session:, context:)
    end
  end

  let :quiz_extension do
    qs = Quizzes::QuizSubmission.new
    qs.user_id = 123
    qs.quiz_id = 234
    qs.extra_attempts = 2
    qs.extra_time = 20
    qs.manually_unlocked = true
    qs.end_at = Time.now
    Quizzes::QuizExtension.new(qs, {})
  end

  let :serializer do
    Quizzes::QuizExtensionSerializer.new(quiz_extension,
                                         controller:,
                                         scope: user,
                                         session:)
  end

  before do
    @json = serializer.as_json[:quiz_extension].stringify_keys
  end

  %w[
    user_id quiz_id user_id extra_attempts extra_time manually_unlocked end_at
  ].each do |attr|
    it "serializes #{attr}" do
      expect(@json).to have_key(attr)
    end
  end
end

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
#

require "spec_helper"

describe NewQuizzesHelper do
  include NewQuizzesHelper

  let_once(:account) { Account.default }
  let_once(:course) { course_factory(account:) }

  before do
    @context = course
    allow(Services::NewQuizzes).to receive(:launch_url).and_return("https://newquizzes.example.com/remoteEntry.js")
  end

  describe "#add_new_quizzes_bundle" do
    context "when context does not respond to feature_enabled?" do
      before do
        @context = Object.new
      end

      it "does not add the new quizzes bundle" do
        expect(self).not_to receive(:js_bundle)
        expect(self).not_to receive(:css_bundle)
        expect(self).not_to receive(:remote_env)

        add_new_quizzes_bundle
      end
    end

    context "when new_quizzes_native_experience feature is disabled" do
      before do
        course.disable_feature!(:new_quizzes_native_experience)
      end

      it "does not add the new quizzes bundle" do
        expect(self).not_to receive(:js_bundle)
        expect(self).not_to receive(:css_bundle)
        expect(self).not_to receive(:remote_env)

        add_new_quizzes_bundle
      end
    end

    context "when new_quizzes_native_experience feature is enabled" do
      before do
        course.enable_feature!(:new_quizzes_native_experience)
      end

      it "adds the new quizzes bundle and remote env" do
        expect(self).to receive(:js_bundle).with(:new_quizzes)
        expect(self).to receive(:css_bundle).with(:native_new_quizzes)
        expect(self).to receive(:remote_env).with(
          new_quizzes: {
            launch_url: "https://newquizzes.example.com/remoteEntry.js"
          }
        )

        add_new_quizzes_bundle
      end
    end
  end
end

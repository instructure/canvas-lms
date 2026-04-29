# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe PatchedArrayConnection do
  def build_connection(items)
    conn = described_class.new(items, context: {})
    allow(conn).to receive(:encode) { |str| str }
    conn
  end

  describe "#cursor_for_submission_node" do
    it "returns a cursor for a submission present in items" do
      t1 = Time.zone.now
      t2 = t1 + 1.hour
      s1 = instance_double(Submission, submitted_at: t1)
      s2 = instance_double(Submission, submitted_at: t2)
      conn = build_connection([s1, s2])
      expect { conn.cursor_for_submission_node(s2) }.not_to raise_error
    end

    it "raises ArgumentError when the submission is not found in items" do
      s1 = instance_double(Submission, submitted_at: Time.zone.now)
      outsider = instance_double(Submission, submitted_at: 1.day.ago)
      conn = build_connection([s1])
      expect { conn.cursor_for_submission_node(outsider) }.to raise_error(ArgumentError, /not found in connection items/)
    end
  end

  describe "#cursor_for_quiz_submission_node" do
    it "returns a cursor for a quiz submission present in items" do
      qs = instance_double(Quizzes::QuizSubmission)
      conn = build_connection([qs])
      expect { conn.cursor_for_quiz_submission_node(qs) }.not_to raise_error
    end

    it "raises ArgumentError when the quiz submission is not found in items" do
      qs1 = instance_double(Quizzes::QuizSubmission)
      qs2 = instance_double(Quizzes::QuizSubmission)
      conn = build_connection([qs1])
      expect { conn.cursor_for_quiz_submission_node(qs2) }.to raise_error(ArgumentError, /not found in connection items/)
    end

    it "distinguishes by object identity, not equality" do
      # Two distinct objects that would be == under AR (same id) must not match each other
      qs1 = instance_double(Quizzes::QuizSubmission)
      qs2 = instance_double(Quizzes::QuizSubmission)
      allow(qs1).to receive(:==).and_return(true)
      conn = build_connection([qs1])
      expect { conn.cursor_for_quiz_submission_node(qs2) }.to raise_error(ArgumentError)
    end
  end
end

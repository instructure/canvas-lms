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

require 'spec_helper'

describe QuizzesNext::QuizSerializer do
  subject { quiz_serializer.as_json }

  let(:original_context) do
    Account.default.courses.create
  end

  let(:original_assignment) do
    group = original_context.assignment_groups.create(:name => "some group 1")
    original_context.assignments.create(
      title: 'some assignment 1',
      assignment_group: group,
      due_at: Time.zone.now + 1.week,
      workflow_state: 'published'
    )
  end

  let(:context) do
    Account.default.courses.create
  end

  let(:assignment) do
    group = context.assignment_groups.create(:name => "some group")
    context.assignments.create(
      title: 'some assignment',
      assignment_group: group,
      due_at: Time.zone.now + 1.week,
      workflow_state: 'published',
      duplicate_of: original_assignment
    )
  end
  let(:user) { User.create }
  let(:session) { double(:[] => nil) }
  let(:controller) do
    ActiveModel::FakeController.new(accepts_jsonapi: false, stringify_json_ids: false)
  end
  let(:quiz_serializer) do
    QuizzesNext::QuizSerializer.new(assignment, {
      controller: controller,
      scope: user,
      session: session,
      root: false
    })
  end

  before do
    allow(controller).to receive(:session).and_return session
    allow(controller).to receive(:context).and_return context
    allow(assignment).to receive(:grants_right?).at_least(:once).and_return true
    allow(context).to receive(:grants_right?).at_least(:once).and_return true
  end

  [
    :id, :title, :description, :due_at, :lock_at, :unlock_at,
    :points_possible,
    :assignment_group_id, :migration_id, :only_visible_to_overrides,
    :post_to_sis, :allowed_attempts,
    :workflow_state
  ].each do |attribute|
    it "serializes #{attribute}" do
      expect(subject[attribute]).to eq assignment.send(attribute)
    end
  end

  describe "#quiz_type" do
    it "serializes quiz_type" do
      expect(subject[:quiz_type]).to eq('quizzes.next')
    end
  end

  describe "#published" do
    it "serializes published" do
      expect(subject[:published]).to be(true)
    end
  end

  describe "#course_id" do
    it "serializes course_id" do
      expect(subject[:course_id]).to eq(context.id)
    end
  end

  describe "#assignment_id" do
    it "serializes assignment_id" do
      expect(subject[:assignment_id]).to eq(assignment.id)
    end
  end

  describe "#original_course_id" do
    it "serializes original_course_id" do
      expect(subject[:original_course_id]).to eq(original_context.id)
    end
  end

  describe "#original_assignment_id" do
    it "serializes original_assignment_id" do
      expect(subject[:original_assignment_id]).to eq(original_assignment.id)
    end
  end

  describe "#original_assignment_name" do
    it "serializes original_assignment_name" do
      expect(subject[:original_assignment_name]).to eq('some assignment 1')
    end
  end

  describe "permissions" do
    it "serializes permissions" do
      expect(subject[:permissions]).to include({
        read: true,
        create: true,
        update: true,
        delete: true
      })
    end
  end
end

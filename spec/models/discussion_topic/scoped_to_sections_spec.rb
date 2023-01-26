# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
#
require_relative "../../spec_helper"

describe DiscussionTopic::ScopedToSections do
  let_once(:context) { course_with_teacher.course }
  let_once(:user) { student_in_course(course: context).user }

  describe ".for" do
    let(:scope) { nil }

    context "with a supported consumer" do
      let(:consumer) { DiscussionTopicsController.new }

      it "returns an instance" do
        expect(
          described_class.for(consumer, context, user, scope)
        ).to be_an_instance_of(described_class)
      end
    end

    context "with an unsupported consumer" do
      let(:consumer) { double }

      it "fails" do
        expect do
          described_class.for(consumer, context, user, scope)
        end.to raise_error "Invalid consumer #{consumer.class}"
      end
    end
  end

  describe "#scope" do
    let_once(:announcement) do
      context.announcements.create!(user: @teacher, message: "hello")
    end
    let_once(:scope) { context.active_announcements }

    context "with an instructor" do
      let_once(:subject) { described_class.new(context, @teacher, scope) }

      it "filters nothing" do
        expect(subject.scope).to eq scope
      end
    end

    context "with a student" do
      before(:once) do
        section = context.course_sections.create!(name: "test section")
        announcement.is_section_specific = true
        announcement.course_sections = [section]
        announcement.save!
      end

      let_once(:subject) { described_class.new(context, user, scope) }

      it "filters by section" do
        expect(subject.scope).to be_empty
      end
    end
  end
end

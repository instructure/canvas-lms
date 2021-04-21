# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe MicrosoftSync::UserMapping do
  subject { described_class.create(root_account: account_model, user: user_model) }

  it { is_expected.to be_a(described_class) }
  it { is_expected.to be_valid }
  it { is_expected.to belong_to(:root_account).required }
  it { is_expected.to validate_presence_of(:root_account) }
  it { is_expected.to validate_presence_of(:user_id) }

  describe '.find_enrolled_user_ids_without_mappings' do
    let(:course) { course_with_teacher.course }
    let(:users) do
      [course.enrollments.first.user, *n_students_in_course(3, course: course)]
    end

    it 'returns the user ids of enrolled users without mappings in batches' do
      described_class.create!(user: users[1], root_account: course.root_account, aad_id: 'manual')
      calls_results = []
      described_class.find_enrolled_user_ids_without_mappings(
        course: course, batch_size: 2
      ) do |ids|
        calls_results << ids
      end
      expect(calls_results.flatten.sort).to eq((users - [users[1]]).map(&:id))
      expect(calls_results.length).to eq(2)
    end

    it 'excludes deleted enrollments' do
      course.enrollments.where(user: users.first).take.update!(workflow_state: 'deleted')
      calls_results = []
      described_class.find_enrolled_user_ids_without_mappings(
        course: course, batch_size: 2
      ) do |ids|
        calls_results << ids
      end
      expect(calls_results.flatten.sort).to eq((users - [users.first]).map(&:id))
    end
  end

  describe '.bulk_insert_for_root_account_id' do
    it "creates UserMappings if they don't already exist" do
      account = account_model
      user1 = user_model
      user2 = user_model
      described_class.create!(root_account_id: account.id, user_id: user1.id, aad_id: 'manual')
      described_class.create!(root_account_id: 0, user_id: user2.id, aad_id: 'manual-wrong-ra-id')
      described_class.bulk_insert_for_root_account_id(
        account.id,
        user1.id => 'user1',
        user2.id => 'user2'
      )
      expect(described_class.where(root_account_id: account.id).pluck(:user_id, :aad_id).sort).to \
        eq([[user1.id, 'manual'], [user2.id, 'user2']].sort)
    end

    it "doesn't raise an error on an empty hash" do
      expect { described_class.bulk_insert_for_root_account_id(0, {}) }.to_not \
        change { described_class.count }.from(0)
    end
  end

  describe '.enrollments_and_aads' do
    subject { described_class.enrollments_and_aads(course).pluck(:aad_id, :type).sort }

    let(:course) { course_model }
    let(:example_enrollment_types) { %w[Student Ta Teacher] }
    let!(:enrollments) do
      example_enrollment_types.map do |type|
        create_enrollment(course, user_model, enrollment_type: type + 'Enrollment')
      end
    end
    let!(:user_mappings) do
      enrollments.map do |e|
        described_class.create!(
          root_account: course.root_account, user: e.user, aad_id: e.type.gsub('Enrollment', 'Aad')
        )
      end
    end

    it 'selects at least type and aad_id' do
      expect(described_class.enrollments_and_aads(course).first.type).to end_with('Enrollment')
      expect(described_class.enrollments_and_aads(course).first.aad_id).to end_with('Aad')
    end

    it 'returns a scope with values for "type" and "aad_id"' do
      expect(subject).to eq([
        %w[StudentAad StudentEnrollment], %w[TaAad TaEnrollment], %w[TeacherAad TeacherEnrollment]
      ])
    end

    it 'ignores enrollments of type StudentViewEnrollment' do
      enrollments.first.update!(type: 'StudentViewEnrollment')
      expect(subject).to eq([
        %w[TaAad TaEnrollment], %w[TeacherAad TeacherEnrollment]
      ])
    end

    it 'ignores deleted enrollments' do
      enrollments[0].destroy
      expect(subject).to eq([%w[TaAad TaEnrollment], %w[TeacherAad TeacherEnrollment]])
    end

    it 'ignores enrollments with missing UserMappings' do
      user_mappings[2].destroy
      expect(subject).to eq([%w[StudentAad StudentEnrollment], %w[TaAad TaEnrollment]])
    end

    it 'can be used with find_each on the primary' do
      res = []
      described_class.enrollments_and_aads(course).find_each do |e|
        res << [e.aad_id, e.type]
      end
      expect(res.sort).to eq(subject)
    end
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe MicrosoftSync::PartialSyncChange do
  subject { described_class.create(course:, user:, enrollment_type: "owner") }

  let(:user) { user_model }
  let(:course) { course_with_user("TeacherEnrollment", user:).course }

  it { is_expected.to be_a described_class }
  it { is_expected.to be_valid }
  it { is_expected.to belong_to(:course).required }
  it { is_expected.to belong_to(:user).required }
  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:enrollment_type) }
  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(%i[course_id enrollment_type]) }

  describe ".with_values_in" do
    it "filters to rows where one of the passed-in tuples equals the columns" do
      u1 = user_model
      u2 = user_model
      c1 = course_model
      c2 = course_model
      t1 = 1.minute.ago
      t2 = 2.minutes.ago
      described_class.create!(course: c1, user: u1, enrollment_type: "owner", created_at: t1)
      described_class.create!(course: c1, user: u2, enrollment_type: "owner", created_at: t1)
      described_class.create!(course: c2, user: u1, enrollment_type: "member", created_at: t2)
      described_class.create!(course: c2, user: u2, enrollment_type: "owner", created_at: t2)

      result = described_class
               .where(enrollment_type: "owner")
               .with_values_in(%w[course_id user_id created_at], [
                                 [c1.id, u1.id, t1],
                                 [c1.id, u2.id, t2],
                                 [c2.id, u1.id, t2],
                                 [c2.id, u2.id, t1],
                                 [c2.id, u2.id, t2],
                               ])
               .pluck(:enrollment_type, :course_id, :user_id, :created_at)
      expect(result.sort).to eq([
                                  ["owner", c1.id, u1.id, t1],
                                  ["owner", c2.id, u2.id, t2]
                                ])
    end

    it "produces the right SQL" do
      expect(
        described_class.with_values_in(%w[id course_id user_id], [[1, 2, 3], [4, 5, 6], [7, 8, 9]]).to_sql
      ).to include(
        'WHERE (("id","course_id","user_id") IN ((1,2,3),(4,5,6),(7,8,9)))'
      )
    end

    it "returns no results if array is empty" do
      expect(described_class.with_values_in(%(id course_id), []).to_a).to be_empty
    end
  end

  describe "#upsert_for_enrollment" do
    let(:enrollment) do
      course_with_user(enrollment_type)
    end

    shared_examples_for "upserting a PartialSyncChange record" do
      context "when a record for (user, course, enrollment type) doesn't exist" do
        it "adds a new record" do
          expect { described_class.upsert_for_enrollment(enrollment) }
            .to change { described_class.count }.from(0).to(1)
          record = described_class.last
          expect(record.user).to eq(enrollment.user)
          expect(record.course).to eq(enrollment.course)
          expect(record.enrollment_type).to eq(psc_enrollment_type)
          expect(record.updated_at.to_f).to be_within(30).of(
            described_class.connection.query("SELECT NOW()").first.first.to_f
          )
        end
      end

      context "when a record for (user, course, enrollment type) exists" do
        it "updates the updated_at on the existing record" do
          described_class.upsert_for_enrollment(enrollment)
          record = described_class.last
          record.update!(updated_at: record.updated_at - 1.minute,
                         created_at: record.updated_at - 1.minute)
          updated_at_before_upsert = record.updated_at

          expect { described_class.upsert_for_enrollment(enrollment) }
            .to not_change { described_class.count }.from(1)
                                                    .and not_change { record.reload.attributes.except("updated_at") }
          expect(record.updated_at).to be > updated_at_before_upsert
          expect(record.updated_at.to_f).to be_within(30).of(
            described_class.connection.query("SELECT NOW()").first.first.to_f
          )
        end
      end
    end

    context "for a StudentEnrollment" do
      let(:enrollment_type) { "StudentEnrollment" }
      let(:psc_enrollment_type) { "member" }

      it_behaves_like "upserting a PartialSyncChange record"
    end

    context "for a TeacherEnrollment" do
      let(:enrollment_type) { "TeacherEnrollment" }
      let(:psc_enrollment_type) { "owner" }

      it_behaves_like "upserting a PartialSyncChange record"
    end
  end

  describe "delete_all_replicated_to_secondary_for_course" do
    let(:courses) { [course_model, course_model] }
    let(:users) { [user_model, user_model] }
    let(:pscs) do
      # Creates two courses, two users, and 2 PartialSyncChanges (member, owner) for each combo.
      # A total of 8 PartialSyncChanges.
      courses.map do |c|
        users.map do |u|
          %w[member owner].map do |e_type|
            described_class.create!(course: c, user: u, enrollment_type: e_type)
          end
        end
      end.flatten
    end

    before do
      pscs # building these seem to trigger a GuardRail.activate(:primary) so build them first

      # simulate updating a record that hasn't made it to the secondary by changing the updated_at
      # after we fetch the last updated record from the secondary
      orig_secondary_method = GuardRail.method(:activate)
      allow(GuardRail).to receive(:activate).with(:primary)
      allow(GuardRail).to receive(:activate).with(:secondary) do |*args, &blk|
        res = orig_secondary_method.call(*args, &blk)
        pscs[2].update!(updated_at: 1.hour.from_now)
        res
      end
    end

    it "only deletes records guaranteed to have been replicated to the secondary" do
      # Anything not replicated to the secondary will have an updated_at greater than
      # the last updated_at on the secondary.
      # pscs[2] should be the only one that remains due to use changing its updated_at
      # in the before block above.
      described_class.delete_all_replicated_to_secondary_for_course(courses[0].id)
      expect(described_class.where(course_id: courses[0].id).pluck(:id)).to eq([pscs[2].id])
    end

    it "doesn't delete records for different courses" do
      expect do
        described_class.delete_all_replicated_to_secondary_for_course(courses[0].id)
      end.to_not change { described_class.where(course_id: courses[1].id).count }.from(4)
    end
  end
end

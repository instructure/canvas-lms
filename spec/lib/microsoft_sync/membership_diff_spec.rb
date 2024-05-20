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

require_relative "../../spec_helper"

describe MicrosoftSync::MembershipDiff do
  subject { described_class.new(remote_members, remote_owners) }

  let(:member_enrollment_type) { "StudentEnrollment" }
  let(:owner_enrollment_type) { "TeacherEnrollment" }

  let(:remote_members) { %w[student1 student2 teacher1 teacher4] }
  let(:remote_owners) { %w[teacher1 teacher2 teacher3] }

  let(:slice_size) { 2 }
  let(:additions) do
    [].tap { |results| subject.additions_in_slices_of(slice_size) { |slice| results << slice } }
  end
  let(:additions_all_owners) { additions.map { |addition| addition[:owners] || [] }.flatten.sort }
  let(:additions_all_members) { additions.map { |addition| addition[:members] || [] }.flatten.sort }

  # e.g. set_local_members('student', [1,2,3], 'StudentEnrollment') ->
  #   creates 'student1', 'student2', 'student3'
  def set_local_members(prefix, suffixes, enrollment_type)
    suffixes.each do |suffix|
      subject.set_local_member("#{prefix}#{suffix}", enrollment_type)
    end
  end

  shared_examples_for "a member enrollment type" do |enrollment_type|
    before do
      set_local_members "student", [1, 3, 4], enrollment_type
      set_local_members "teacher", [1, 5], owner_enrollment_type
    end

    describe "#additions_in_slices_of" do
      it "does not indicate #{enrollment_type} users to be added as owners" do
        expect(additions_all_owners.select { |user| user.start_with?("student") }).to eq([])
      end

      it "indicates #{enrollment_type} users to be added as members" do
        expect(additions_all_members.select { |user| user.start_with?("student") })
          .to eq(%w[student3 student4])
      end
    end
  end

  shared_examples_for "an owner enrollment type" do |enrollment_type|
    before do
      set_local_members "student", [1, 3, 4], enrollment_type
      set_local_members "teacher", [1, 5], owner_enrollment_type
    end

    describe "#additions_in_slices_of" do
      it "indicates #{enrollment_type} users to be added as owners" do
        expect(additions_all_owners.select { |user| user.start_with?("teacher") })
          .to eq(%w[teacher5])
      end

      it "indicates #{enrollment_type} users to be added as members" do
        expect(additions_all_members.select { |user| user.start_with?("teacher") })
          .to eq(%w[teacher5])
      end
    end
  end

  describe("TeacherEnrollment") { it_behaves_like "an owner enrollment type", "TeacherEnrollment" }

  describe("TaEnrollment") { it_behaves_like "an owner enrollment type", "TaEnrollment" }

  describe("DesignerEnrollment") { it_behaves_like "an owner enrollment type", "DesignerEnrollment" }

  describe("ObserverEnrollment") { it_behaves_like "a member enrollment type", "ObserverEnrollment" }

  describe("StudentEnrollment") { it_behaves_like "a member enrollment type", "StudentEnrollment" }

  describe "#additions_in_slices_of" do
    before do
      set_local_members "student", [1, 3, 4, 5], member_enrollment_type
      set_local_members "teacher", [1, 2, 4, 5, 6], owner_enrollment_type
    end

    it "batches in slices" do
      counts = additions.map do |a|
        (a[:owners] || []).length + (a[:members] || []).length
      end
      expect(counts).to eq([2, 2, 2, 2, 1])
    end

    it "yields owners first" do
      expect(additions_all_owners).to eq(%w[teacher4 teacher5 teacher6])
      expect((additions[0][:owners] + additions[1][:owners]).sort)
        .to eq(%w[teacher4 teacher5 teacher6])
    end

    it "yields members" do
      expect(additions_all_members).to eq(%w[student3 student4 student5 teacher2 teacher5 teacher6])
    end

    it "adds some members in to the last owners slice if there is room" do
      expect(additions[1][:members].length).to eq(1)
    end

    context "with a different slice size where no members fit into the last owners slice" do
      let(:slice_size) { 3 }

      it "batches in slices" do
        counts = additions.map do |a|
          (a[:owners] || []).length + (a[:members] || []).length
        end
        expect(counts).to eq([3, 3, 3])
      end

      it "yields owners first" do
        expect(additions_all_owners).to eq(%w[teacher4 teacher5 teacher6])
        expect(additions[0][:owners]).to eq(%w[teacher4 teacher5 teacher6])
      end

      it "yields members" do
        expect(additions_all_members).to eq(%w[student3 student4 student5 teacher2 teacher5 teacher6])
      end
    end
  end

  describe "#removals_in_slices_of" do
    let(:removals) do
      [].tap { |results| subject.removals_in_slices_of(slice_size) { |slice| results << slice } }
    end
    let(:removals_all_owners) { removals.map { |removal| removal[:owners] || [] }.flatten.sort }
    let(:removals_all_members) { removals.map { |removal| removal[:members] || [] }.flatten.sort }

    let(:remote_members) { %w[student1 student2 teacher1 teacher4 teacher5] }
    let(:remote_owners) { %w[teacher1 teacher2 teacher3 teacher5] }

    before do
      set_local_members "student", [2], member_enrollment_type
      set_local_members "teacher", [4], member_enrollment_type
      set_local_members "teacher", [5], owner_enrollment_type

      # student1 (remote member, local missing) -> remove as member
      # student2 (remove member, local member) -> OK
      # teacher1 (remote member & owner, local missing) -> remove as member and owner
      # teacher2 (remote owner, local member) -> remove as owner [add as member]
      # teacher3 (remote owner, local missing) -> remove as owner
      # teacher4 (remote member, local member) -> OK
      # teacher5 (remote member & owner, local owner) -> OK
    end

    it "batches in slices" do
      counts = removals.map do |a|
        (a[:owners] || []).length + (a[:members] || []).length
      end
      expect(counts).to eq([2, 2, 1])
    end

    it "yields owners first" do
      expect(removals_all_owners).to eq(%w[teacher1 teacher2 teacher3])
      expect((removals[0][:owners] + removals[1][:owners]).sort)
        .to eq(%w[teacher1 teacher2 teacher3])
    end

    it "yields members" do
      expect(removals_all_members).to eq(%w[student1 teacher1])
    end

    it "adds some members in to the last owners slice if there is room" do
      expect(removals[1][:members].length).to eq(1)
    end

    context "with a different slice size where no members fit into the last owners slice" do
      let(:slice_size) { 3 }

      it "batches in slices" do
        counts = removals.map do |a|
          (a[:owners] || []).length + (a[:members] || []).length
        end
        expect(counts).to eq([3, 2])
      end

      it "yields owners first" do
        expect(removals_all_owners).to eq(%w[teacher1 teacher2 teacher3])
        expect(removals[0][:owners]).to eq(%w[teacher1 teacher2 teacher3])
      end

      it "yields members" do
        expect(removals_all_members).to eq(%w[student1 teacher1])
      end
    end
  end

  describe "#local_owners" do
    it "returns the local owners" do
      set_local_members "teacher", [1], member_enrollment_type
      set_local_members "teacher", [2, 4], owner_enrollment_type
      set_local_members "teacher", [4, 5, 6], owner_enrollment_type
      expect(subject.local_owners).to eq(Set.new(%w[teacher2 teacher4 teacher5 teacher6]))
    end
  end

  describe "#local_owners_or_members" do
    it "returns the local owners and members" do
      set_local_members "student", [2, 3], owner_enrollment_type
      set_local_members "teacher", [2, 4], owner_enrollment_type
      expect(subject.local_owners_or_members).to eq(Set.new(%w[student2 student3 teacher2 teacher4]))
    end
  end

  describe "max_enrollment_members_reached?" do
    let(:half) { max / 2 }
    let(:max) { MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_MEMBERS }
    let(:min) { 1 }

    it "when the members size is less than or equal to the max enrollment members" do
      set_local_members "student", (min..half), member_enrollment_type
      set_local_members "teacher", (half...max), owner_enrollment_type
      expect(subject.max_enrollment_members_reached?).to be false
    end

    it "when the members size is greater than to the max enrollment members" do
      set_local_members "student", (min..half), member_enrollment_type
      set_local_members "teacher", (half..max), owner_enrollment_type
      expect(subject.max_enrollment_members_reached?).to be true
    end
  end

  describe "max_enrollment_owners_reached?" do
    let(:max) { MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_OWNERS }

    it "when the owners size is less than or equal to the max enrollment owners" do
      set_local_members "teacher", (1...max), owner_enrollment_type
      expect(subject.max_enrollment_owners_reached?).to be false
    end

    it "when the owners size is greater than to the max enrollment owners" do
      set_local_members "teacher", (0..max), owner_enrollment_type
      expect(subject.max_enrollment_owners_reached?).to be true
    end
  end
end

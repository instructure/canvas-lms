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

require_relative '../../spec_helper'

describe MicrosoftSync::MembershipDiff do
  subject { described_class.new(remote_members, remote_owners) }

  let(:member_enrollment_type) { 'StudentEnrollment' }
  let(:owner_enrollment_type) { 'TeacherEnrollment' }

  let(:remote_members) { %w[student1 student2 teacher1 teacher4] }
  let(:remote_owners) { %w[teacher1 teacher2 teacher3] }

  let(:slice_size) { 2 }
  let(:additions) do
    [].tap { |results| subject.additions_in_slices_of(slice_size) { |slice| results << slice } }
  end
  let(:additions_all_owners) { additions.map{|addition| addition[:owners] || []}.flatten.sort }
  let(:additions_all_members) { additions.map{|addition| addition[:members] || []}.flatten.sort }

  # e.g. set_local_members('student', [1,2,3], 'StudentEnrollment') ->
  #   creates 'student1', 'student2', 'student3'
  def set_local_members(prefix, suffixes, enrollment_type)
    suffixes.each do |suffix|
      subject.set_local_member("#{prefix}#{suffix}", enrollment_type)
    end
  end

  shared_examples_for 'a member enrollment type' do |enrollment_type|
    before do
      set_local_members 'student', [1, 3, 4], enrollment_type
      set_local_members 'teacher', [1, 5], owner_enrollment_type
    end

    describe '#additions_in_slices_of' do
      it "does not indicate #{enrollment_type} users to be added as owners" do
        expect(additions_all_owners.select{|user| user.start_with?('student')}).to eq([])
      end

      it "indicates #{enrollment_type} users to be added as members" do
        expect(additions_all_members.select{|user| user.start_with?('student')}).to \
          eq(%w[student3 student4])
      end
    end
  end

  shared_examples_for 'an owner enrollment type' do |enrollment_type|
    before do
      set_local_members 'student', [1, 3, 4], enrollment_type
      set_local_members 'teacher', [1, 5], owner_enrollment_type
    end

    describe '#additions_in_slices_of' do
      it "indicates #{enrollment_type} users to be added as owners" do
        expect(additions_all_owners.select{|user| user.start_with?('teacher')}).to \
          eq(%w[teacher5])
      end

      it "indicates #{enrollment_type} users to be added as members" do
        expect(additions_all_members.select{|user| user.start_with?('teacher')}).to \
          eq(%w[teacher5])
      end
    end
  end

  describe('TeacherEnrollment') { it_behaves_like 'an owner enrollment type', 'TeacherEnrollment' }
  describe('TaEnrollment') { it_behaves_like 'an owner enrollment type', 'TaEnrollment' }
  describe('DesignerEnrollment') { it_behaves_like 'an owner enrollment type', 'DesignerEnrollment' }
  describe('ObserverEnrollment') { it_behaves_like 'a member enrollment type', 'ObserverEnrollment' }
  describe('StudentEnrollment') { it_behaves_like 'a member enrollment type', 'StudentEnrollment' }

  describe '#additions_in_slices_of' do
    before do
      set_local_members 'student', [1, 3, 4, 5], member_enrollment_type
      set_local_members 'teacher', [1, 2, 4, 5, 6], owner_enrollment_type
    end

    it 'batches in slices' do
      counts = additions.map do |a|
        (a[:owners] || []).length + (a[:members] || []).length
      end
      expect(counts).to eq([2, 2, 2, 2, 1])
    end

    it 'yields owners first' do
      expect(additions_all_owners).to eq(%w[teacher4 teacher5 teacher6])
      expect((additions[0][:owners] + additions[1][:owners]).sort).to \
        eq(%w[teacher4 teacher5 teacher6])
    end

    it 'yields members' do
      expect(additions_all_members).to eq(%w[student3 student4 student5 teacher2 teacher5 teacher6])
    end

    it 'adds some members in to the last owners slice if there is room' do
      expect(additions[1][:members].length).to eq(1)
    end

    context 'with a different slice size where no members fit into the last owners slice' do
      let(:slice_size) { 3 }

      it 'batches in slices' do
        counts = additions.map do |a|
          (a[:owners] || []).length + (a[:members] || []).length
        end
        expect(counts).to eq([3, 3, 3])
      end

      it 'yields owners first' do
        expect(additions_all_owners).to eq(%w[teacher4 teacher5 teacher6])
        expect(additions[0][:owners]).to eq(%w[teacher4 teacher5 teacher6])
      end

      it 'yields members' do
        expect(additions_all_members).to eq(%w[student3 student4 student5 teacher2 teacher5 teacher6])
      end
    end
  end

  describe '#members_to_remove' do
    before do
      set_local_members 'student', [1, 3, 4, 5], member_enrollment_type
      set_local_members 'teacher', [2, 4, 5, 6], owner_enrollment_type
    end

    it 'returns an Enumerable' do
      expect(subject.members_to_remove).to be_a(Enumerable)
    end

    it 'returns remote users are members but are neither members/owners locally' do
      expect(subject.members_to_remove.to_a.sort).to \
        eq(%w[student2 teacher1])
    end
  end

  describe '#owners_to_remove' do
    before do
      set_local_members 'student', [1, 3, 4, 5], member_enrollment_type
      set_local_members 'teacher', [1], member_enrollment_type
      set_local_members 'teacher', [2, 4, 5, 6], owner_enrollment_type
    end

    it 'returns an Enumerable' do
      expect(subject.owners_to_remove).to be_a(Enumerable)
    end

    it 'returns remote users are owners but are not owners locally' do
      expect(subject.owners_to_remove.to_a.sort).to \
        eq(%w[teacher1 teacher3])
    end
  end
end

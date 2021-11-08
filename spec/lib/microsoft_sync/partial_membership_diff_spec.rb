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

describe MicrosoftSync::PartialMembershipDiff do
  # We test this by adding users for every possible combination:
  # Mapping of change type (m, o) and enrollment state (X=none, M, O) to actions to take:
  # 1. m-X    remove member
  # 2. m-M    add member
  # 3. m-O    ??? do nothing (add member would also be fine but seems unnecessary)
  #   this happens when either:
  #     was MO and M was removed
  #     was O, M added and removed
  #     was M, M removed, O added but not seen yet
  #     was X, M added and removed, O added but not seen yet
  # 4. m-MO   add member
  # 5. o-X    remove member, remove owner
  # 6. o-M    remove owner, add member (future remove-remove-add DANCE)
  # 7. o-O    add member, add owner
  # 8. o-MO   add member, add owner
  # 9. mo-X   remove member, remove owner
  # 10. mo-M  remove owner, add member (future remove-remove-add DANCE)
  # 11. mo-O  add member, add owner
  # 12. mo-MO add member, add owner
  #
  #

  subject { create_diff(users_to_msft_role_types, local_members, member_mappings) }

  let(:users_to_msft_role_types) do
    {
      101 => %w[member],
      102 => %w[member],
      103 => %w[member],
      104 => %w[member],
      105 => %w[owner],
      106 => %w[owner],
      107 => %w[owner],
      108 => %w[owner],
      109 => %w[member owner],
      110 => %w[member owner],
      111 => %w[member owner],
      112 => %w[member owner],
    }
  end

  let(:local_members) do
    [
      # 101 m_X none
      [102, student_enrollment_type], # m_M
      [103, teacher_enrollment_type], # m_O
      [104, student_enrollment_type], # m_MO
      [104, teacher_enrollment_type], # m_MO
      # 105 o_X none
      [106, student_enrollment_type], # o_M
      [107, teacher_enrollment_type], # o_O
      [108, student_enrollment_type], # o_MO
      [108, teacher_enrollment_type], # o_MO
      # 109 mo_X none
      [110, student_enrollment_type], # mo_M
      [111, teacher_enrollment_type], # mo_O
      [112, student_enrollment_type], # mo_MO
      [112, teacher_enrollment_type], # mo_MO
    ]
  end

  let(:student_enrollment_type) { 'StudentEnrollment' }
  let(:teacher_enrollment_type) { 'TeacherEnrollment' }
  let(:slice_size) { 20 }

  let(:member_mappings) do
    {
      'm_X' => 101,
      'm_M' => 102,
      'm_O' => 103,
      'm_MO' => 104,
      'o_X' => 105,
      'o_M' => 106,
      'o_O' => 107,
      'o_MO' => 108,
      'mo_X' => 109,
      'mo_M' => 110,
      'mo_O' => 111,
      'mo_MO' => 112,
    }
  end

  let(:actions_by_aad) { actions_by_aad_for_diff(subject) }

  def actions_by_aad_for_diff(diff)
    actions = Hash.new { |hash, key| hash[key] = [] }

    diff.additions_in_slices_of(slice_size) do |additions|
      additions[:owners]&.each { |aad| actions[aad] << :add_owner }
      additions[:members]&.each { |aad| actions[aad] << :add_member }
    end

    diff.removals_in_slices_of(slice_size) do |removals|
      removals[:owners]&.each { |aad| actions[aad] << :remove_owner }
      removals[:members]&.each { |aad| actions[aad] << :remove_member }
    end

    actions
  end

  def create_diff(users_to_msft_role_types, aads_and_enrollment_types, mappings)
    diff = described_class.new(users_to_msft_role_types)

    aads_and_enrollment_types.each do |aad_id, enrollment_type|
      diff.set_local_member(aad_id, enrollment_type)
    end

    mappings.each do |aad_id, user_id|
      diff.set_member_mapping(user_id, aad_id)
    end

    diff
  end

  EXPECTED_ACTIONS = {
    m_X: %i[remove_member],
    m_M: %i[add_member],
    m_O: [],
    m_MO: %i[add_member],
    o_X: %i[remove_member remove_owner],
    o_M: %i[remove_owner add_member],
    o_O: %i[add_member add_owner],
    o_MO: %i[add_member add_owner],
    mo_X: %i[remove_member remove_owner],
    mo_M: %i[remove_owner add_member],
    mo_O: %i[add_member add_owner],
    mo_MO: %i[add_member add_owner],
  }.transform_values(&:freeze).freeze

  [20, 4].each do |slice_len|
    context "with a slice size of #{slice_len}" do
      let(:slice_size) { slice_len }

      EXPECTED_ACTIONS.each do |aad, actions|
        context "for a user with MSFT role type and enrollment types '#{aad}'" do
          it "executes the actions #{actions.inspect}" do
            expect(actions_by_aad[aad.to_s]).to match_array(EXPECTED_ACTIONS[aad])
          end
        end
      end
    end
  end

  it 'dedupes aads' do
    subject.set_member_mapping(111, 'mo_MO')
    expect(actions_by_aad['mo_O']).to_not be_present
    expect(actions_by_aad['mo_MO']).to match_array(%i[add_member add_owner])
  end

  context 'when mappings are missing' do
    it 'does not suggest any changes for those users' do
      mappings2 = member_mappings.except('m_X', 'o_M')
      diff2 = create_diff(users_to_msft_role_types, local_members, mappings2)
      actions2 = actions_by_aad_for_diff(diff2)

      expect(actions2.keys).to match_array(%w[m_M m_MO o_X o_O o_MO mo_X mo_M mo_O mo_MO])
      expect(actions2).to eq(actions_by_aad.except('m_X', 'o_M'))
    end
  end

  describe 'enrollment type classification' do
    %w[TeacherEnrollment TaEnrollment DesignerEnrollment].each do |owner_enrollment|
      context "when an enrollment is of type #{owner_enrollment}" do
        let(:teacher_enrollment_type) { owner_enrollment }

        it "classifies it as an owner" do
          expect(actions_by_aad['o_O']).to match_array(EXPECTED_ACTIONS[:o_O])
        end
      end
    end

    %w[StudentEnrollment ObserverEnrollment].each do |member_enrollment|
      context "when an enrollment is of type #{member_enrollment}" do
        let(:student_enrollment_type) { member_enrollment }

        it "classifies it as an member" do
          expect(actions_by_aad['o_M']).to match_array(EXPECTED_ACTIONS[:o_M])
        end
      end
    end
  end

  context 'slices' do
    let(:slice_size) { 3 }

    let(:removals_slices) do
      [].tap { |actions| subject.removals_in_slices_of(slice_size) { |slice| actions << slice } }
    end

    let(:additions_slices) do
      [].tap { |actions| subject.additions_in_slices_of(slice_size) { |slice| actions << slice } }
    end

    before { allow(MicrosoftSync::MembershipDiff).to receive(:in_slices_of).and_call_original }

    it 'batches additions in slices, owners first' do
      expect(additions_slices.map { |slice| slice.transform_values(&:count) }).to eq([
                                                                                       { members: 0, owners: 3 },
                                                                                       { members: 2, owners: 1 },
                                                                                       { members: 3 },
                                                                                       { members: 3 },
                                                                                     ])
    end

    it 'batches removals in slices, owners first' do
      expect(removals_slices.map { |slice| slice.transform_values(&:count) }).to eq([
                                                                                      { members: 0, owners: 3 },
                                                                                      { members: 2, owners: 1 },
                                                                                      { members: 1 },
                                                                                    ])
    end

    it 'uses MembershipDiff.in_slices_of for additions' do
      additions_slices
      expect(MicrosoftSync::MembershipDiff).to have_received(:in_slices_of).once
    end

    it 'uses MembershipDiff.in_slices_of for removals' do
      removals_slices
      expect(MicrosoftSync::MembershipDiff).to have_received(:in_slices_of).once
    end
  end

  describe '#log_all_actions' do
    it 'logs user ids, aad ids, change types, enrollment types, and actions' do
      logs = []
      expect(Rails.logger).to receive(:info).at_least(:once) do |line|
        logs << line
      end

      subject.log_all_actions

      logs = logs.map { |l| l.dup.gsub!(/^MicrosoftSync::PartialMembershipDiff: /, '') }.compact.sort

      expect(logs.join("\n")).to eq([
        'User 101 (m_X): change ["member"], enrolls [] -> [:remove_member]',
        'User 102 (m_M): change ["member"], enrolls ["StudentEnrollment"] -> [:add_member]',
        'User 103 (m_O): change ["member"], enrolls ["TeacherEnrollment"] -> []',
        'User 104 (m_MO): change ["member"], enrolls ["StudentEnrollment", "TeacherEnrollment"] -> [:add_member]',
        'User 105 (o_X): change ["owner"], enrolls [] -> [:remove_member, :remove_owner]',
        'User 106 (o_M): change ["owner"], enrolls ["StudentEnrollment"] -> [:add_member, :remove_owner]',
        'User 107 (o_O): change ["owner"], enrolls ["TeacherEnrollment"] -> [:add_member, :add_owner]',
        'User 108 (o_MO): change ["owner"], enrolls ["StudentEnrollment", "TeacherEnrollment"] -> [:add_member, :add_owner]',
        'User 109 (mo_X): change ["member", "owner"], enrolls [] -> [:remove_member, :remove_owner]',
        'User 110 (mo_M): change ["member", "owner"], enrolls ["StudentEnrollment"] -> [:add_member, :remove_owner]',
        'User 111 (mo_O): change ["member", "owner"], enrolls ["TeacherEnrollment"] -> [:add_member, :add_owner]',
        'User 112 (mo_MO): change ["member", "owner"], enrolls ["StudentEnrollment", "TeacherEnrollment"] -> [:add_member, :add_owner]',
      ].join("\n"))
    end
  end
end

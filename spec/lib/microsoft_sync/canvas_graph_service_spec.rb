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

describe MicrosoftSync::CanvasGraphService do
  subject { described_class.new('mytenant123') }

  let(:graph_service) { double('GraphService') }

  before do
    allow(MicrosoftSync::GraphService).to \
      receive(:new).with('mytenant123').and_return(graph_service)
  end

  describe '#list_education_classes_for_course' do
    it 'filters by externalId=course.uuid' do
      course_model
      expect(graph_service).to receive(:list_education_classes).
        with(filter: {externalId: @course.uuid}).
        and_return([{abc: 123}])
      expect(subject.list_education_classes_for_course(@course)).to eq([{abc: 123}])
    end
  end

  describe '#create_education_class' do
    it 'maps course fields to Microsoft education class fields' do
      course_model(public_description: 'great class', name: 'math 101')
      expect(graph_service).to receive(:create_education_class).with(
        description: 'great class',
        displayName: 'math 101',
        externalId: @course.uuid,
        externalName: 'math 101',
        externalSource: 'manual',
        mailNickname: "Course_#{@course.uuid}",
      ).and_return('foo')


      expect(subject.create_education_class(@course)).to eq('foo')
    end
  end

  describe '#update_group_with_course_data' do
    it 'maps course fields to Microsoft fields' do
      course_model(public_description: 'classic', name: 'algebra', sis_source_id: 'ALG-101')
      # force generation of lti context id (normally done lazily)
      lti_context_id = Lti::Asset.opaque_identifier_for(@course)
      expect(lti_context_id).to_not eq(nil)
      expect(graph_service).to receive(:update_group).with(
        'msgroupid',
        microsoft_EducationClassLmsExt: {
          ltiContextId: lti_context_id,
          lmsCourseId: @course.uuid,
          lmsCourseName: 'algebra',
          lmsCourseDescription: 'classic',
        },
        microsoft_EducationClassSisExt: {
          sisCourseId: 'ALG-101',
        }
      ).and_return('foo')

      expect(subject.update_group_with_course_data('msgroupid', @course)).to eq('foo')
    end

    it 'forces generation of lti_context_id if needed' do
      course_model
      expect(Lti::Asset).to receive(:opaque_identifier_for).with(@course).and_return('abcdef')
      expect(graph_service).to receive(:update_group).with(
        'msgroupid',
        hash_including(
          microsoft_EducationClassLmsExt: hash_including(ltiContextId: 'abcdef'),
        )
      ).and_return('foo')

      expect(subject.update_group_with_course_data('msgroupid', @course)).to eq('foo')
    end
  end

  describe '#users_upns_to_aads' do
    it 'returns a hash from UPN to AAD object id' do
      expect(subject.graph_service).to \
        receive(:list_users).
        with(select: %w[id userPrincipalName], filter: {userPrincipalName: %w[a b c d]}).
        and_return([
          {'id' => '789', 'userPrincipalName' => 'd'},
          {'id' => '456', 'userPrincipalName' => 'b'},
          {'id' => '123', 'userPrincipalName' => 'a'},
        ])
      expect(subject.users_upns_to_aads(%w[a b c d])).to eq(
        'a' => '123',
        'b' => '456',
        'd' => '789'
      )
    end

    context 'when passed in more than 15' do
      it 'raises ArgumentError' do
        expect { subject.users_upns_to_aads((1..16).map(&:to_s)) }.to \
          raise_error(ArgumentError, "Can't look up 16 UPNs at once")
      end
    end
  end
end

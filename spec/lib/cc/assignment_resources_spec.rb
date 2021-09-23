# frozen_string_literal: true

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

require File.expand_path(File.dirname(__FILE__) + '/cc_spec_helper')

require 'nokogiri'

describe CC::AssignmentResources do
  let(:assignment) { assignment_model }
  let(:document) { Builder::XmlMarkup.new(target: xml, indent: 2) }
  let(:xml) { +'' }

  describe '#create_canvas_assignment' do
    subject do
      document.assignment(identifier: SecureRandom.uuid) do |a|
        CC::AssignmentResources.create_canvas_assignment(a, assignment)
      end
      Nokogiri::XML(xml) { |c| c.nonet.strict }
    end

    it 'does not set the resource link lookup uuid' do
      expect(subject.at('resource_link_lookup_uuid')).to be_blank
    end

    context 'with an associated LTI 1.3 tool' do
      let(:assignment) do
        course.assignments.new(
          name: 'test assignment',
          submission_types: 'external_tool',
          points_possible: 10
        )
      end

      let(:course) { course_model }
      let(:custom_params) { { foo: 'bar '} }
      let(:developer_key) { DeveloperKey.create!(account: course.root_account) }
      let(:tag) { ContentTag.create!(context: assignment, content: tool, url: tool.url) }
      let(:tool) { external_tool_model(context: course, opts: { use_1_3: true }) }

      before do
        tool.update!(developer_key: developer_key)
        assignment.external_tool_tag = tag
        assignment.save!
        assignment.primary_resource_link.update!(custom: custom_params)
      end

      it 'sets the resource link lookup uuid' do
        expect(subject.at('resource_link_lookup_uuid').text).to eq(
          assignment.primary_resource_link.lookup_uuid
        )
      end
    end
  end
end
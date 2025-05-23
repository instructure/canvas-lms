# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

# Get a list of valid capabilities
# Validate capabilities array
# return capability params hash

module Lti
  describe CapabilitiesHelper do
    let(:root_account) { Account.new(lti_guid: "test-lti-guid") }
    let(:account) { Account.new(root_account:) }
    let(:course) { Course.new(account:, sis_source_id: 12) }
    let(:group_category) { course.group_categories.new(name: "Category") }
    let(:group) { course.groups.new(name: "Group", group_category:) }
    let(:user) { User.new }
    let(:assignment) { Assignment.new }
    let(:collaboration) do
      ExternalToolCollaboration.new(
        title: "my collab",
        user:,
        url: "http://www.example.com"
      )
    end
    let(:substitution_helper) { double.as_null_object }
    let(:right_now) { Time.zone.now }
    let(:tool) do
      shard_mock = double("shard")
      allow(shard_mock).to receive(:settings).and_return({ encription_key: "abc" })
      m = double("tool")
      allow(m).to receive_messages(id: 1,
                                   context: root_account,
                                   shard: shard_mock,
                                   opaque_identifier_for: "6cd2e0d65bd5aef3b5ee56a64bdcd595e447bc8f")
      m
    end
    let(:controller) do
      request_mock = double("request")
      allow(request_mock).to receive_messages(url: "https://localhost", host: "/my/url", scheme: "https")
      m = double("controller")
      allow(m).to receive(:css_url_for).with(:common).and_return("/path/to/common.scss")
      view_context_mock = double("view_context")
      allow(view_context_mock).to receive(:stylesheet_path)
        .and_return(URI.parse(request_mock.url).merge(m.css_url_for(:common)).to_s)
      allow(m).to receive_messages(request: request_mock,
                                   logged_in_user: user,
                                   named_context_url: "url",
                                   polymorphic_url: "url",
                                   view_context: view_context_mock)
      m
    end

    let(:variable_expander) { Lti::VariableExpander.new(root_account, account, controller, current_user: user, tool:) }

    let(:invalid_enabled_caps) { %w[InvalidCap.Foo AnotherInvalid.Bar] }
    let(:valid_enabled_caps) { %w[ToolConsumerInstance.guid Membership.role CourseSection.sourcedId] }
    let(:supported_capabilities) do
      %w[ToolConsumerInstance.guid
         Canvas.term.name
         CourseSection.sourcedId
         Membership.role
         Person.email.primary
         Person.name.given
         Person.name.family
         Person.name.full
         Person.name.display
         Person.sourcedId
         User.id
         User.image
         Message.documentTarget
         Message.locale
         Context.id
         CourseOffering.sourcedId
         com.instructure.File.id
         com.instructure.OriginalityReport.id
         com.instructure.Submission.id
         com.instructure.contextLabel
         vnd.Canvas.root_account.uuid
         vnd.Canvas.OriginalityReport.url
         vnd.Canvas.submission.history.url
         vnd.Canvas.submission.url
         Context.title
         com.instructure.Assignment.lti.id
         com.instructure.Assignment.description
         com.instructure.Assignment.allowedFileExtensions
         com.instructure.Person.name_sortable
         com.instructure.PostMessageToken
         com.instructure.Editor.contents
         com.instructure.Editor.selection
         com.instructure.Group.id
         com.instructure.Group.name
         Canvas.membership.roles
         com.instructure.Course.groupIds
         com.Instructure.membership.roles
         com.instructure.Assignment.anonymous_grading
         com.instructure.Person.pronouns
         com.instructure.User.observees
         com.instructure.User.sectionNames
         com.instructure.Observee.sisIds
         ResourceLink.id
         ResourceLink.description
         ResourceLink.title
         ResourceLink.available.startDateTime
         ResourceLink.available.endDateTime
         ResourceLink.submission.endDateTime]
    end

    describe "#supported_capabilities" do
      it "returns all supported capabilities asociated with launch params" do
        expect(CapabilitiesHelper.supported_capabilities).to include(*supported_capabilities)
      end
    end

    describe "#filter_capabilities" do
      it "removes invalid capabilities" do
        valid_capabilities = CapabilitiesHelper.filter_capabilities(valid_enabled_caps + invalid_enabled_caps)
        expect(valid_capabilities).not_to include(*invalid_enabled_caps)
      end

      it "does not remove valid capabilities" do
        valid_capabilities = CapabilitiesHelper.filter_capabilities(valid_enabled_caps + invalid_enabled_caps)
        expect(valid_capabilities).to match_array valid_enabled_caps
      end
    end

    describe "#capability_params_hash" do
      let(:valid_keys) { %w[tool_consumer_instance_guid roles lis_course_section_sourcedid] }

      it "does not include a name (key) for invalid capabilities" do
        params_hash = CapabilitiesHelper.capability_params_hash(invalid_enabled_caps + valid_enabled_caps, variable_expander)
        expect(params_hash.keys).not_to include(*invalid_enabled_caps)
      end

      context "in a course" do
        let(:variable_expander) { VariableExpander.new(root_account, course, controller, current_user: user, tool:) }

        it "does include a valid name (key) for valid capabilities" do
          params_hash = CapabilitiesHelper.capability_params_hash(invalid_enabled_caps + valid_enabled_caps, variable_expander)
          expect(params_hash.keys).to include(*valid_keys)
        end

        it "does include a value for each valid capability" do
          params_hash = CapabilitiesHelper.capability_params_hash(invalid_enabled_caps + valid_enabled_caps, variable_expander)
          expect(params_hash.values.length).to eq valid_keys.length
        end
      end
    end
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe Lti::LtiContextCreator do
  let(:root_account) do
    Account.create!.tap do |account|
      account.name = "root_account"
      account.lti_guid = "lti_guid"
      allow(account).to receive_messages(domain: "account_domain", id: 42)
      account.sis_source_id = "account_sis_id"
    end
  end
  let(:canvas_tool) do
    ContextExternalTool.new.tap do |canvas_tool|
      canvas_tool.context = root_account
      allow(canvas_tool).to receive(:opaque_identifier_for).and_return("opaque_id")
    end
  end

  describe "#convert" do
    describe "consumer instance" do
      let(:canvas_user) { user_factory(name: "Shorty McLongishname") }
      let(:lti_context_creator) { Lti::LtiContextCreator.new(canvas_user, canvas_tool) }

      it "generates a consumer instance from the tool" do
        consumer_instance = lti_context_creator.convert.consumer_instance

        expect(consumer_instance).to be_a(LtiOutbound::LTIConsumerInstance)
        expect(consumer_instance.name).to eq "root_account"
        expect(consumer_instance.lti_guid).to eq "lti_guid"
        expect(consumer_instance.id).to eq 42
        expect(consumer_instance.sis_source_id).to eq "account_sis_id"
      end

      it "uses the consumer_instance_class property of LtiOutboundAdapter" do
        some_class = Class.new(LtiOutbound::LTIConsumerInstance)
        Lti::LtiOutboundAdapter.consumer_instance_class = some_class

        consumer_instance = lti_context_creator.convert.consumer_instance

        expect(consumer_instance).to be_a(some_class)

        Lti::LtiOutboundAdapter.consumer_instance_class = nil
      end
    end

    describe "for canvas user" do
      let(:canvas_user) { user_factory(name: "Shorty McLongishname") }
      let(:lti_context_creator) { Lti::LtiContextCreator.new(canvas_user, canvas_tool) }

      it "converts a user to an lti_user" do
        allow(canvas_user).to receive(:id).and_return(123)
        lti_user = lti_context_creator.convert

        expect(lti_user).to be_a(LtiOutbound::LTIUser)

        expect(lti_user.opaque_identifier).to eq "opaque_id"
        expect(lti_user.id).to eq 123
        expect(lti_user.name).to eq "Shorty McLongishname"
      end
    end

    describe "for a canvas course" do
      let(:canvas_course) do
        course_factory(active_course: true, course_name: "my course").tap do |course|
          course.course_code = "abc"
          course.sis_source_id = "sis_id"
          course.root_account = root_account
          allow(course).to receive(:id).and_return(123)
        end
      end

      let(:lti_context_creator) { Lti::LtiContextCreator.new(canvas_course, canvas_tool) }

      it "converts a course to an lti_course" do
        lti_course = lti_context_creator.convert

        expect(lti_course).to be_a(LtiOutbound::LTICourse)
        expect(lti_course.opaque_identifier).to eq "opaque_id"
        expect(lti_course.id).to eq 123
        expect(lti_course.name).to eq "my course"

        expect(lti_course.course_code).to eq "abc"
        expect(lti_course.sis_source_id).to eq "sis_id"
      end

      it "generates a consumer instance from the course" do
        consumer_instance = lti_context_creator.convert.consumer_instance
        expect(consumer_instance.id).to eq 42
      end
    end

    describe "for a canvas account" do
      let(:canvas_account) do
        root_account.sub_accounts.create!(name: "account name").tap do |account|
          account.root_account = root_account
          allow(account).to receive(:id).and_return(123)
          account.sis_source_id = "sis_id"
        end
      end

      let(:lti_context_creator) { Lti::LtiContextCreator.new(canvas_account, canvas_tool) }

      it "converts a account to an lti_account" do
        lti_account = lti_context_creator.convert

        expect(lti_account).to be_a(LtiOutbound::LTIContext)
        expect(lti_account.opaque_identifier).to eq "opaque_id"
        expect(lti_account.id).to eq 123
        expect(lti_account.name).to eq "account name"

        expect(lti_account.sis_source_id).to eq "sis_id"
      end

      it "generates a consumer instance from the course" do
        consumer_instance = lti_context_creator.convert.consumer_instance
        expect(consumer_instance.id).to eq 42
      end
    end
  end
end

#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Lti::LtiContextCreator do
  let(:root_account) do
    Account.create!.tap do |account|
      account.name = 'root_account'
      account.lti_guid = 'lti_guid'
      account.stubs(:domain).returns('account_domain')
      account.stubs(:id).returns(42)
      account.sis_source_id = 'account_sis_id'
    end
  end
  let(:canvas_tool) do
    ContextExternalTool.new.tap do |canvas_tool|
      canvas_tool.context = root_account
      canvas_tool.stubs(:opaque_identifier_for).returns('opaque_id')
    end
  end

  describe "#convert" do

    describe "consumer instance" do
      let(:canvas_user) { user(name: 'Shorty McLongishname') }
      let(:lti_context_creator) { Lti::LtiContextCreator.new(canvas_user, canvas_tool) }

      it "generates a consumer instance from the tool" do
        consumer_instance = lti_context_creator.convert.consumer_instance

        consumer_instance.should be_a(LtiOutbound::LTIConsumerInstance)
        consumer_instance.name.should == 'root_account'
        consumer_instance.lti_guid.should == 'lti_guid'
        consumer_instance.id.should == 42
        consumer_instance.sis_source_id.should == 'account_sis_id'
      end

      it "uses the consumer_instance_class property of LtiOutboundAdapter" do
        some_class = Class.new(LtiOutbound::LTIConsumerInstance)
        Lti::LtiOutboundAdapter.consumer_instance_class = some_class

        consumer_instance = lti_context_creator.convert.consumer_instance

        consumer_instance.should be_a(some_class)

        Lti::LtiOutboundAdapter.consumer_instance_class = nil
      end
    end

    describe "for canvas user" do
      let(:canvas_user) { user(name: 'Shorty McLongishname') }
      let(:lti_context_creator) { Lti::LtiContextCreator.new(canvas_user, canvas_tool) }

      it "converts a user to an lti_user" do
        canvas_user.stubs(:id).returns(123)
        lti_user = lti_context_creator.convert

        lti_user.should be_a(LtiOutbound::LTIUser)

        lti_user.opaque_identifier.should == 'opaque_id'
        lti_user.id.should == 123
        lti_user.name.should == 'Shorty McLongishname'
      end
    end

    describe "for a canvas course" do
      let(:canvas_course) do
        course(active_course: true, course_name: 'my course').tap do |course|
          course.course_code = 'abc'
          course.sis_source_id = 'sis_id'
          course.root_account = root_account
          course.stubs(:id).returns(123)
        end
      end

      let(:lti_context_creator) { Lti::LtiContextCreator.new(canvas_course, canvas_tool) }

      it "converts a course to an lti_course" do
        lti_course = lti_context_creator.convert

        lti_course.should be_a(LtiOutbound::LTICourse)
        lti_course.opaque_identifier.should == 'opaque_id'
        lti_course.id.should == 123
        lti_course.name.should == 'my course'

        lti_course.course_code.should == 'abc'
        lti_course.sis_source_id.should == 'sis_id'
      end

      it "generates a consumer instance from the course" do
        consumer_instance = lti_context_creator.convert.consumer_instance
        consumer_instance.id.should == 42
      end
    end

    describe "for a canvas account" do
      let(:canvas_account) do
        Account.create!.tap do |account|
          account.name = 'account name'
          account.root_account = root_account
          account.stubs(:id).returns(123)
          account.sis_source_id = 'sis_id'
        end
      end

      let(:lti_context_creator) { Lti::LtiContextCreator.new(canvas_account, canvas_tool) }

      it "converts a account to an lti_account" do
        lti_account = lti_context_creator.convert

        lti_account.should be_a(LtiOutbound::LTIContext)
        lti_account.opaque_identifier.should == 'opaque_id'
        lti_account.id.should == 123
        lti_account.name.should == 'account name'

        lti_account.sis_source_id.should == 'sis_id'
      end

      it "generates a consumer instance from the course" do
        consumer_instance = lti_context_creator.convert.consumer_instance
        consumer_instance.id.should == 42
      end
    end
  end
end
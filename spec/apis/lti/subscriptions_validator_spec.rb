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
#

require File.expand_path(File.dirname(__FILE__) + '../../../lti2_spec_helper')
require_dependency "lti/subscriptions_validator"
module Lti
  describe SubscriptionsValidator do
    include_context 'lti2_spec_helper'

    let(:subscription) do
      {
        RootAccountUUID: account.uuid,
        EventTypes:["submission_created"],
        ContextType: "root_account",
        ContextId: account.uuid,
        Format: "live-event",
        TransportType: "sqs",
        TransportMetadata: { Url: "http://sqs.docker"},
        UserId: "2"
      }
    end

    describe "#check_required_capabilities!" do
      context "ALL" do
        let(:tool_proxy) do
          Lti::ToolProxy.create!(
            context: account,
            guid: SecureRandom.uuid,
            shared_secret: 'abc',
            product_family: product_family,
            product_version: '1',
            workflow_state: 'active',
            raw_data: {'enabled_capability' => ['vnd.instructure.webhooks.root_account.all']},
            lti_version: '1'
          )
        end
        let(:validator){ SubscriptionsValidator.new(subscription, tool_proxy) }

        it 'allows all subscription types if installed in context' do
          expect { validator.check_required_capabilities! }.not_to raise_error
        end
      end

      context "QUIZ_SUBMITTED" do
        let(:subscription) do
          {
            RootAccountUUID: account.uuid,
            EventTypes:["quiz_submitted"],
            ContextType: "root_account",
            ContextId: account.uuid,
            Format: "live-event",
            TransportType: "sqs",
            TransportMetadata: { Url: "http://sqs.docker"},
            UserId: "2"
          }
        end
        let(:tool_proxy) do
          Lti::ToolProxy.create!(
            context: account,
            guid: SecureRandom.uuid,
            shared_secret: 'abc',
            product_family: product_family,
            product_version: '1',
            workflow_state: 'active',
            raw_data: {'enabled_capability' => ['vnd.instructure.webhooks.root_account.quiz_submitted']},
            lti_version: '1'
          )
        end

        it 'allows subscription if vnd.instructure.webhooks.root_account.quiz_submitted enabled' do
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'allows subscription if vnd.instructure.webhooks.assignment.quiz_submitted enabled' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.quiz_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'raises MissingCapability if missing capabilities' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.submission_created)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.to raise_error SubscriptionsValidator::MissingCapability
        end
      end

      context "GRADE_CHANGE" do
        let(:subscription) do
          {
            RootAccountUUID: account.uuid,
            EventTypes:["grade_change"],
            ContextType: "root_account",
            ContextId: account.uuid,
            Format: "live-event",
            TransportType: "sqs",
            TransportMetadata: { Url: "http://sqs.docker"},
            UserId: "2"
          }
        end
        let(:tool_proxy) do
          Lti::ToolProxy.create!(
            context: account,
            guid: SecureRandom.uuid,
            shared_secret: 'abc',
            product_family: product_family,
            product_version: '1',
            workflow_state: 'active',
            raw_data: {'enabled_capability' => ['vnd.instructure.webhooks.root_account.grade_change']},
            lti_version: '1'
          )
        end

        it 'allows subscription if vnd.instructure.webhooks.root_account.grade_change' do
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'raises MissingCapability if missing capabilities' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.quiz_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.to raise_error SubscriptionsValidator::MissingCapability
        end
      end

      context "ATTACHMENT_CREATED" do
        let(:subscription) do
          {
            RootAccountUUID: account.uuid,
            EventTypes:["attachment_created"],
            ContextType: "root_account",
            ContextId: account.uuid,
            Format: "live-event",
            TransportType: "sqs",
            TransportMetadata: { Url: "http://sqs.docker"},
            UserId: "2"
          }
        end
        let(:tool_proxy) do
          Lti::ToolProxy.create!(
            context: account,
            guid: SecureRandom.uuid,
            shared_secret: 'abc',
            product_family: product_family,
            product_version: '1',
            workflow_state: 'active',
            raw_data: {'enabled_capability' => ['vnd.instructure.webhooks.root_account.attachment_created']},
            lti_version: '1'
          )
        end

        it 'allows subscription if vnd.instructure.webhooks.root_account.attachment_created' do
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'allows subscription if vnd.instructure.webhooks.assignment.attachment_created' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.attachment_created)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'raises MissingCapability if missing capabilities' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.quiz_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.to raise_error SubscriptionsValidator::MissingCapability
        end
      end

      context "SUBMISSION_CREATED" do
        let(:subscription) do
          {
            RootAccountUUID: account.uuid,
            EventTypes:["submission_created"],
            ContextType: "root_account",
            ContextId: account.uuid,
            Format: "live-event",
            TransportType: "sqs",
            TransportMetadata: { Url: "http://sqs.docker"},
            UserId: "2"
          }
        end
        let(:tool_proxy) do
          Lti::ToolProxy.create!(
            context: account,
            guid: SecureRandom.uuid,
            shared_secret: 'abc',
            product_family: product_family,
            product_version: '1',
            workflow_state: 'active',
            raw_data: {'enabled_capability' => ['vnd.instructure.webhooks.root_account.submission_created']},
            lti_version: '1'
          )
        end

        it 'allows subscription if vnd.instructure.webhooks.root_account.submission_created' do
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'allows subscription if vnd.instructure.webhooks.assignment.submission_created' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.submission_created)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'raises MissingCapability if missing capabilities' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.quiz_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.to raise_error SubscriptionsValidator::MissingCapability
        end
      end

      context "SUBMISSION_UPDATED" do
        let(:subscription) do
          {
            RootAccountUUID: account.uuid,
            EventTypes:["submission_updated"],
            ContextType: "root_account",
            ContextId: account.uuid,
            Format: "live-event",
            TransportType: "sqs",
            TransportMetadata: { Url: "http://sqs.docker"},
            UserId: "2"
          }
        end
        let(:tool_proxy) do
          Lti::ToolProxy.create!(
            context: account,
            guid: SecureRandom.uuid,
            shared_secret: 'abc',
            product_family: product_family,
            product_version: '1',
            workflow_state: 'active',
            raw_data: {'enabled_capability' => ['vnd.instructure.webhooks.root_account.submission_updated']},
            lti_version: '1'
          )
        end

        it 'allows subscription if vnd.instructure.webhooks.root_account.submission_updated' do
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'allows subscription if vnd.instructure.webhooks.assignment.submission_updated' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.submission_updated)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'raises MissingCapability if missing capabilities' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.quiz_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.to raise_error SubscriptionsValidator::MissingCapability
        end
      end

      context "PLAGIARISM_RESUBMIT" do
        let(:subscription) do
          {
            RootAccountUUID: account.uuid,
            EventTypes:["plagiarism_resubmit"],
            ContextType: "root_account",
            ContextId: account.uuid,
            Format: "live-event",
            TransportType: "sqs",
            TransportMetadata: { Url: "http://sqs.docker"},
            UserId: "2"
          }
        end
        let(:tool_proxy) do
          Lti::ToolProxy.create!(
            context: account,
            guid: SecureRandom.uuid,
            shared_secret: 'abc',
            product_family: product_family,
            product_version: '1',
            workflow_state: 'active',
            raw_data: {'enabled_capability' => ['vnd.instructure.webhooks.root_account.plagiarism_resubmit']},
            lti_version: '1'
          )
        end

        it 'allows subscription if vnd.instructure.webhooks.root_account.plagiarism_resubmit' do
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'allows subscription if vnd.instructure.webhooks.assignment.submission_created' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.plagiarism_resubmit)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'raises MissingCapability if missing capabilities' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.quiz_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.to raise_error SubscriptionsValidator::MissingCapability
        end
      end
    end

    describe "#check_tool_context!" do
      let(:subscription) do
        {
          RootAccountUUID: account.uuid,
          EventTypes:["grade_changed"],
          ContextType: "root_account",
          ContextId: account.uuid,
          Format: "live-event",
          TransportType: "sqs",
          TransportMetadata: { Url: "http://sqs.docker"},
          UserId: "2"
        }
      end
      let(:tool_proxy) do
        Lti::ToolProxy.create!(
          context: account,
          guid: SecureRandom.uuid,
          shared_secret: 'abc',
          product_family: product_family,
          product_version: '1',
          workflow_state: 'active',
          raw_data: {'enabled_capability' => ['vnd.instructure.webhooks.root_account.all']},
          lti_version: '1'
        )
      end
      let(:validator){ SubscriptionsValidator.new(subscription, tool_proxy) }

      it "does not raise error if ToolProxy::active_in_context? returns true" do
        allow_any_instance_of(Lti::ToolProxy).to receive(:active_in_context?).and_return(true)
        expect { validator.check_tool_context! }.not_to raise_error
      end

      it "Uses the assignment's course as the context" do
        allow_any_instance_of(Lti::ToolProxy).to receive(:active_in_context?).with(an_instance_of(Course)).and_return(true)
        course = Course.create!(account: account)
        assignment = course.assignments.create!(title: "some assignment")

        subscription[:ContextType] = 'assignment'
        subscription[:ContextId] = assignment.id
        expect { validator.check_tool_context! }.not_to raise_error
      end

      it "raises ToolNotInContext if ToolProxy::active_in_context? returns false" do
        a = Account.create!
        subscription[:ContextId] = a.uuid
        expect { validator.check_tool_context! }.to raise_error(SubscriptionsValidator::ToolNotInContext)
      end

      it "raises InvalidContextType if a non-whilelisted context is requested" do
        subscription[:ContextType] = 'user'
        subscription[:ContextId] = '2'
        expect { validator.check_tool_context! }.to raise_error(SubscriptionsValidator::InvalidContextType)
      end
    end
  end
end

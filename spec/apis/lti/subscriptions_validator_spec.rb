require File.expand_path(File.dirname(__FILE__) + '../../../lti2_spec_helper')
require_dependency "lti/subscriptions_validator"
module Lti
  describe SubscriptionsValidator do
    include_context 'lti2_spec_helper'

    let(:subscription) do
      {
        RootAccountId: account.id,
        EventTypes:["submission_created"],
        ContextType: "account",
        ContextId: account.id,
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
            raw_data: {'enabled_capability' => ['vnd.Canvas.webhooks.root_account.all']},
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
            RootAccountId: account.id,
            EventTypes:["quiz_submitted"],
            ContextType: "account",
            ContextId: account.id,
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

        it 'allows subscription if vnd.instructure.webhooks.course.quiz_submitted enabled' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.course.quiz_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'allows subscription if vnd.instructure.webhooks.assignment.quiz_submitted enabled' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.quiz_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'raises MissingCapability if missing capaiblities' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.assignment_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.to raise_error SubscriptionsValidator::MissingCapability
        end
      end

      context "ASSIGNMENT_SUBMITTED" do
        let(:subscription) do
          {
            RootAccountId: account.id,
            EventTypes:["assignment_submitted"],
            ContextType: "account",
            ContextId: account.id,
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
            raw_data: {'enabled_capability' => ['vnd.instructure.webhooks.root_account.assignment_submitted']},
            lti_version: '1'
          )
        end

        it 'allows subscription if vnd.instructure.webhooks.root_account.assignment_submitted' do
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'allows subscription if vnd.instructure.webhooks.course.assignment_submitted enabled' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.course.assignment_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'allows subscription if vnd.instructure.webhooks.assignment.assignment_submitted enabled' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.assignment_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'raises MissingCapability if missing capaiblities' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.quiz_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.to raise_error SubscriptionsValidator::MissingCapability
        end
      end

      context "GRADE_CHANGED" do
        let(:subscription) do
          {
            RootAccountId: account.id,
            EventTypes:["grade_changed"],
            ContextType: "account",
            ContextId: account.id,
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
            raw_data: {'enabled_capability' => ['vnd.instructure.webhooks.root_account.grade_changed']},
            lti_version: '1'
          )
        end

        it 'allows subscription if vnd.instructure.webhooks.root_account.grade_changed' do
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'allows subscription if vnd.instructure.webhooks.course.grade_changed' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.course.grade_changed)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'raises MissingCapability if missing capaiblities' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.quiz_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.to raise_error SubscriptionsValidator::MissingCapability
        end
      end

      context "ATTACHMENT_CREATED" do
        let(:subscription) do
          {
            RootAccountId: account.id,
            EventTypes:["attachment_created"],
            ContextType: "account",
            ContextId: account.id,
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

        it 'raises MissingCapability if missing capaiblities' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.quiz_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.to raise_error SubscriptionsValidator::MissingCapability
        end
      end

      context "SUBMISSION_CREATED" do
        let(:subscription) do
          {
            RootAccountId: account.id,
            EventTypes:["submission_created"],
            ContextType: "account",
            ContextId: account.id,
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

        it 'allows subscription if vnd.instructure.webhooks.root_account.attachment_created' do
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'allows subscription if vnd.instructure.webhooks.assignment.submission_created' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.submission_created)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.not_to raise_error
        end

        it 'raises MissingCapability if missing capaiblities' do
          tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.instructure.webhooks.assignment.quiz_submitted)
          validator = SubscriptionsValidator.new(subscription, tool_proxy)
          expect { validator.check_required_capabilities! }.to raise_error SubscriptionsValidator::MissingCapability
        end
      end
    end

    describe "#check_tool_context!" do
      let(:subscription) do
        {
          RootAccountId: account.id,
          EventTypes:["grade_changed"],
          ContextType: "account",
          ContextId: account.id,
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
          raw_data: {'enabled_capability' => ['vnd.Canvas.webhooks.root_account.all']},
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
        subscription[:ContextId] = a.id
        expect { validator.check_tool_context! }.to raise_error(SubscriptionsValidator::ToolNotInContext)
      end

      it "raises InvalidContextType if a non-whilelisted context is requested" do
        subscription[:ContextType] = 'User'
        subscription[:ContextId] = '2'
        expect { validator.check_tool_context! }.to raise_error(SubscriptionsValidator::InvalidContextType)
      end
    end
  end
end

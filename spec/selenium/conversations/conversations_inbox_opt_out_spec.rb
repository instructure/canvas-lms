require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

describe "conversations new" do
  include_examples "in-process server selenium tests"

  before do
    conversation_setup
  end

  describe 'conversations inbox opt-out option' do
    it "should be hidden a feature flag" do
      get "/profile/settings"
      expect(ff('#disable_inbox').count).to eq 0
    end

    it "should reveal when the feature flag is set" do
      @course.root_account.enable_feature!(:allow_opt_out_of_inbox)
      get "/profile/settings"
      expect(ff('#disable_inbox').count).to eq 1
    end

    context "when activated" do
      it "should set the notification preferences for conversations to ASAP, and hide those options" do
        @course.root_account.enable_feature!(:allow_opt_out_of_inbox)
        expect(@teacher.reload.disabled_inbox?).to be_falsey
        notification = Notification.create!(workflow_state: "active", name: "Conversation Message",
                             category: "Conversation Message", delay_for: 0)
        policy = NotificationPolicy.create!(notification_id: notification.id, communication_channel_id: @teacher.email_channel.id, broadcast: true, frequency: "weekly")
        @teacher.update_attribute(:unread_conversations_count, 3)
        sleep 0.5

        get '/profile/communication'
        expect(ff('td[data-category="conversation_message"]').count).to eq 1
        expect(ff('.unread-messages-count').count).to eq 1

        get "/profile/settings"
        f('#disable_inbox').click
        sleep 0.5

        expect(@teacher.reload.disabled_inbox?).to be_truthy

        get '/profile/communication'
        expect(ff('td[data-category="conversation_message"]').count).to eq 0
        expect(policy.reload.frequency).to eq "immediately"
        expect(ff('.unread-messages-count').count).to eq 0
      end
    end
  end
end

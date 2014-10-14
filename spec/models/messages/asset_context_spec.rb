require 'spec_helper'

module Messages

  describe AssetContext do
    let(:author){ stub("Author", short_name: "Author Name") }
    let(:user){ stub("User", short_name: "User Name") }
    let(:asset){ stub("Asset", user: user, author: author) }

    def asset_for(notification_name)
      AssetContext.new(asset, notification_name)
    end

    describe '#reply_to_name' do
      it 'is nil for notification types that dont have source users' do
        expect(asset_for("Nonsense").reply_to_name).to be_nil
      end

      it 'uses the author name for messages with authors' do
        expect(asset_for("Submission Comment").reply_to_name).to  eq "Author Name via Canvas Notifications"
      end

      it 'uses the user name for messages belonging to users' do
        expect(asset_for("New Discussion Entry").reply_to_name).to  eq "User Name via Canvas Notifications"
      end
    end

    describe '#from_name' do
      it 'is nil for notification types that dont have source users' do
        expect(asset_for("Nonsense").from_name).to be_nil
      end

      it 'uses the author name for messages with authors' do
        expect(asset_for("Conversation Message").from_name).to eq "Author Name"
      end

      it 'uses the user name for messages belonging to users' do
        expect(asset_for("Assignment Resubmitted").from_name).to eq "User Name"
      end
    end
  end
end

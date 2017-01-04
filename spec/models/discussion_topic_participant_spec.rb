

require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

describe DiscussionTopicParticipant do
  describe 'check_unread_count' do
    before(:once) do
      @participant = DiscussionTopicParticipant.create!(:user => user_factory,
        :discussion_topic => discussion_topic_model)
    end

    it 'should set negative unread_counts to zero on save' do
      @participant.update_attribute(:unread_entry_count, -15)
      expect(@participant.unread_entry_count).to eq 0
    end

    it 'should not change an unread_count of zero' do
      @participant.update_attribute(:unread_entry_count, 0)
      expect(@participant.unread_entry_count).to eq 0
    end

    it 'should not change a positive unread_count' do
      @participant.update_attribute(:unread_entry_count, 15)
      expect(@participant.unread_entry_count).to eq 15
    end
  end
end

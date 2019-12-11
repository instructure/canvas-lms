#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Eportfolio do
  context "validations" do
    describe "spam_status" do
      before(:once) do
        @user = User.create!
        @eportfolio = Eportfolio.new(user: @user, name: 'an eportfolio')
      end

      it "is valid when spam_status is nil" do
        @eportfolio.spam_status = nil
        expect(@eportfolio).to be_valid
      end

      it "is valid when spam_status is 'marked_as_spam'" do
        @eportfolio.spam_status = 'marked_as_spam'
        expect(@eportfolio).to be_valid
      end

      it "is valid when spam_status is 'marked_as_safe'" do
        @eportfolio.spam_status = 'marked_as_safe'
        expect(@eportfolio).to be_valid
      end

      it "is valid when spam_status is 'flagged_as_possible_spam'" do
        @eportfolio.spam_status = 'flagged_as_possible_spam'
        expect(@eportfolio).to be_valid
      end

      it "is invalid when spam_status is not nil, 'marked_as_spam', 'marked_as_safe', or 'flagged_as_possible_spam'" do
        @eportfolio.spam_status = 'a_new_status'
        expect(@eportfolio).to be_invalid
      end
    end
  end

  describe "#ensure_defaults" do
    before(:once) do
      eportfolio
    end

    it "should create a category if one doesn't exist" do
      expect(@portfolio.eportfolio_categories).to be_empty
      @portfolio.ensure_defaults
      expect(@portfolio.reload.eportfolio_categories).not_to be_empty
    end

    it "should create an entry in the first category if one doesn't exist" do
      @category = @portfolio.eportfolio_categories.create!(:name => "Hi")
      expect(@category.eportfolio_entries).to be_empty
      @portfolio.ensure_defaults
      expect(@category.reload.eportfolio_entries).not_to be_empty
    end
  end

  describe "callbacks" do
    describe "#check_for_spam" do
      let(:user) { User.create! }
      let(:eportfolio) { Eportfolio.create!(name: "my file", user: user) }
      let(:spam_status) { eportfolio.reload.spam_status }

      context "when the setting has a value and the release flag is enabled" do
        before(:each) do
          user.account.root_account.enable_feature!(:eportfolio_moderation)
          Setting.set('eportfolio_title_spam_keywords', 'bad, verybad, worse')
        end

        it "marks as possible spam when the title matches one or more keywords" do
          eportfolio.update!(name: "my verybad page")
          expect(spam_status).to eq "flagged_as_possible_spam"
        end

        it "does not mark as spam when the title matches no keywords" do
          expect {
            eportfolio.update!(name: "my great and notbad page")
          }.not_to change { spam_status }
        end

        it "does not mark as spam if a spam_status already exists" do
          eportfolio.update!(spam_status: "marked_as_safe")

          expect {
            eportfolio.update!(name: "actually a bad page")
          }.not_to change { spam_status }
        end
      end

      it "does not attempt to mark as spam when the setting is empty" do
        user.account.root_account.enable_feature!(:eportfolio_moderation)
        expect {
          eportfolio.update!(name: "actually a bad page")
        }.not_to change { spam_status }
      end

      it "does not attempt to mark as spam when the release flag is not enabled" do
        Setting.set('eportfolio_title_spam_keywords', 'bad, verybad, worse')
        expect {
          eportfolio.update!(name: "actually a bad page")
        }.not_to change { spam_status }
      end
    end
  end
end

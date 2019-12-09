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
end

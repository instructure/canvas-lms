#
# Copyright (C) 2011 Instructure, Inc.
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

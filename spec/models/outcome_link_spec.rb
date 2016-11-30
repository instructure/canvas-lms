#
# Copyright (C) 2016 Instructure, Inc.
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

describe OutcomeLink do

  describe "global outcome links" do
    before do
      @root = LearningOutcomeGroup.global_root_outcome_group
      @outcome = LearningOutcome.new(short_description: "blank")
      @outcome.save!
      @link = @root.add_outcome(@outcome)
    end
    it "should be destroyable" do
      expect(@link.can_destroy?).to be_truthy
    end

    it "returns links with no context" do
      links = OutcomeLink.outcome_links_for_context(@root)
      expect(links.count).to eq 1
      expect(links.first).to eq @link
    end

    it "check context" do
      expect(@link.context).to eq @root
      expect(@link.context_id).to eq @root.id
      expect(@link.context_type).to eq LearningOutcomeGroup.to_s
    end
  end

  describe "course links" do
    before do
      course
      root = @course.root_outcome_group
      outcome = LearningOutcome.new(short_description: "blank")
      outcome.save!
      @link = root.add_outcome(outcome)
    end
    it "return links with course context" do
      links = OutcomeLink.outcome_links_for_context(@course)
      expect(links.count).to eq 1
      expect(links.first).to eq @link
    end

    it "check context" do
      expect(@link.context).to eq @course
      expect(@link.context_id).to eq @course.id
      expect(@link.context_type).to eq Course.to_s
    end
  end

end
#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative '../../../spec_helper.rb'

describe "Api::V1::ModerationGrader" do
  api = (Class.new do
    include Api::V1::ModerationGrader
  end).new

  describe "#moderation_graders_json" do
    let_once(:assignment) { assignment_model }
    let_once(:user) { user_model }
    let_once(:session) { Object.new }
    let_once(:grader_1) { user_model(name: "Adam Jones") }
    let_once(:grader_2) { user_model(name: "Betty Ford") }

    let(:json) { api.moderation_graders_json(assignment, user, session) }

    before :once do
      assignment.moderation_graders.create!(anonymous_id: "abcde", user: grader_1)
      assignment.moderation_graders.create!(anonymous_id: "fghij", user: grader_2)
    end

    context "when the user can view other grader identities" do
      before :each do
        allow(assignment).to receive(:can_view_other_grader_identities?).with(user).and_return(true)
      end

      it "returns all moderation graders for the assignment" do
        expect(json.length).to be(2)
      end

      it "includes user_id on graders" do
        expect(json.map {|grader| grader['user_id']}).to match_array([grader_1.id, grader_2.id])
      end

      it "includes ids on graders" do
        expect(json.map {|grader| grader['id']}).to match_array(assignment.moderation_graders.map(&:id))
      end

      it "includes grader_name on graders" do
        expect(json.map {|grader| grader['grader_name']}).to match_array([grader_1, grader_2].map(&:short_name))
      end
    end

    context "when the user cannot view other grader identities" do
      before :each do
        allow(assignment).to receive(:can_view_other_grader_identities?).with(user).and_return(false)
      end

      it "returns all moderation graders for the assignment" do
        expect(json.length).to be(2)
      end

      it "includes anonymous_id on graders" do
        expect(json.map {|grader| grader['anonymous_id']}).to match_array(["abcde", "fghij"])
      end

      it "includes ids on graders" do
        expect(json.map {|grader| grader['id']}).to match_array(assignment.moderation_graders.map(&:id))
      end

      it "excludes grader_name from graders" do
        expect(json).to all(not_have_key('grader_name'))
      end
    end
  end
end

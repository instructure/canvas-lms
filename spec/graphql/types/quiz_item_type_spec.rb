# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"
require_relative "../../outcome_alignments_spec_helper"

describe Types::QuizItemType do
  before :once do
    account_admin_user
    outcome_model
    @course.account.enable_feature!(:improved_outcomes_management)
    @course.enable_feature!(:outcome_alignment_summary_with_new_quizzes)
    @new_quiz = @course.assignments.create!(title: "new quiz - aligned in OS", submission_types: "external_tool")
  end

  let(:graphql_context) { { current_user: @admin } }
  let(:outcome_type) { GraphQLTypeTester.new(@outcome, graphql_context) }

  def resolve_field(field_name)
    outcome_type.resolve("alignments(contextType: \"Course\", contextId: #{@course.id}) { #{field_name} }").first
  end

  it "works" do
    allow_any_instance_of(OutcomesServiceAlignmentsHelper)
      .to receive(:get_os_aligned_outcomes)
      .and_return(OutcomeAlignmentsSpecHelper.mock_os_aligned_outcomes([@outcome], @new_quiz.id, with_items: true))
    expect(resolve_field("quizItems { _id, title}").length).to eq 2
    expect(resolve_field("quizItems {_id}")).to match_array(["101", "102"])
    expect(resolve_field("quizItems {title}")).to match_array(["Question Number 101", "Question Number 102"])
  end
end

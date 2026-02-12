# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "../../../spec_helper"

describe "Api::V1::Rubric" do
  include Api::V1::Rubric

  let(:course) { course_model }
  let(:teacher) { user_factory(active_all: true) }
  let(:session) { {} }
  let(:outcome_group) { course.root_outcome_group }

  # Stub routing helpers needed by outcome_group_json
  def polymorphic_path(*_args)
    "/test"
  end

  before do
    course.enroll_teacher(teacher).accept
    @context = course
    @current_user = teacher
    allow(self).to receive(:js_env)
    allow(self).to receive(:session).and_return(session)
  end

  describe "#enhanced_rubrics_context_js_env" do
    let(:assignment) { assignment_model(course:) }

    before do
      allow(Rubric).to receive(:enhanced_rubrics_assignments_enabled?).with(course).and_return(true)
      allow(course.root_account).to receive(:feature_enabled?).and_call_original
      allow(course.root_account).to receive(:feature_enabled?).with(:account_level_mastery_scales).and_return(false)
      allow(Rubric).to receive(:ai_rubrics_enabled?).with(course).and_return(false)
      allow(Rubric).to receive(:rubric_self_assessment_enabled?).with(course).and_return(true)
    end

    context "when enhanced rubrics is not enabled" do
      it "returns early without setting js_env" do
        allow(Rubric).to receive(:enhanced_rubrics_assignments_enabled?).with(course).and_return(false)

        enhanced_rubrics_context_js_env(assignment)

        expect(self).not_to have_received(:js_env)
      end
    end

    context "when enhanced rubrics is enabled" do
      context "rubric_self_assessment_ff_enabled" do
        it "sets to true for regular assignments when feature flag is enabled" do
          enhanced_rubrics_context_js_env(assignment)

          expect(self).to have_received(:js_env).with(hash_including(
                                                        rubric_self_assessment_ff_enabled: true
                                                      ))
        end

        it "sets to false when feature flag is disabled" do
          allow(Rubric).to receive(:rubric_self_assessment_enabled?).with(course).and_return(false)

          enhanced_rubrics_context_js_env(assignment)

          expect(self).to have_received(:js_env).with(hash_including(
                                                        rubric_self_assessment_ff_enabled: false
                                                      ))
        end

        it "sets to false for quiz_lti assignments even when feature flag is enabled" do
          allow(assignment).to receive(:quiz_lti?).and_return(true)

          enhanced_rubrics_context_js_env(assignment)

          expect(self).to have_received(:js_env).with(hash_including(
                                                        rubric_self_assessment_ff_enabled: false
                                                      ))
        end

        it "sets to false for quiz assignments even when feature flag is enabled" do
          allow(assignment).to receive(:quiz?).and_return(true)

          enhanced_rubrics_context_js_env(assignment)

          expect(self).to have_received(:js_env).with(hash_including(
                                                        rubric_self_assessment_ff_enabled: false
                                                      ))
        end

        it "sets to false for discussion topic assignments even when feature flag is enabled" do
          allow(assignment).to receive(:discussion_topic?).and_return(true)

          enhanced_rubrics_context_js_env(assignment)

          expect(self).to have_received(:js_env).with(hash_including(
                                                        rubric_self_assessment_ff_enabled: false
                                                      ))
        end

        it "sets to true for non-quiz, non-discussion assignments when feature flag is enabled" do
          allow(assignment).to receive_messages(quiz_lti?: false, quiz?: false, discussion_topic?: false)

          enhanced_rubrics_context_js_env(assignment)

          expect(self).to have_received(:js_env).with(hash_including(
                                                        rubric_self_assessment_ff_enabled: true
                                                      ))
        end
      end

      it "calls js_env with all expected keys" do
        enhanced_rubrics_context_js_env(assignment)

        expect(self).to have_received(:js_env).with(hash_including(
                                                      ACCOUNT_LEVEL_MASTERY_SCALES: anything,
                                                      COURSE_ID: anything,
                                                      ai_rubrics_enabled: anything,
                                                      rubric_self_assessment_ff_enabled: anything,
                                                      ROOT_OUTCOME_GROUP: anything
                                                    ))
      end
    end

    context "when assignment is nil" do
      it "sets rubric_self_assessment_ff_enabled to false" do
        enhanced_rubrics_context_js_env(nil)

        expect(self).to have_received(:js_env).with(hash_including(
                                                      rubric_self_assessment_ff_enabled: false
                                                    ))
      end

      it "can be called without arguments" do
        expect { enhanced_rubrics_context_js_env }.not_to raise_error
      end
    end
  end
end

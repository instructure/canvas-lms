# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../outcome_alignments_spec_helper"

describe Outcomes::LearningOutcomeGroupChildren do
  subject { described_class.new(context) }

  # rubocop:disable RSpec/LetSetup
  let!(:context) { Account.default }
  let!(:global_group) { LearningOutcomeGroup.create(title: "global") }
  let!(:global_group_subgroup) { global_group.child_outcome_groups.build(title: "global subgroup") }
  let!(:global_outcome1) { outcome_model(outcome_group: global_group, title: "G Outcome 1") }
  let!(:global_outcome2) { outcome_model(outcome_group: global_group, title: "G Outcome 2") }
  let!(:g0) { context.root_outcome_group }
  let!(:g1) { outcome_group_model(context:, outcome_group_id: g0, title: "Group 1.1") }
  let!(:g2) { outcome_group_model(context:, outcome_group_id: g0, title: "Group 1.2") }
  let!(:g3) { outcome_group_model(context:, outcome_group_id: g1, title: "Group 2.1") }
  let!(:g4) { outcome_group_model(context:, outcome_group_id: g1, title: "Group 2.2") }
  let!(:g5) { outcome_group_model(context:, outcome_group_id: g2, title: "Group 3") }
  let!(:g6) { outcome_group_model(context:, outcome_group_id: g3, title: "Group 4") }
  let!(:o0) { outcome_model(context:, outcome_group: g0, title: "Outcome 1", short_description: "Outcome 1") }
  let!(:o1) { outcome_model(context:, outcome_group: g1, title: "Outcome 2.1", short_description: "Outcome 2.1") }
  let!(:o2) { outcome_model(context:, outcome_group: g1, title: "Outcome 2.2", short_description: "Outcome 2.2") }
  let!(:o3) { outcome_model(context:, outcome_group: g2, title: "Outcome 3", short_description: "Outcome 3") }
  let!(:o4) { outcome_model(context:, outcome_group: g3, title: "Outcome 4.1", short_description: "Outcome 4.1") }
  let!(:o5) { outcome_model(context:, outcome_group: g3, title: "Outcome 4.2", short_description: "Outcome 4.2") }
  let!(:o6) { outcome_model(context:, outcome_group: g3, title: "Outcome 4.3", short_description: "Outcome 4.3") }
  let!(:o7) { outcome_model(context:, outcome_group: g4, title: "Outcome 5", short_description: "Outcome 5") }
  let!(:o8) { outcome_model(context:, outcome_group: g5, title: "Outcome 6", short_description: "Outcome 6") }
  let!(:o9) { outcome_model(context:, outcome_group: g6, title: "Outcome 7.1", short_description: "Outcome 7.1") }
  let!(:o10) { outcome_model(context:, outcome_group: g6, title: "Outcome 7.2", short_description: "Outcome 7.2") }
  let!(:o11) { outcome_model(context:, outcome_group: g6, title: "Outcome 7.3 mathematic", short_description: "Outcome 7.3 mathematic") }
  let!(:course) { course_model name: "course", account: context, workflow_state: "created" }
  let!(:cg0) { course.root_outcome_group }
  let!(:cg1) { outcome_group_model(context: course, outcome_group_id: cg0, title: "Course Group 1") }
  let!(:cg2) { outcome_group_model(context: course, outcome_group_id: cg1, title: "Course Group 2") }
  let!(:args) { { target_group_id: cg1.id } }
  # rubocop:enable RSpec/LetSetup

  # Outcome Structure for visual reference
  # Global
  # global_group: global
  #   global_outcome1: G Outcome 1
  #   global_outcome2: G Outcome 2
  # Root
  # g0: Root/Content Name
  #   o0: Outcome 1
  #   g1: Group 1.1
  #      o1: Outcome 2.1
  #      o2: Outcome 2.2
  #      g3: Group 2.1
  #         o4: Outcome 4.1
  #         o5: Outcome 4.2
  #         o6: Outcome 4.3
  #         g6: Group 4
  #            o9:  Outcome 7.1
  #            o10: Outcome 7.2
  #            o11: Outcome 7.3
  #      g4: Group 2.2
  #         o7: Outcome 5
  #   g2: Group 1.2
  #      o3: Outcome 3
  #      g5: Group 3
  #         o8: Outcome 6
  # Course
  # cg0: Root Course Group
  #   cg1: Course Group 1
  #      o3: Outcome 3       # imported outcome
  #      cg2: Course Group 2
  #         o8: Outcome 6    # imported outcome

  before do
    Rails.cache.clear
    context.root_account.enable_feature! :improved_outcomes_management
  end

  before do
    cg1.add_outcome o3
    cg2.add_outcome o8
  end

  describe "#total_outcomes" do
    it "returns the total nested outcomes at each group" do
      expect(subject.total_outcomes(g0.id)).to eq 12
      expect(subject.total_outcomes(g1.id)).to eq 9
      expect(subject.total_outcomes(g2.id)).to eq 2
      expect(subject.total_outcomes(g3.id)).to eq 6
      expect(subject.total_outcomes(g4.id)).to eq 1
      expect(subject.total_outcomes(g5.id)).to eq 1
      expect(subject.total_outcomes(g6.id)).to eq 3
    end

    it "counts content tags rather than distinct outcomes" do
      g0.add_outcome(o8)
      expect(subject.total_outcomes(g0.id)).to eq 13
    end

    it "caches the total outcomes if FF is on" do
      enable_cache do
        expect(ContentTag).to receive(:active).and_call_original.once
        expect(subject.total_outcomes(g0.id)).to eq 12
        expect(subject.total_outcomes(g0.id)).to eq 12
        expect(described_class.new(context).total_outcomes(g0.id)).to eq 12
      end
    end

    it "doesnt caches the total outcomes if FF is off" do
      context.root_account.disable_feature! :improved_outcomes_management
      enable_cache do
        expect(ContentTag).to receive(:active).and_call_original.exactly(3).times
        expect(subject.total_outcomes(g0.id)).to eq 12
        expect(subject.total_outcomes(g0.id)).to eq 12
        expect(described_class.new(context).total_outcomes(g0.id)).to eq 12
      end
    end

    it "returns the total with search_query" do
      expect(subject.total_outcomes(g0.id, search_query: "mathematic")).to eq 1
      expect(subject.total_outcomes(g1.id, search_query: "mathematic")).to eq 1
      expect(subject.total_outcomes(g2.id, search_query: "mathematic")).to eq 0
      expect(subject.total_outcomes(g3.id, search_query: "mathematic")).to eq 1
      expect(subject.total_outcomes(g4.id, search_query: "mathematic")).to eq 0
      expect(subject.total_outcomes(g5.id, search_query: "mathematic")).to eq 0
      expect(subject.total_outcomes(g6.id, search_query: "mathematic")).to eq 1
    end

    context "when outcome is deleted" do
      before { o4.destroy }

      it "returns the total outcomes for a learning outcome group without the deleted outcomes" do
        expect(subject.total_outcomes(g0.id)).to eq 11
        expect(subject.total_outcomes(g1.id)).to eq 8
        expect(subject.total_outcomes(g2.id)).to eq 2
        expect(subject.total_outcomes(g3.id)).to eq 5
        expect(subject.total_outcomes(g4.id)).to eq 1
        expect(subject.total_outcomes(g5.id)).to eq 1
        expect(subject.total_outcomes(g6.id)).to eq 3
      end
    end

    context "when outcome is marked as deleted, but content tag is still active" do
      before do
        o4.workflow_state = "deleted"
        o4.save!
        o8.workflow_state = "deleted"
        o8.save!
      end

      it "returns the total outcomes for a learning outcome group without the deleted outcomes" do
        expect(subject.total_outcomes(g0.id)).to eq 10
        expect(subject.total_outcomes(g1.id)).to eq 8
        expect(subject.total_outcomes(g2.id)).to eq 1
        expect(subject.total_outcomes(g3.id)).to eq 5
        expect(subject.total_outcomes(g4.id)).to eq 1
        expect(subject.total_outcomes(g5.id)).to eq 0
        expect(subject.total_outcomes(g6.id)).to eq 3
      end
    end

    context "when context is nil" do
      subject { described_class.new }

      it "returns global outcomes" do
        expect(subject.total_outcomes(global_group.id)).to eq 2
      end
    end

    context "when filter arg is used" do
      subject { described_class.new(course) }

      before do
        course.account.enable_feature!(:improved_outcomes_management)
        cg2.add_outcome o7
      end

      context "when outcomes are aligned in course context" do
        before do
          o3.align(assignment_model, course)
        end

        it "returns the total outcomes based on filter argument" do
          expect(subject.total_outcomes(cg0.id, { filter: "WITH_ALIGNMENTS" })).to eq 1
          expect(subject.total_outcomes(cg0.id, { filter: "NO_ALIGNMENTS" })).to eq 2
        end

        it "returns the total outcomes if filter arg isn't passed in" do
          expect(subject.total_outcomes(cg0.id, {})).to eq 3
        end

        it "returns the total outcomes without filtering if the FF is disabled" do
          course.account.disable_feature!(:improved_outcomes_management)
          expect(subject.total_outcomes(cg0.id, { filter: "WITH_ALIGNMENTS" })).to eq 3
          expect(subject.total_outcomes(cg0.id, { filter: "NO_ALIGNMENTS" })).to eq 3
        end

        context "when outcome is aligned to New Quizzes" do
          before do
            @new_quiz = course.assignments.create!(title: "new quiz - aligned in OS", submission_types: "external_tool")
            allow_any_instance_of(OutcomesServiceAlignmentsHelper)
              .to receive(:get_os_aligned_outcomes)
              .and_return(OutcomeAlignmentsSpecHelper.mock_os_aligned_outcomes([o8], @new_quiz.id))
          end

          context "when Outcome Alignment Summary with NQ FF is enabled" do
            before do
              course.enable_feature!(:outcome_alignment_summary_with_new_quizzes)
            end

            it "returns the total outcomes aligned in Canvas and Outcomes-Service based on filter argument" do
              expect(subject.total_outcomes(cg0.id, { filter: "WITH_ALIGNMENTS" })).to eq 2
              expect(subject.total_outcomes(cg0.id, { filter: "NO_ALIGNMENTS" })).to eq 1
            end

            context "when new quiz aligned to outcome is deleted in Canvas but not in Outcomes-Service" do
              it "returns the total outcomes aligned in Canvas and Outcomes-Service and filters out alignments to deleted quizzes" do
                @new_quiz.destroy!
                expect(subject.total_outcomes(cg0.id, { filter: "WITH_ALIGNMENTS" })).to eq 1
                expect(subject.total_outcomes(cg0.id, { filter: "NO_ALIGNMENTS" })).to eq 2
              end
            end
          end

          context "when Outcome Alignment Summary with NQ FF is disabled" do
            before do
              course.disable_feature!(:outcome_alignment_summary_with_new_quizzes)
            end

            it "returns the total outcomes only aligned in Canvas based on filter argument" do
              expect(subject.total_outcomes(cg0.id, { filter: "WITH_ALIGNMENTS" })).to eq 1
              expect(subject.total_outcomes(cg0.id, { filter: "NO_ALIGNMENTS" })).to eq 2
            end
          end
        end
      end

      context "when outcomes are aligned in account context and imported in a course" do
        before do
          o3.align(assignment_model, context)
        end

        it "returns the correct number of total outcomes based on filter argument" do
          expect(subject.total_outcomes(cg0.id, { filter: "WITH_ALIGNMENTS" })).to eq 0
          expect(subject.total_outcomes(cg0.id, { filter: "NO_ALIGNMENTS" })).to eq 3
        end
      end
    end
  end

  describe "#not_imported_outcomes" do
    it "returns the number of not imported outcomes in each group" do
      expect(subject.not_imported_outcomes(g0.id, args)).to eq 10
      expect(subject.not_imported_outcomes(g1.id, args)).to eq 9
      expect(subject.not_imported_outcomes(g2.id, args)).to eq 0
      expect(subject.not_imported_outcomes(g3.id, args)).to eq 6
      expect(subject.not_imported_outcomes(g4.id, args)).to eq 1
      expect(subject.not_imported_outcomes(g5.id, args)).to eq 0
      expect(subject.not_imported_outcomes(g6.id, args)).to eq 3
    end

    it "returns nil if no target_group_id provided" do
      expect(subject.not_imported_outcomes(g2.id)).to be_nil
    end
  end

  describe "#suboutcomes_by_group_id" do
    it "returns the outcomes ordered by parent group title then outcome short_description" do
      g_outcomes = subject.suboutcomes_by_group_id(global_group.id)
                          .map { |o| o.learning_outcome_content.short_description }
      expect(g_outcomes).to match_array(["G Outcome 1", "G Outcome 2"])
      r_outcomes = subject.suboutcomes_by_group_id(g0.id)
                          .map { |o| o.learning_outcome_content.short_description }
      expect(r_outcomes).to match_array(
        [
          "Outcome 1",
          "Outcome 2.1",
          "Outcome 2.2",
          "Outcome 3",
          "Outcome 4.1",
          "Outcome 4.2",
          "Outcome 4.3",
          "Outcome 5",
          "Outcome 6",
          "Outcome 7.1",
          "Outcome 7.2",
          "Outcome 7.3 mathematic"
        ]
      )
    end

    it "returns outcomes even if FF is off" do
      context.root_account.disable_feature! :improved_outcomes_management
      outcomes = subject.suboutcomes_by_group_id(g1.id)
                        .map { |o| o.learning_outcome_content.short_description }
      expect(outcomes).to match_array(
        [
          "Outcome 5",
          "Outcome 2.1",
          "Outcome 2.2",
          "Outcome 4.3",
          "Outcome 4.1",
          "Outcome 4.2",
          "Outcome 7.1",
          "Outcome 7.2",
          "Outcome 7.3 mathematic"
        ]
      )
    end

    context "when g2 title is updated with a letter that will proceed others" do
      before { g2.update!(title: "A Group 3") }

      it "returns the g2s outcome (o3) first" do
        outcomes = subject.suboutcomes_by_group_id(g0.id)
                          .map { |o| o.learning_outcome_content.short_description }
        expect(outcomes).to match_array(
          [
            "Outcome 3",
            "Outcome 1",
            "Outcome 2.1",
            "Outcome 2.2",
            "Outcome 4.1",
            "Outcome 4.2",
            "Outcome 4.3",
            "Outcome 5",
            "Outcome 6",
            "Outcome 7.1",
            "Outcome 7.2",
            "Outcome 7.3 mathematic"
          ]
        )
      end
    end

    context "when o5 short_description is updated with a letter that will proceed others" do
      # NOTE: when you update the short_description of a LearningOutcome it does NOT update the
      # content tag title.
      before { o5.update!(short_description: "A Outcome 4.2") }

      it "o5 should be returned before o4 but not o2 and o3" do
        outcomes = subject.suboutcomes_by_group_id(g1.id)
                          .map { |o| o.learning_outcome_content.short_description }
        expect(outcomes).to match_array(
          [
            "Outcome 2.1",
            "Outcome 2.2",
            "A Outcome 4.2",
            "Outcome 4.1",
            "Outcome 4.3",
            "Outcome 5",
            "Outcome 7.1",
            "Outcome 7.2",
            "Outcome 7.3 mathematic"
          ]
        )
      end
    end

    context "when g4 title and o6 short_description is updated with a letter that will proceed others" do
      before do
        g4.update!(title: "A Group 2.2")
        o6.update!(short_description: "A Outcome 4.3")
      end

      it "returns the g4s outcomes first and o6 should be first before other Outcomes 4.x" do
        outcomes = subject.suboutcomes_by_group_id(g1.id)
                          .map { |o| o.learning_outcome_content.short_description }
        expect(outcomes).to match_array(
          [
            "Outcome 5",
            "Outcome 2.1",
            "Outcome 2.2",
            "A Outcome 4.3",
            "Outcome 4.1",
            "Outcome 4.2",
            "Outcome 7.1",
            "Outcome 7.2",
            "Outcome 7.3 mathematic"
          ]
        )
      end
    end

    context "when context is nil" do
      subject { described_class.new }

      it "returns global outcomes" do
        outcomes = subject.suboutcomes_by_group_id(global_group.id)
                          .map { |o| o.learning_outcome_content.short_description }
        expect(outcomes).to match_array(["G Outcome 1", "G Outcome 2"])
      end
    end

    context "search" do
      before do
        outcome_model(
          context:,
          outcome_group: g1,
          title: "LA.1.1.1.1",
          description: "Talk about personal experiences and familiar events."
        )
        outcome_model(
          context:,
          outcome_group: g1,
          title: "LA.1.1.1",
          description: "continue to apply phonic knowledge and skills as the route to decode words until " \
                       "automatic decoding has become embedded and reading is fluent"
        )
        outcome_model(
          context:,
          outcome_group: g1,
          title: "LA.2.2.1.2",
          description: "Explain anticipated meaning, recognize relationships, and draw conclusions; self-correct " \
                       "understanding using a variety of strategies [including rereading for story sense]."
        )
        outcome_model(
          context:,
          outcome_group: g1,
          title: "FO.3",
          description: "apply their growing knowledge of root words, prefixes and suffixes (etymology and morphology) " \
                       "as listed in English Appendix 1, both to read aloud and to understand the meaning of new wor" \
                       "ds they meet"
        )
        outcome_model(
          context:,
          outcome_group: g1,
          title: "HT.ML.1.1",
          description: "<p>Pellentesque&nbsp;habitant morbi tristique senectus et netus et malesuada fames ac turpis e" \
                       "gestas.</p>"
        )
        outcome_model(
          context:,
          outcome_group: g1,
          title: "HT.ML.1.2",
          description: "<p>This is <b>awesome</b>.</p>"
        )
      end

      it "filters title with non-alphanumerical chars" do
        outcomes = subject.suboutcomes_by_group_id(g1.id, { search_query: "LA.1" })
                          .map { |o| o.learning_outcome_content.short_description }
        expect(outcomes).to eql([
                                  "LA.1.1.1", "LA.1.1.1.1"
                                ])
      end

      it "filters description with text content" do
        outcomes = subject.suboutcomes_by_group_id(g1.id, { search_query: "knowledge" })
                          .map { |o| o.learning_outcome_content.short_description }
        expect(outcomes).to eql([
                                  "FO.3", "LA.1.1.1"
                                ])
      end

      it "filters description with html content" do
        outcomes = subject.suboutcomes_by_group_id(g1.id, { search_query: "Pellentesque" })
                          .map { |o| o.learning_outcome_content.short_description }
        expect(outcomes).to eql([
                                  "HT.ML.1.1"
                                ])
      end

      it "filters more than 1 word" do
        outcomes = subject.suboutcomes_by_group_id(g1.id, { search_query: "LA.1.1 Pellentesque" })
                          .map { |o| o.learning_outcome_content.short_description }
        expect(outcomes).to eql([
                                  "HT.ML.1.1",
                                  "LA.1.1.1",
                                  "LA.1.1.1.1"
                                ])
      end

      it "filters when words aren't all completed" do
        outcomes = subject.suboutcomes_by_group_id(g1.id, { search_query: "recog awe" })
                          .map { |o| o.learning_outcome_content.short_description }
        expect(outcomes).to eql([
                                  "LA.2.2.1.2",
                                  "HT.ML.1.2"
                                ])
      end

      context "when lang is portuguese" do
        it "filters outcomes removing portuguese stop words" do
          account = context.root_account
          account.default_locale = "pt-BR"
          account.save!

          outcome_model(
            context:,
            outcome_group: g1,
            title: "will bring",
            description: "<p>Um texto <b>portugues</b>.</p>"
          )
          outcome_model(
            context:,
            outcome_group: g1,
            title: "won't bring",
            description: "<p>Um animal bonito.</p>"
          )

          outcomes = subject.suboutcomes_by_group_id(
            g1.id, {
              search_query: "Um portugues"
            }
          ).map { |o| o.learning_outcome_content.short_description }

          expect(outcomes).to eql([
                                    "will bring"
                                  ])
        end

        context "when context is nil" do
          subject { described_class.new }

          it "filters outcomes removing portuguese stop words" do
            account = Account.default
            account.default_locale = "pt-BR"
            account.save!

            outcome_model(
              global: true,
              title: "will bring",
              description: "<p>Um texto <b>portugues</b>.</p>"
            )
            outcome_model(
              global: true,
              title: "won't bring",
              description: "<p>Um animal bonito.</p>"
            )

            outcomes = subject.suboutcomes_by_group_id(
              LearningOutcomeGroup.find_or_create_root(nil, true).id, {
                search_query: "Um portugues"
              }
            ).map { |o| o.learning_outcome_content.short_description }

            expect(outcomes).to eql([
                                      "will bring"
                                    ])
          end
        end
      end

      context "when lang is not supported" do
        before do
          account = context.root_account
          account.default_locale = "pl" # polski
          account.save!
        end

        it "filters outcomes normally" do
          outcome_model(
            context:,
            outcome_group: g1,
            title: "will bring",
            description: "<p>Um texto <b>portugues</b>.</p>"
          )
          outcome_model(
            context:,
            outcome_group: g1,
            title: "will bring too",
            description: "<p>Um animal bonito.</p>"
          )

          outcomes = subject.suboutcomes_by_group_id(
            g1.id, { search_query: "Um portugues" }
          ).map { |o| o.learning_outcome_content.short_description }

          expect(outcomes).to eql([
                                    "will bring",
                                    "will bring too"
                                  ])
        end
      end
    end

    context "filter" do
      subject { described_class.new(course) }

      before do
        course.account.enable_feature!(:improved_outcomes_management)
        o3.align(assignment_model, course)
        cg1.add_outcome o4
      end

      it "filters outcomes without alignments in Canvas" do
        outcomes = subject.suboutcomes_by_group_id(cg1.id, { filter: "NO_ALIGNMENTS" })
                          .map { |o| o.learning_outcome_content.id }
        expect(outcomes).to eql([o4.id, o8.id])
      end

      it "filters outcomes with alignments in Canvas" do
        outcomes = subject.suboutcomes_by_group_id(cg1.id, { filter: "WITH_ALIGNMENTS" })
                          .map { |o| o.learning_outcome_content.id }
        expect(outcomes).to eql([o3.id])
      end

      it "filters outcomes without alignments in Canvas and with search" do
        outcomes = subject.suboutcomes_by_group_id(cg1.id, { search_query: "4.1", filter: "NO_ALIGNMENTS" })
                          .map { |o| o.learning_outcome_content.id }
        expect(outcomes).to eql([o4.id])
      end

      it "doesn't filter when the FF is disabled" do
        course.account.disable_feature!(:improved_outcomes_management)
        outcomes = subject.suboutcomes_by_group_id(cg1.id, { filter: "WITH_ALIGNMENTS" })
                          .map { |o| o.learning_outcome_content.id }
        expect(outcomes).to eql([o3.id, o4.id, o8.id])
      end

      it "doesn't filter if an invalid arg is passed" do
        outcomes = subject.suboutcomes_by_group_id(cg1.id, { filter: "INVALID" })
                          .map { |o| o.learning_outcome_content.id }
        expect(outcomes).to eql([o3.id, o4.id, o8.id])
      end

      context "when Outcome Alignment Summary with NQ FF is enabled" do
        before do
          cg1.add_outcome o5
          course.enable_feature!(:outcome_alignment_summary_with_new_quizzes)
          @new_quiz = course.assignments.create!(title: "new quiz - aligned in OS", submission_types: "external_tool")
          allow_any_instance_of(OutcomesServiceAlignmentsHelper)
            .to receive(:get_os_aligned_outcomes)
            .and_return(OutcomeAlignmentsSpecHelper.mock_os_aligned_outcomes([o8], @new_quiz.id))
        end

        it "filters outcomes without alignments in Canvas or Outcomes-Service" do
          outcomes = subject.suboutcomes_by_group_id(cg1.id, { filter: "NO_ALIGNMENTS" })
                            .map { |o| o.learning_outcome_content.id }
          expect(outcomes).to eql([o4.id, o5.id])
        end

        it "filters outcomes with alignments in Canvas or Outcomes-Service" do
          outcomes = subject.suboutcomes_by_group_id(cg1.id, { filter: "WITH_ALIGNMENTS" })
                            .map { |o| o.learning_outcome_content.id }
          expect(outcomes).to eql([o3.id, o8.id])
        end

        context "when new quiz aligned to outcome is deleted in Canvas but not in Outcomes-Service" do
          it "filters outcomes with alignments in Canvas or Outcomes-Service and filters out alignments to deleted quizzes" do
            @new_quiz.destroy!
            outcomes = subject.suboutcomes_by_group_id(cg1.id, { filter: "WITH_ALIGNMENTS" })
                              .map { |o| o.learning_outcome_content.id }
            expect(outcomes).to eql([o3.id])
          end
        end

        it "filters outcomes without alignments in Canvas or Outcomes-Service and with search" do
          outcomes = subject.suboutcomes_by_group_id(cg1.id, { search_query: "4.1", filter: "NO_ALIGNMENTS" })
                            .map { |o| o.learning_outcome_content.id }
          expect(outcomes).to eql([o4.id])
        end
      end
    end
  end

  context "learning outcome groups and learning outcomes events" do
    context "when a group is destroyed" do
      it "clears the cache" do
        enable_cache do
          expect(subject.total_outcomes(g0.id)).to eq 12
          g6.destroy
          expect(described_class.new(context).total_outcomes(g0.id)).to eq 9
        end
      end
    end

    context "when a group is added" do
      it "clears the cache" do
        enable_cache do
          expect(subject.total_outcomes(g0.id)).to eq 12
          new_group = outcome_group_model(context:, outcome_group_id: g0)
          outcome_model(context:, outcome_group: new_group)
          expect(described_class.new(context).total_outcomes(g0.id)).to eq 13
        end
      end

      context "when a global group is added" do
        it "clears the cache for total_outcomes" do
          enable_cache do
            expect(subject.total_outcomes(g0.id)).to eq 12
            g0.add_outcome_group(global_group)
            expect(described_class.new(context).total_outcomes(g0.id)).to eq 14
          end
        end
      end
    end

    context "when a group is adopted" do
      it "clears the cache" do
        enable_cache do
          expect(subject.total_outcomes(g0.id)).to eq 12
          outcome_group = outcome_group_model(context:)
          outcome_model(context:, outcome_group:)
          g1.adopt_outcome_group(outcome_group)
          expect(described_class.new(context).total_outcomes(g0.id)).to eq 13
        end
      end
    end

    context "when a group is edited" do
      it "does not clear the cache" do
        enable_cache do
          expect_any_instance_of(Outcomes::LearningOutcomeGroupChildren).not_to receive(:clear_descendants_cache)
          expect(subject.total_outcomes(g0.id)).to eq 12
          g1.update(title: "title edited")
          expect(described_class.new(context).total_outcomes(g0.id)).to eq 12
        end
      end
    end

    context "when an outcome is added" do
      it "clears the cache" do
        enable_cache do
          expect(subject.total_outcomes(g1.id)).to eq 9
          outcome = LearningOutcome.create!(title: "test outcome", context:)
          g1.add_outcome(outcome)
          expect(described_class.new(context).total_outcomes(g1.id)).to eq 10
        end
      end
    end

    context "when an outcome is destroyed" do
      it "clears the cache" do
        enable_cache do
          outcome = LearningOutcome.create!(title: "test outcome", context:)
          g1.add_outcome(outcome)
          expect(described_class.new(context).total_outcomes(g1.id)).to eq 10
          outcome.destroy
          expect(described_class.new(context).total_outcomes(g1.id)).to eq 9
        end
      end

      context "when the outcome belongs to a global group" do
        it "clears the cache" do
          enable_cache do
            expect(described_class.new.total_outcomes(global_group.id)).to eq 2
            global_outcome1.destroy
            expect(described_class.new.total_outcomes(global_group.id)).to eq 1
          end
        end
      end

      context "when the outcome belongs to different contexts" do
        it "clears the cache on each context" do
          enable_cache do
            g1.add_outcome(global_outcome1)
            expect(described_class.new(context).total_outcomes(g1.id)).to eq 10
            expect(described_class.new.total_outcomes(global_group.id)).to eq 2
            global_outcome1.destroy
            expect(described_class.new(context).total_outcomes(g1.id)).to eq 9
            expect(described_class.new.total_outcomes(global_group.id)).to eq 1
          end
        end
      end
    end

    context "when a child_outcome_link is destroyed" do
      it "clears the cache" do
        enable_cache do
          outcome = LearningOutcome.create!(title: "test outcome", context:)
          child_outcome_link = g1.add_outcome(outcome)
          expect(described_class.new(context).total_outcomes(g1.id)).to eq 10
          child_outcome_link.destroy
          expect(described_class.new(context).total_outcomes(g1.id)).to eq 9
        end
      end

      context "when the child_outcome_link belongs to global learning outcome group" do
        it "clears the cache" do
          enable_cache do
            outcome = LearningOutcome.create!(title: "test outcome")
            child_outcome_link = global_group.add_outcome(outcome)
            expect(described_class.new.total_outcomes(global_group.id)).to eq 3
            child_outcome_link.destroy
            expect(described_class.new.total_outcomes(global_group.id)).to eq 2
          end
        end
      end
    end
  end
end

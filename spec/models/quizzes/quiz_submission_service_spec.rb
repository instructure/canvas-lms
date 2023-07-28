# frozen_string_literal: true

# Copyright (C) 2013 - present Instructure, Inc.
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

shared_examples_for "Takeable Quiz Services" do
  it "denies access to locked quizzes" do
    allow(quiz).to receive(:locked_for?).and_return(true)
    allow(quiz).to receive(:grants_right?)
      .with(anything, anything, :manage).and_return(false)

    expect { service_action.call }.to raise_error(RequestError, /is locked/i)
  end

  it "validates the access code" do
    quiz.access_code = "adooken"

    expect { service_action.call }.to raise_error(RequestError, /access code/i)
  end

  it "accepts a valid access code" do
    participant.access_code = quiz.access_code = "adooken"

    expect { service_action.call }.to_not raise_error
  end

  it "validates the IP address of the participant" do
    quiz.ip_filter = "10.0.0.1/24"
    participant.ip_address = "192.168.0.1"

    expect { service_action.call }.to raise_error(RequestError, /ip address/i)
  end

  it "accepts a covered IP" do
    participant.ip_address = quiz.ip_filter = "10.0.0.1"

    expect { service_action.call }.to_not raise_error
  end
end

describe Quizzes::QuizSubmissionService do
  subject { Quizzes::QuizSubmissionService.new participant }

  let :quiz do
    quiz = Quizzes::Quiz.new
    quiz.workflow_state = "available"
    quiz
  end

  let :participant do
    Quizzes::QuizParticipant.new(User.new, "some temporary user code")
  end

  describe "#create" do
    before do
      # consume all calls to actual QS generation, no need to test this
      allow(quiz).to receive(:generate_submission)
    end

    context "as an authentic user" do
      before do
        allow(quiz).to receive(:grants_right?).and_return true
      end

      let :service_action do
        ->(*_) { subject.create quiz }
      end

      include_examples "Takeable Quiz Services"

      it "creates a QS" do
        expect { subject.create quiz }.to_not raise_error
      end

      context "retrying a quiz" do
        let :retriable_qs do
          qs = Quizzes::QuizSubmission.new
          allow(qs).to receive(:retriable?).and_return true
          qs
        end

        let :unretriable_qs do
          qs = Quizzes::QuizSubmission.new
          allow(qs).to receive(:retriable?).and_return false
          qs
        end

        it "regenerates when possible" do
          expect(Quizzes::QuizSubmission).to receive(:for_participant).with(participant) { double(first: retriable_qs) }

          expect do
            subject.create quiz
          end.to_not raise_error
        end

        it "does not regenerate if the QS is not retriable" do
          expect(Quizzes::QuizSubmission).to receive(:for_participant).with(participant) { double(first: unretriable_qs) }

          expect do
            subject.create quiz
          end.to raise_error(RequestError, /already exists/i)
        end

        it "works with multiple sections" do
          active_course_section   = CourseSection.new(start_at: 3.days.ago, end_at: 3.days.from_now, restrict_enrollments_to_section_dates: true)
          inactive_course_section = CourseSection.new(start_at: 6.days.ago, end_at: 3.days.ago, restrict_enrollments_to_section_dates: true)

          quiz.context = Account.default.courses.new

          quiz.context.save!
          participant.user = user_factory
          quiz.context.enroll_user(participant.user)

          allow(quiz).to receive(:grants_right?).and_return(true)
          allow(quiz).to receive(:grants_right?).with(anything, anything, :manage).and_return(false)

          allow(participant.user).to receive_messages(sections_for_course: [inactive_course_section, active_course_section], new_record?: false)

          expect do
            subject.create quiz
          end.not_to raise_error
        end
      end
    end

    context "as an anonymous participant" do
      before do
        participant.user = nil
        quiz.context = Account.default.courses.new.tap { |c| c.root_account = Account.default }
      end

      it "allows taking a quiz in a public course" do
        allow(quiz).to receive(:grants_right?).and_return true
        quiz.context.is_public = true

        expect { subject.create quiz }.to_not raise_error
      end

      it "denies access otherwise" do
        expect do
          subject.create quiz
        end.to raise_error(RequestError, /not allowed to participate/i)
      end
    end
  end

  describe "#create_preview" do
    it "utilizes the user code instead of the user" do
      expect(quiz).to receive(:generate_submission).with(participant.user_code, true)
      allow(quiz).to receive(:grants_right?).and_return true

      subject.create_preview quiz, nil
    end
  end

  describe "#complete" do
    let :qs do
      qs = Quizzes::QuizSubmission.new
      qs.attempt = 1
      qs.quiz = quiz
      qs
    end

    context "as the participant" do
      before do
        allow(quiz).to receive(:grants_right?).and_return true
      end

      let :service_action do
        ->(*_) { subject.complete qs, qs.attempt }
      end

      include_examples "Takeable Quiz Services"

      it "completes the QS" do
        expect do
          subject.complete qs, qs.attempt
        end.to_not raise_error
      end

      it "rejects an invalid attempt" do
        expect do
          subject.complete qs, "hi"
        end.to raise_error(RequestError, /invalid attempt/)
      end

      it "rejects completing an old attempt" do
        expect do
          subject.complete qs, 0
        end.to raise_error(RequestError, /attempt 0 can not be modified/)
      end

      it "rejects an invalid validation_token" do
        qs.validation_token = "yep"
        participant.validation_token = "nope"

        expect do
          subject.complete qs, qs.attempt
        end.to raise_error(RequestError, /invalid token/)
      end

      it "requires the QS to be untaken" do
        qs.workflow_state = "complete"

        expect do
          subject.complete qs, qs.attempt
        end.to raise_error(RequestError, /already complete/)
      end
    end
  end

  describe "#update_question" do
    let :qs do
      qs = Quizzes::QuizSubmission.new
      qs.attempt = 1
      qs.quiz = quiz
      allow(qs).to receive(:completed?).and_return false
      allow(qs).to receive(:backup_submission_data)
      qs
    end

    context "as the participant" do
      before do
        allow(quiz).to receive(:grants_right?).and_return true
      end

      let :service_action do
        ->(*_) { subject.update_question({}, qs, qs.attempt) }
      end

      include_examples "Takeable Quiz Services"

      it "updates a question" do
        expect do
          subject.update_question({ question_5_marked: true }, qs, qs.attempt)
        end.to_not raise_error
      end

      it "rejects when the QS is complete" do
        allow(qs).to receive(:completed?).and_return true

        expect do
          subject.update_question({ question_5_marked: true }, qs, qs.attempt)
        end.to raise_error(RequestError, /already complete/)
      end
    end

    context "as someone else" do
      it "denies access" do
        participant.user = nil
        quiz.context = Account.default.courses.new.tap { |c| c.root_account = Account.default }

        expect do
          subject.complete qs, qs.attempt
        end.to raise_error(RequestError, /not allowed to complete/i)
      end
    end
  end

  describe "#update_scores" do
    let :qs do
      qs = Quizzes::QuizSubmission.new
      qs.attempt = 1
      qs.quiz = quiz
      qs
    end

    context "as a teacher" do
      before do
        allow(qs).to receive(:grants_right?).with(participant.user, :update_scores).and_return true
      end

      def expect_version_object
        expect(qs.versions).to receive(:get).with(qs.attempt).at_most(:once) do
          o = Object.new
          allow(o).to receive(:model).and_return(qs)
          o
        end
      end

      it "updates the scores" do
        expect_version_object
        qs.workflow_state = "complete"
        expect(qs).to receive(:update_scores)

        expect do
          subject.update_scores qs, qs.attempt, {
            fudge_points: 2
          }
        end.to_not raise_error
      end

      it 'generates the correct "legacy" format' do
        expect_version_object
        qs.workflow_state = "complete"
        expect(qs).to receive(:update_scores).with({
          "submission_version_number" => qs.attempt,
          "fudge_points" => 2.0,
          "question_score_5" => 3.2,
          "question_comment_5" => "Roar.",
          "question_score_2" => 0
        }.with_indifferent_access)

        subject.update_scores qs, qs.attempt, {
          fudge_points: 2,
          questions: {
            "2" => {
              score: 0
            },
            "3" => {},
            "5" => {
              score: 3.2,
              comment: "Roar."
            }
          }
        }
      end

      it "requires a valid attempt" do
        allow(qs.versions).to receive(:get).and_return nil

        expect do
          subject.update_scores qs, qs.attempt, {}
        end.to raise_error(RequestError, /invalid attempt/i)
      end

      it "requires a complete attempt" do
        expect_version_object
        expect do
          subject.update_scores qs, qs.attempt, {}
        end.to raise_error(RequestError, /attempt must be complete/i)
      end

      it "rejects a bad score" do
        expect_version_object
        qs.workflow_state = "complete"

        expect do
          subject.update_scores qs, qs.attempt, {
            questions: {
              "1" => { score: ["adooken"] }
            }
          }
        end.to raise_error(RequestError, /must be an unsigned decimal/i)
      end

      it "is a no-op if no changes are requested" do
        expect_version_object
        qs.workflow_state = "complete"
        expect(qs).not_to receive(:update_scores)

        subject.update_scores qs, qs.attempt, {}
      end
    end

    context "as someone else" do
      before do
        allow(qs).to receive(:grants_right?).with(participant.user, :update_scores).and_return false
      end

      it "denies access" do
        expect do
          subject.update_scores qs, qs.attempt, {}
        end.to raise_error(RequestError, /not allowed/i)
      end
    end
  end
end

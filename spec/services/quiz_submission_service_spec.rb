# encoding: UTF-8
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

shared_examples_for 'Takeable Quiz Services' do
  it 'should deny access to locked quizzes' do
    quiz.stubs(:locked?).returns true

    expect { service_action.call }.to raise_error(ApiError, /is locked/i)
  end

  it 'should validate the access code' do
    quiz.access_code = 'adooken'

    expect { service_action.call }.to raise_error(ApiError, /access code/i)
  end

  it 'should accept a valid access code' do
    participant.access_code = quiz.access_code = 'adooken'

    expect { service_action.call }.to_not raise_error
  end

  it 'should validate the IP address of the participant' do
    quiz.ip_filter = '10.0.0.1/24'
    participant.ip_address = '192.168.0.1'

    expect { service_action.call }.to raise_error(ApiError, /ip address/i)
  end

  it 'should accept a covered IP' do
    participant.ip_address = quiz.ip_filter = '10.0.0.1'

    expect { service_action.call }.to_not raise_error
  end
end

describe QuizSubmissionService do
  ApiError = Api::V1::ApiError

  subject { QuizSubmissionService.new participant }

  let :quiz do
    quiz = Quiz.new
    quiz.workflow_state = 'available'
    quiz
  end

  let :participant do
    QuizParticipant.new(User.new, 'some temporary user code')
  end

  describe '#create' do
    before :each do
      # consume all calls to actual QS generation, no need to test this
      quiz.stubs(:generate_submission)
    end

    context 'as an authentic user' do
      before :each do
        quiz.stubs(:grants_right?).returns true
      end

      let :service_action do
        lambda { |*_| subject.create quiz }
      end

      it_should_behave_like 'Takeable Quiz Services'

      it 'should create a QS' do
        expect { subject.create quiz }.to_not raise_error
      end

      context 'retrying a quiz' do
        let :retriable_qs do
          qs = QuizSubmission.new
          qs.stubs(:retriable?).returns true
          qs
        end

        let :unretriable_qs do
          qs = QuizSubmission.new
          qs.stubs(:retriable?).returns false
          qs
        end

        it 'should regenerate when possible' do
          participant.stubs(:find_quiz_submission).returns { retriable_qs }

          expect do
            subject.create quiz
          end.to_not raise_error
        end

        it 'should not regenerate if the QS is not retriable' do
          participant.stubs(:find_quiz_submission).returns { unretriable_qs }

          expect do
            subject.create quiz
          end.to raise_error(ApiError, /already exists/i)
        end
      end
    end

    context 'as an anonymous participant' do
      before :each do
        participant.user = nil
        quiz.context = Course.new
      end

      it 'should allow taking a quiz in a public course' do
        quiz.context.is_public = true

        expect { subject.create quiz }.to_not raise_error
      end

      it 'should deny access otherwise' do
        expect do
          subject.create quiz
        end.to raise_error(ApiError, /not allowed to participate/i)
      end
    end
  end

  describe '#create_preview' do
    it 'should utilize the user code instead of the user' do
      quiz.expects(:generate_submission).with(participant.user_code, true)
      quiz.stubs(:grants_right?).returns true

      subject.create_preview quiz, nil
    end
  end

  describe '#complete' do
    let :qs do
      qs = QuizSubmission.new
      qs.attempt = 1
      qs.quiz = quiz
      qs
    end

    context 'as the participant' do
      before :each do
        quiz.stubs(:grants_right?).returns true
      end

      let :service_action do
        lambda { |*_| subject.complete qs, qs.attempt }
      end

      it_should_behave_like 'Takeable Quiz Services'

      it 'should complete the QS' do
        expect do
          subject.complete qs, qs.attempt
        end.to_not raise_error
      end

      it 'should reject an invalid attempt' do
        expect do
          subject.complete qs, 'hi'
        end.to raise_error(ApiError, /invalid attempt/)
      end

      it 'should reject completing an old attempt' do
        expect do
          subject.complete qs, 0
        end.to raise_error(ApiError, /attempt 0 can not be modified/)
      end

      it 'should reject an invalid validation_token' do
        qs.validation_token = 'yep'
        participant.validation_token = 'nope'

        expect do
          subject.complete qs, qs.attempt
        end.to raise_error(ApiError, /invalid token/)
      end

      it 'should require the QS to be untaken' do
        qs.workflow_state = 'complete'

        expect do
          subject.complete qs, qs.attempt
        end.to raise_error(ApiError, /already complete/)
      end

      it 'should require the QS to be untaken' do
        qs.workflow_state = 'complete'

        expect do
          subject.complete qs, qs.attempt
        end.to raise_error(ApiError, /already complete/)
      end
    end

    context 'as someone else' do
      it 'should deny access' do
        quiz.context = Course.new
        participant.user = nil

        expect do
          subject.complete qs, qs.attempt
        end.to raise_error(ApiError, /not allowed to complete/i)
      end
    end
  end
end

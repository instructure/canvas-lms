#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::QuizSubmissionEvent do
  describe '#empty?' do
    context Quizzes::QuizSubmissionEvent::EVT_QUESTION_ANSWERED do
      before do
        subject.event_type = Quizzes::QuizSubmissionEvent::EVT_QUESTION_ANSWERED
      end

      it 'should be true if it has no answer records' do
        expect(subject).to be_empty
      end

      it 'should not be true if it has any answer record' do
        subject.answers = [{}]
        expect(subject).not_to be_empty
      end
    end
  end
end

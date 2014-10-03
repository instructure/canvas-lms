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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::QuizSubmissionAttempt do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  describe "#initialize" do
    it "should assign number" do
      attempt = Quizzes::QuizSubmissionAttempt.new(:number => 1)
      attempt.number.should == 1
    end

    it "should assign versions" do
      versions = [1, 2, 3]
      attempt = Quizzes::QuizSubmissionAttempt.new(:number => 1, :versions => versions)
      attempt.versions.should == versions
    end
  end
end

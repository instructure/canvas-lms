#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizQuestion::RawFields do
  describe "#fetch_any" do
    let(:fields) { Quizzes::QuizQuestion::RawFields.new(answer_comment: "an answer comment", comments: "another answer comment") }
    it "fetches a specified key" do
      fields.fetch_any(:answer_comment).should == "an answer comment"
    end

    it "fetches one of any supplied keys, in order" do
      fields.fetch_any([:answer_comment]).should == "an answer comment"
      fields.fetch_any([:answer_comment, :comments]).should == "an answer comment"
      fields.fetch_any([:comments, :answer_comment]).should == "another answer comment"
    end

    it "defaults if it can't find any of the supplied keys" do
      fields.fetch_any([:foo, :blah], "default value").should == "default value"
    end
  end

  describe "#fetch_with_enforced_length" do

    it "has no problem with short data" do
      fields = Quizzes::QuizQuestion::RawFields.new(answer_comment: "an answer comment")
      fields.fetch_with_enforced_length(:answer_comment).should == "an answer comment"
    end

    it "bombs with data that's too long" do
      long_data = "abcdefghijklmnopqrstuvwxyz"
      16.times do
        long_data = "#{long_data}abcdefghijklmnopqrstuvwxyz#{long_data}"
      end

      fields = Quizzes::QuizQuestion::RawFields.new(answer_comment: long_data)

      expect {
        fields.fetch_with_enforced_length(:answer_comment)
      }.to raise_error(Quizzes::QuizQuestion::RawFields::FieldTooLongError)
    end
  end

end

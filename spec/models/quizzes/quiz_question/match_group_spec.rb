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

describe Quizzes::QuizQuestion::MatchGroup do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  describe '#add' do
    let(:properties) do
      { text: 'Arkansas', match_id: 177 }
    end

    it "adds to matches" do
      subject.add(properties)
      subject.matches.length.should == 1
      subject.matches.first.text.should == properties[:text]
      subject.matches.first.id.should == properties[:match_id]
    end

    it "does not add a duplicate match" do
      subject.add(properties)
      subject.matches.length.should == 1
      subject.add(properties)
      subject.matches.length.should == 1
    end

    context "when providing a match with only text" do
      it "generates a unique id" do
        subject.add(text: "Georgia")
        subject.matches.first.text.should == "Georgia"
        subject.matches.first.id.should_not be_nil
      end
    end

    context "when providing a match with the same text" do
      it "does not add a duplicate match" do
        subject.add(text: "California")
        subject.matches.length.should == 1
        subject.add(text: "California")
        subject.matches.length.should == 1
      end
    end
  end
end



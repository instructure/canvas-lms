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

describe ContentTag do
  
  it "should allow setting a valid content_asset_string" do
    tag = ContentTag.new
    tag.content_asset_string = 'discussion_topic_5'
    tag.content_type.should eql('DiscussionTopic')
    tag.content_id.should eql(5)
  end
  
  it "should not allow setting an invalid content_asset_string" do
    tag = ContentTag.new
    tag.content_asset_string = 'bad_class_41'
    tag.content_type.should eql(nil)
    tag.content_id.should eql(nil)
    
    tag.content_asset_string = 'bad_class'
    tag.content_type.should eql(nil)
    tag.content_id.should eql(nil)
    
    tag.content_asset_string = 'course_55'
    tag.content_type.should eql(nil)
    tag.content_id.should eql(nil)
  end

  it "should return content for a assignment" do
    course
    assignment = course.assignments.create!
    tag = ContentTag.new(:content => assignment, :context => @course)
    tag.assignment.should == assignment
  end

  it "should return associated assignment for a quiz" do
    course
    quiz = course.quizzes.create!
    tag = ContentTag.new(:content => quiz, :context => @course)
    tag.assignment.should == quiz.assignment
  end

  it "should return nil assignment for something else" do
    tag = ContentTag.new
    tag.assignment.should be_nil
  end

  it "should include tags from a course in the for_context named scope" do
    course
    quiz = @course.quizzes.create!
    tag = ContentTag.create!(:content => quiz, :context => @course)
    tags = ContentTag.for_context(@course)
    tags.should_not be_empty
    tags.any?{ |t| t.id == tag.id }.should be_true
  end

  it "should include tags from an account in the for_context named scope" do
    account = Account.default
    outcome = account.learning_outcomes.create!(:description => '<p>This is <b>awesome</b>.</p>')
    tag = ContentTag.create!(:content => outcome, :context => account)
    tags = ContentTag.for_context(account)
    tags.should_not be_empty
    tags.any?{ |t| t.id == tag.id }.should be_true
  end

  it "should include tags from courses under an account in the for_context named scope" do
    course
    quiz = @course.quizzes.create!
    tag = ContentTag.create!(:content => quiz, :context => @course)
    tags = ContentTag.for_context(@course.account)
    tags.should_not be_empty
    tags.any?{ |t| t.id == tag.id }.should be_true
  end
end

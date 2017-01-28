#
# Copyright (C) 2015 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Messages::PeerReviewsHelper do

  describe 'assessment requests' do

    it 'should should return reviewee name' do
      assessment_request_model
      expect(reviewee_name(@assessment_request, @user)).to eq(@assessment_request.asset.user.name)
    end

    it 'should return anonymous when anonymous peer reviews enabled' do
      assessment_request_model
      assignment = @assessment_request.asset.assignment
      assignment.update_attribute(:anonymous_peer_reviews, true)
      @assessment_request.reload
      expect(reviewee_name(@assessment_request, @user2)).to eq(I18n.t(:anonymous_user, 'Anonymous User'))
    end

  end

  describe 'submission comments' do

    context 'anonymous peer reviews disabled' do

      it 'should return author name' do
        submission_model
        comment = @submission.add_comment(:comment => "new comment")
        expect(submission_comment_author(comment, @user)).to eq(comment.author_name)
      end

      it 'should return anonymous' do
        @user2 = user_model
        submission_model
        comment = @submission.add_comment(:comment => "new comment", :user => @user2)
        @submission.assignment.update_attribute(:anonymous_peer_reviews, true)
        comment.reload
        expect(submission_comment_author(comment, @user)).to eq(I18n.t(:anonymous_user, 'Anonymous User'))
      end

    end

    context 'anonymous peer reviews enabled' do

      it 'should return submittor' do
        submission_model
        comment = @submission.add_comment(:comment => "new comment")
        expect(submission_comment_submittor(comment, @user)).to eq(@submission.user.short_name)
      end

      it 'should return anonymous' do
        @user2 = user_model
        submission_model
        comment = @submission.add_comment(:comment => "new comment", :user => @user2)
        @submission.assignment.update_attribute(:anonymous_peer_reviews, true)
        comment.reload
        expect(submission_comment_submittor(comment, @user2)).to eq(I18n.t(:anonymous_user, 'Anonymous User'))
      end

    end
  end

end

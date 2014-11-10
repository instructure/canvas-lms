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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../views_helper')

describe "/quizzes/quizzes/index_legacy" do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  it "should render" do
    course_with_student
    view_context
    assigns[:body_classes] = []
    assigns[:quizzes] = [@course.quizzes.create!]
    assigns[:unpublished_quizzes] = []
    assigns[:assignment_quizzes] = assigns[:quizzes]
    assigns[:open_quizzes] = assigns[:quizzes]
    assigns[:surveys] = assigns[:quizzes]
    assigns[:submissions_hash] = {}
    render "quizzes/quizzes/index_legacy"
    expect(response).not_to be_nil
  end

  it "with draft state enabled should render" do
    Account.default.enable_feature!(:draft_state)

    course_with_student
    view_context
    assigns[:body_classes] = []

    render "quizzes/quizzes/index"
    expect(response).not_to be_nil
  end
end


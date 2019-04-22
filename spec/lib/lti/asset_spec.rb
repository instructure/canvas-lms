#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe Lti::Asset do

  before(:each) do
    course_model
  end


  describe "opaque_identifier_for" do
    it "should create lti_context_id for asset" do
      expect(@course.lti_context_id).to eq nil
      context_id = described_class.opaque_identifier_for(@course)
      @course.reload
      expect(@course.lti_context_id).to eq context_id
    end

    it "should use old_id when present" do
      user = user_model
      context_id = described_class.opaque_identifier_for(user)
      UserPastLtiId.create!(user: user, context: @course, user_lti_id: @teacher.lti_id, user_lti_context_id: 'old_lti_id', user_uuid: 'old')
      expect(described_class.opaque_identifier_for(user, context: @course)).to_not eq context_id
      expect(described_class.opaque_identifier_for(user, context: @course)).to eq 'old_lti_id'
    end

    it "should not use old_id when not present" do
      user = user_model
      context_id = described_class.opaque_identifier_for(user)
      expect(described_class.opaque_identifier_for(user, context: @course)).to eq context_id
    end

    it "should not create new lti_context for asset if exists" do
      @course.lti_context_id = 'dummy_context_id'
      @course.save!
      described_class.opaque_identifier_for(@course)
      @course.reload
      expect(@course.lti_context_id).to eq 'dummy_context_id'
    end
  end

end

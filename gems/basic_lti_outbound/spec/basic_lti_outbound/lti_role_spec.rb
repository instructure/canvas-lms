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

require "spec_helper"

describe BasicLtiOutbound::LTIRole do
  it_behaves_like "it has an attribute setter and getter for", :type
  it_behaves_like "it has an attribute setter and getter for", :state

  it "returns active? IFF the state is :active" do
    expect(subject.active?).to be false
    subject.state = "something irrelevant"
    expect(subject.active?).to be false
    subject.state = :active
    expect(subject.active?).to be true
  end

  describe "constants" do
    it "provides role constants" do
      expect(BasicLtiOutbound::LTIRole::INSTRUCTOR).to eq "Instructor"
      expect(BasicLtiOutbound::LTIRole::LEARNER).to eq "Learner"
      expect(BasicLtiOutbound::LTIRole::ADMIN).to eq "urn:lti:instrole:ims/lis/Administrator"
      expect(BasicLtiOutbound::LTIRole::CONTENT_DEVLOPER).to eq "ContentDeveloper"
      expect(BasicLtiOutbound::LTIRole::OBSERVER).to eq "urn:lti:instrole:ims/lis/Observer"
      expect(BasicLtiOutbound::LTIRole::TEACHING_ASSISTANT).to eq "urn:lti:role:ims/lis/TeachingAssistant"
      expect(BasicLtiOutbound::LTIRole::NONE).to eq "urn:lti:sysrole:ims/lis/None"
    end
  end
end
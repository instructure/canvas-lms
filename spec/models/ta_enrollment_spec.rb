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


#
# Table name: enrollments
#
#  id             :integer         not null, primary key
#  user_id        :integer
#  course_id      :integer
#  type           :string(255)
#  workflow_state :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

describe TaEnrollment do
  it "should subclass Enrollment" do
    expect(TaEnrollment.ancestors).to be_include(Enrollment)
  end
end

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe DataFixup::RemoveOrphanedContextModuleProgressions do
  it "should work" do
    c1 = Course.create!
    c2 = Course.create!
    cm1 = c1.context_modules.create!
    cm2 = c2.context_modules.create!
    u = User.create!
    c1.enroll_student(u)
    cmp1 = cm1.context_module_progressions.create!(user: u)
    cmp2 = cm2.context_module_progressions.create!(user: u)

    DataFixup::RemoveOrphanedContextModuleProgressions.run

    cmp1.reload
    expect { cmp2.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end

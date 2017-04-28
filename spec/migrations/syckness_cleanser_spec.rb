#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe DataFixup::SycknessCleanser do
  it "should remove the syckness" do
    user_factory
    @user.preferences = {:bloop => "blah"}
    @user.save!

    old_yaml = User.where(:id => @user).pluck("preferences as y").first
    new_yaml = old_yaml + Syckness::TAG
    User.where(:id => @user).update_all(["preferences = ?", new_yaml])

    DataFixup::SycknessCleanser.run(User, ['preferences'])

    expect(User.where(:id => @user).pluck("preferences as y").first).to eq old_yaml

    DataFixup::SycknessCleanser.run(User, ['preferences']) # make sure it doesn't break anything just in case

    expect(User.where(:id => @user).pluck("preferences as y").first).to eq old_yaml
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe Favorite do
  it "populates root account" do
    student_in_course
    favorite = @user.favorites.create!(context: @course)
    expect(favorite.root_account).to eq @course.root_account
  end

  describe ".create_or_find_by" do
    before do
      student_in_course
    end

    context "when item is not present" do
      it "inserts it into the DB" do
        expect(Favorite.all).to eq []

        fave = Favorite.create_or_find_by(user: @user, context: @course)
        expect(Favorite.all).to eq [fave]
      end
    end

    context "when item is present" do
      before do
        @fave = Favorite.create_or_find_by(user: @user, context: @course)
      end

      it "fetches it from the DB" do
        expect(Favorite.create_or_find_by(user: @user, context: @course)).to eq @fave
      end
    end
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module StudentVisibilityCommon
  shared_examples_for "student visibility models" do
    context "table" do
      it "returns objects" do
        expect(visibility_object).not_to be_nil
      end

      it "doesnt allow updates" do
        visibility_object.user_id = visibility_object.user_id + 1
        expect { visibility_object.save! }.to raise_error(ActiveRecord::ReadOnlyRecord)
      end

      it "doesnt allow new records" do
        expect do
          visibility_object.class.create!(visibility_object.attributes)
        end.to raise_error(ActiveRecord::ReadOnlyRecord)
      end

      it "doesnt allow deletion" do
        expect { visibility_object.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end
  end
end

# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe DefaultDueTimeHelper do
  include DefaultDueTimeHelper

  before :once do
    @root = Account.default
    @subaccount = account_model(parent_account: @root)
    @course = course_factory(account: @subaccount)
  end

  describe "default_due_time_options" do
    it "includes times" do
      stuff = default_due_time_options(@root)
      expect(stuff).to eq(
        [["Account default (11:59pm)", "inherit"],
         [" 1:00am", "01:00:00"],
         [" 2:00am", "02:00:00"],
         [" 3:00am", "03:00:00"],
         [" 4:00am", "04:00:00"],
         [" 5:00am", "05:00:00"],
         [" 6:00am", "06:00:00"],
         [" 7:00am", "07:00:00"],
         [" 8:00am", "08:00:00"],
         [" 9:00am", "09:00:00"],
         ["10:00am", "10:00:00"],
         ["11:00am", "11:00:00"],
         ["12:00pm", "12:00:00"],
         [" 1:00pm", "13:00:00"],
         [" 2:00pm", "14:00:00"],
         [" 3:00pm", "15:00:00"],
         [" 4:00pm", "16:00:00"],
         [" 5:00pm", "17:00:00"],
         [" 6:00pm", "18:00:00"],
         [" 7:00pm", "19:00:00"],
         [" 8:00pm", "20:00:00"],
         [" 9:00pm", "21:00:00"],
         ["10:00pm", "22:00:00"],
         ["11:00pm", "23:00:00"],
         ["11:59pm", "23:59:59"]]
      )
    end

    context "preserving non-hourly time" do
      it "works on account" do
        @root.update settings: { default_due_time: { value: "22:30:00" } }
        stuff = default_due_time_options(@root)
        expect(stuff).to include(["10:30pm", "22:30:00"])
      end

      it "works on course" do
        @course.update default_due_time: "22:30:00"
        stuff = default_due_time_options(@course)
        expect(stuff).to include(["10:30pm", "22:30:00"])
      end
    end

    context "inherited" do
      it "retrives correct account-course inherited time" do
        @subaccount.update settings: { default_due_time: { value: "22:00:00" } }
        stuff = default_due_time_options(@course)
        expect(stuff[0]).to eq(["Account default (10:00pm)", "inherit"])
      end

      it "retrieves correct account-subaccount inherited time" do
        @root.update settings: { default_due_time: { value: "22:00:00" } }
        stuff = default_due_time_options(@subaccount)
        expect(stuff[0]).to eq(["Account default (10:00pm)", "inherit"])
      end
    end
  end

  describe "default_due_time_key" do
    it "works for root account" do
      expect(default_due_time_key(@root)).to eq "inherit"
      @root.update settings: { default_due_time: { value: "4:00" } }
      expect(default_due_time_key(@root)).to eq "04:00:00"
    end

    it "works for subaccount" do
      expect(default_due_time_key(@subaccount)).to eq "inherit"

      @root.update settings: { default_due_time: { value: "4:00" } }
      expect(default_due_time_key(@subaccount)).to eq "inherit"

      @subaccount.update settings: { default_due_time: { value: "4:00" } }
      expect(default_due_time_key(@subaccount)).to eq "04:00:00"
    end

    it "works for course" do
      expect(default_due_time_key(@course)).to eq "inherit"
      @course.update default_due_time: "4:00 PM"
      expect(default_due_time_key(@course)).to eq "16:00:00"
    end
  end
end

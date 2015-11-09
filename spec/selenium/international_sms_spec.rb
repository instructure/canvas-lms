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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "international sms" do
  include_context "in-process server selenium tests"

  context "international sms enabled" do

    before(:each) do
      Account.default.enable_feature!(:international_sms)
      course_with_student_logged_in
    end

    it 'shows a disclaimer for international numbers', priority: "1", test_id: 443930 do
      # All selections except those in this array should include the text messaging rate disclaimer
      no_disclaimer = Array[
          'Select Country',
          'United States'
      ]

      get '/profile/settings'
      make_full_screen
      find('.add_contact_link.icon-add').click
      wait_for_ajaximations

      list_of_countries = find_all('.controls .user_selected.country option')
      list_of_countries.each do |country|
        fj(".controls .user_selected.country :contains(#{country.text})").click
        wait_for_ajaximations

        if no_disclaimer.any? { |w| country.text.include? w }
          # no text messaging rate disclaimer displayed
          expect(find('.intl_rates_may_apply')).to have_attribute('style', "display: none\;")\
        else
          # display text messaging rate disclaimer
          expect(find('.intl_rates_may_apply')).to have_attribute('style', "display: inline\;")
        end
      end
    end
  end
end

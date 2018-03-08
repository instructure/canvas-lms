#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')

module EnrollmentPageObject

  def add_people_button
    f('#addUsers')
  end

  def add_people_modal
    f('#add_people_modal')
  end

  def peopleready_info_box
    f('.peoplereadylist__pad-box')
  end

  def name_to_be_added(order)
    f(".addpeople__peoplereadylist tbody tr:nth-of-type(#{order}) td:nth-of-type(1)").text
  end

  def cancel_button
    f('#addpeople_cancel')
  end

  def next_button
    f('#addpeople_next')
  end

  def course_roster(row)
    f(".roster tbody tr:nth-of-type(#{row}) td")
  end


  # commenting these until further tests are added

  # def add_by_email_button
  #   f("input[type=radio][id='peoplesearch_radio_cc_path']")
  # end
  #
  # def add_by_login_id_buton
  #   f("input[type=radio][id='peoplesearch_radio_unique_id']")
  # end
  #
  # def add_by_sis_id_button
  #   f("input[type=radio][id='peoplesearch_radio_sis_user_id']")
  # end
  #
  # def example_email_text
  #   fxpath("//*[@class='addpeople_peoplesearch']//span[contains(text(),'lsmith@myschool.edu, mfoster@myschool.edu')]")
  # end
  #
  # def example_login_text
  #   fxpath("//*[@class='addpeople_peoplesearch']//span[contains(text(),'lsmith, mfoster')]")
  # end
  #
  # def example_sis_text
  #   fxpath("//*[@class='addpeople_peoplesearch']//span[contains(text(),'student_2708, student_3693')]")
  # end
  #
  # def select_role(role)
  #   click_option('#peoplesearch_select_role', role)
  # end

  # def select_section(section)
  #   click_option('#peoplesearch_select_section', section)
  # end
  #
  # def limit_privileges_to_section
  #   f("input[type=checkbox][id='limit_privileges_to_course_section']")
  # end
  #
  # def search_instructions
  #   fxpath("//*[@class='peoplesearch__instructions']//span[contains(text(),'When adding multiple users, use a comma or line break to separate users.')]")
  # end

  # def start_over
  #   f('#addpeople_back')
  # end
  #


  # def second_name_to_be_added
  #   f('.addpeople__peoplereadylist tbody tr:nth-of-type(2) td:nth-of-type(1)').text
  # end

  # def email_to_be_added
  #   f('.addpeople__peoplereadylist tbody tr td:nth-of-type(2)').text
  # end
  #
  # def login_to_be_added
  #   f('.addpeople__peoplereadylist tbody tr td:nth-of-type(3)').text
  # end
  #
  # def sis_id_to_be_added
  #   f('.addpeople__peoplereadylist tbody tr td:nth-of-type(4)').text
  # end
  #
  # def instituition_belonged_to
  #   f('.addpeople__peoplereadylist tbody tr td:nth-of-type(5)').text
  # end


end

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'quizzes question with html answers' do
  include_context "in-process server selenium tests"
  include QuizzesCommon

  before(:each) do
    course_with_teacher_logged_in
  end

  def edit_first_html_answer(question_type=nil)
    edit_first_question
    click_option('.question_form:visible .question_type', question_type) if question_type
    driver.execute_script "$('.answer').addClass('hover');"
    fj('.edit_html:visible').click
  end

  def close_first_html_answer
    move_to_click('.btn.edit_html_done')
  end

  def check_for_no_edit_button(option)
    click_option('.question_form:visible .question_type', option)
    driver.execute_script "$('.answer').addClass('hover');"
    expect(f("#content")).not_to contain_jqcss('.edit_html:visible')
  end

  it 'allows HTML answers for multiple choice', priority: "1", test_id: 209356 do
    quiz_with_new_questions
    click_questions_tab
    edit_first_html_answer
    type_in_tiny '.answer:eq(3) textarea', 'HTML'
    close_first_html_answer
    html = driver.execute_script "return $('.answer:eq(3) .answer_html').html()"
    expect(html).to eq '<p>HTML</p>'
    submit_form('.question_form')
    refresh_page
    click_questions_tab
    edit_first_question
    html = driver.execute_script "return $('.answer:eq(3) .answer_html').html()"
    wait_for_ajaximations
    expect(html).to eq '<p>HTML</p>'
  end

  it 'should preserve HTML image answers for multiple choice', priority: "2", test_id: 3103797 do
    img_url = "http://invalid.nowhere.com/nothing.jpg"
    img_alt = "sample alt text"
    img_cls = "sample_image"
    quiz_with_new_questions(true, {id: 1}, {id: 2},
                            {id: 3, answer_html: %|<img src="#{img_url}" alt="#{img_alt}" class="#{img_cls}">|})
    dismiss_flash_messages # in non-prod environments images that fail to load will cause a flash message
    click_questions_tab
    edit_first_question
    alt_before = fj(".#{img_cls}", question_answers[2]).attribute('alt')
    select_different_correct_answer(2)
    alt_after = fj(".#{img_cls}", question_answers[2]).attribute('alt')
    expect(alt_after).to eq alt_before
  end

  it 'sets focus back to the edit button after editing', priority: "1", test_id: 209357 do
    quiz_with_new_questions
    click_questions_tab
    edit_first_html_answer
    close_first_html_answer
    wait_for_ajaximations
    check_element_has_focus(fj('.edit_html:visible'))
  end

  it 'doesn\'t show the edit html button for question types besides multiple choice and multiple answers', priority: "1", test_id: 209358 do
    quiz_with_new_questions
    click_questions_tab
    edit_first_question

    check_for_no_edit_button 'True/False'
    check_for_no_edit_button 'Fill In the Blank'
    check_for_no_edit_button 'Fill In Multiple Blanks'
    check_for_no_edit_button 'Multiple Dropdowns'
    check_for_no_edit_button 'Matching'
    check_for_no_edit_button 'Numerical Answer'
  end

  it 'restores normal input when html answer is empty', priority: "1", test_id: 209359 do
    quiz_with_new_questions
    click_questions_tab
    edit_first_html_answer
    type_in_tiny '.answer:eq(3) textarea', 'HTML'

    # clear tiny
    driver.execute_script "tinyMCE.activeEditor.setContent('')"
    close_first_html_answer
    input_length = driver.execute_script "return $('.answer:eq(3) input[name=answer_text]:visible').length"
    expect(input_length).to eq 1
  end

  it 'populates the editor and input elements properly', priority: "1", test_id: 209360 do
    quiz_with_new_questions
    click_questions_tab

    # add text to regular input
    edit_first_question
    input = fj('input[name=answer_text]:visible')
    input.click
    input.send_keys 'ohai'
    submit_form('.question_form')
    wait_for_ajax_requests

    # open it up in the editor, make sure the text matches the input
    edit_first_html_answer
    content = driver.execute_script "return $('.answer:eq(3) textarea')._justGetCode()"
    expect(content).to eq '<p>ohai</p>'

    # clear it out, make sure the original input is empty also
    driver.execute_script "tinyMCE.activeEditor.setContent('')"
    close_first_html_answer
    value = driver.execute_script "return $('input[name=answer_text]:visible')[0].value"
    expect(value).to eq ''
  end

  it 'saves open html answers when the question is submitted for multiple choice', priority: "1", test_id: 209361 do
    quiz_with_new_questions
    click_questions_tab
    edit_first_html_answer
    type_in_tiny '.answer:eq(3) textarea', 'HTML'
    submit_form('.question_form')
    refresh_page
    click_questions_tab
    edit_first_question
    html = driver.execute_script "return $('.answer:eq(3) .answer_html').html()"
    expect(html).to eq '<p>HTML</p>'
  end

  it 'saves open html answers when the question is submitted for multiple answers', priority: "1", test_id: 209362 do
    quiz_with_new_questions
    click_questions_tab
    edit_first_html_answer 'Multiple Answers'
    type_in_tiny '.answer:eq(3) textarea', 'HTML'
    submit_form('.question_form')
    refresh_page
    click_questions_tab
    edit_first_question
    html = driver.execute_script "return $('.answer:eq(3) .answer_html').html()"
    expect(html).to eq '<p>HTML</p>'
  end
end

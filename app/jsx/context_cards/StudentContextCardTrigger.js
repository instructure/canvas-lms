/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import StudentContextTray from '../context_cards/GraphQLStudentContextTray'

  const handleClickEvent = (event) => {
    const studentId = $(event.target).attr('data-student_id');
    const courseId = $(event.target).attr('data-course_id');
    if (ENV.STUDENT_CONTEXT_CARDS_ENABLED && studentId && courseId) {
      event.preventDefault();
      const container = document.getElementById('StudentTray__Container')

      const returnFocusToHandler = () => {
        const focusableItems = [$(event.target)];
        if ($('.search-query')) {
          focusableItems.push($('.search-query'))
        }
        if ($('[name="search_term"]')) {
          focusableItems.push($('[name="search_term"]'))
        }

        return focusableItems;
      }

      ReactDOM.render(
        <StudentContextTray
          key={`student_context_card_${courseId}_${studentId}`}
          courseId={courseId}
          studentId={studentId}
          returnFocusTo={returnFocusToHandler}
        />, container
      )
    }
  }

  $(document).on('click', '.student_context_card_trigger', handleClickEvent);

export default handleClickEvent;


/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import ready from '@instructure/ready'
import $ from 'jquery'
import QuizArrowApplicator from '@canvas/quizzes/jquery/quiz_arrows'
import './jquery/quizzes'
import './jquery/supercalc'
import '@canvas/quizzes/jquery/quiz_rubric'
import '@canvas/jquery/jquery.simulate'

ready(() => {
  $('#show_question_details').on('click', function () {
    // Create the quiz arrows
    if ($(this).is(':checked')) {
      const arrowApplicator = new QuizArrowApplicator()
      arrowApplicator.applyArrows()
    } else {
      // Delete all quiz arrows
      $('.answer_arrow').remove()
    }
  })

  // Subscribe to custom event that is triggered as an 'aftersave' on a question form
  $('body').on('saved', '.question', () => {
    // Remove all arrows and recreate all if option is checked
    $('.answer_arrow').remove()
    if ($('#show_question_details').is(':checked')) {
      const arrowApplicator = new QuizArrowApplicator()
      arrowApplicator.applyArrows()
    }
  })
})

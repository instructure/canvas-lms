/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {scoreToGrade} from '@instructure/grading-utils'
import '@canvas/jquery/jquery.ajaxJSON'

const I18n = useI18nScope('user_grades')

$(document).ready(function () {
  $('.grading_periods_selector').each(function () {
    const $selector = $(this),
      selectedOption = $selector.find('option:selected').val()
    $selector.val(selectedOption)
  })

  $('.grading_periods_selector').on('change', function (_e) {
    const selector = $(this),
      gradingPeriodId = selector.val(),
      enrollmentId = selector.attr('data-enrollment-id')

    $.ajaxJSON(
      ENV.grades_for_student_url,
      'GET',
      {
        grading_period_id: gradingPeriodId,
        enrollment_id: enrollmentId,
      },
      totals => {
        const $percentDisplay = $(this).closest('tr').children('.percent')
        let gradeToShow

        if (totals.hide_final_grades) {
          gradeToShow = '--'
        } else if (totals.grade || totals.grade === 0) {
          gradeToShow = totals.restrict_quantitative_data
            ? scoreToGrade(totals.grade, totals.grading_scheme)
            : totals.grade + '%'
        } else {
          gradeToShow = I18n.t('no grade')
        }

        $percentDisplay.text(gradeToShow)
      }
    )
  })
})

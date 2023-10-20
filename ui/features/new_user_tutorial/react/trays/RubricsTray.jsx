/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import TutorialTrayContent from './TutorialTrayContent'

const I18n = useI18nScope('new_user_tutorial')

const RubricsTray = () => (
  <TutorialTrayContent
    name="Rubrics"
    heading={I18n.t('Rubrics')}
    subheading={I18n.t('Communicate grading expectations')}
    image="/images/tutorial-tray-images/Panda_Teacher.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: I18n.t('#community.instructor_guide'),
    }}
    links={[
      {
        label: I18n.t('How do I add a rubric in a course?'),
        href: I18n.t('#community.instructor_add_rubric_course'),
      },
      {
        label: I18n.t('How do I manage rubrics in a course?'),
        href: I18n.t('#community.instructor_manage_rubrics'),
      },
      {
        label: I18n.t('How do I align an outcome with a rubric in a course?'),
        href: I18n.t('#community.instructor_align_outcome_rubric'),
      },
      {
        label: I18n.t('How do I add a rubric to an assignment?'),
        href: I18n.t('#community.instructor_add_rubric_assignment'),
      },
    ]}
  >
    {I18n.t(`Rubrics can show students your expectations for assignment quality
    and how they'll be scored accordingly. Rubrics can be associated with
    assignments, discussions, and quizzes. Use a rubric solely for grading,
    or create a non-scoring rubric specifically for assessment-based and
    outcome-based grading without points. Outcomes can be added as criteria
    items in rubrics.`)}
  </TutorialTrayContent>
)

export default RubricsTray

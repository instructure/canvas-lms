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

const QuizzesTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Quizzes')}
    subheading={I18n.t('Assess student understanding')}
    image="/images/tutorial-tray-images/Panda_Quizzes.svg"
    imageWidth="8rem"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: I18n.t('#community.instructor_guide'),
    }}
    links={[
      {
        label: I18n.t('How do I use the Quizzes Index Page?'),
        href: I18n.t('#community.instructor_use_quizzes_index'),
      },
      {
        label: I18n.t('How do I create an assessment using New Quizzes?'),
        href: I18n.t('#community.instructor_create_new_quiz'),
      },
      {
        label: I18n.t('How do I manage settings for an assessment in New Quizzes?'),
        href: I18n.t('#community.instructor_manage_new_quizzes_settings'),
      },
      {
        label: I18n.t('How do I create a quiz with individual questions?'),
        href: I18n.t('#community.instructor_create_quiz_questions'),
      },
      {
        label: I18n.t('What options can I set in a quiz?'),
        href: I18n.t('#community.instructor_quiz_options'),
      },
    ]}
  >
    {I18n.t(`Use quizzes to challenge student understanding and assess comprehension
      of course material. The New Quizzes assessment engine allows you to create up to
      13 types of question types and content. If New Quizzes isn't enabled for your institution,
      Classic Quizzes are still available to help you achieve your objectives.`)}
  </TutorialTrayContent>
)

export default QuizzesTray

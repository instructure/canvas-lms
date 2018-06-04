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
import I18n from 'i18n!new_user_tutorial'
import Text from '@instructure/ui-elements/lib/components/Text'
import TutorialTrayContent from './TutorialTrayContent'

const QuizzesTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Quizzes')}
    subheading={I18n.t('Assess and survey your students')}
    image="/images/tutorial-tray-images/quiz.svg"
  >
    <Text as="p">
      {
        I18n.t('Create and administer online quizzes and surveys, both graded and ungraded.')
      }
    </Text>
  </TutorialTrayContent>
);

export default QuizzesTray

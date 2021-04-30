/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import I18n from 'i18n!k5_course_GradesEmptyPage'
import PropTypes from 'prop-types'

import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'

import EmptyGradesUrl from '../images/empty-grades.svg'

const GradesEmptyPage = ({userIsInstructor, courseId}) => (
  <Flex direction="column" alignItems="center" margin="x-large large">
    <Img src={EmptyGradesUrl} margin="0 0 medium 0" data-testid="empty-grades-panda" />
    {userIsInstructor ? (
      <>
        <Text size="large">{I18n.t('Students see their grades here.')}</Text>
        <Button href={`/courses/${courseId}/gradebook`} margin="small 0 0 0">
          {I18n.t('View Gradebook')}
        </Button>
      </>
    ) : (
      <Text size="large">{I18n.t("You don't have any grades yet.")}</Text>
    )}
  </Flex>
)

GradesEmptyPage.propTypes = {
  userIsInstructor: PropTypes.bool.isRequired,
  courseId: PropTypes.string.isRequired
}

export default GradesEmptyPage

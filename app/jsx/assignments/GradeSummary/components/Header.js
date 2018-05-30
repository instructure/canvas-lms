/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {arrayOf, shape, string} from 'prop-types'
import Alert from '@instructure/ui-alerts/lib/components/Alert'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import I18n from 'i18n!assignment_grade_summary'

export default function Header(props) {
  const showNoGradersMessage = !props.assignment.gradesPublished && props.graders.length === 0

  return (
    <header>
      {showNoGradersMessage && (
        <Alert margin="0 0 medium 0" variant="warning">
          {I18n.t('Moderation is unable to occur at this time due to grades not being submitted.')}
        </Alert>
      )}

      <Heading level="h1">{I18n.t('Grade Summary')}</Heading>

      <Heading level="h2" margin="small 0 0 0">
        {props.assignment.title}
      </Heading>
    </header>
  )
}

Header.propTypes = {
  assignment: shape({
    title: string.isRequired
  }).isRequired,
  graders: arrayOf(
    shape({
      graderId: string.isRequired
    })
  ).isRequired
}

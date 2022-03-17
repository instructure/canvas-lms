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
import {useScope as useI18nScope} from '@canvas/i18n'
import {bool, string} from 'prop-types'
import React from 'react'

import {Pill} from '@instructure/ui-pill'

const I18n = useI18nScope('assignments_2')

export default function SubmissionStatusPill(props) {
  if (props.excused) {
    return <Pill data-test-id="excused-pill">{I18n.t('Excused')}</Pill>
  } else if (props.submissionStatus === 'missing') {
    return (
      <Pill data-test-id="missing-pill" color="danger">
        {I18n.t('Missing')}
      </Pill>
    )
  } else if (props.submissionStatus === 'late') {
    return <Pill data-test-id="late-pill">{I18n.t('Late')}</Pill>
  } else {
    return null
  }
}

SubmissionStatusPill.propTypes = {
  excused: bool,
  submissionStatus: string
}

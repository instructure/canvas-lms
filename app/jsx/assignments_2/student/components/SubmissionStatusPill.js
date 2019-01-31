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
import I18n from 'i18n!assignments_2'
import {string} from 'prop-types'
import React from 'react'

import Pill from '@instructure/ui-elements/lib/components/Pill'

function SubmissionStatusPill(props) {
  if (!props.submissionStatus) {
    return null
  }
  return (
    <React.Fragment>
      {props.submissionStatus === 'missing' ? (
        <Pill
          data-test-id="missing-pill"
          variant="danger"
          text={I18n.t('Missing')}
          margin="x-small 0 0 0"
        />
      ) : (
        <Pill data-test-id="late-pill" text={I18n.t('Late')} margin="x-small 0 0 0" />
      )}
    </React.Fragment>
  )
}

SubmissionStatusPill.propTypes = {
  submissionStatus: string
}

export default React.memo(SubmissionStatusPill)

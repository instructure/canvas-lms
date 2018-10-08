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
import {func} from 'prop-types'
import ApplyTheme from '@instructure/ui-themeable/lib/components/ApplyTheme'
import Button from '@instructure/ui-buttons/lib/components/Button'
import IconClock from '@instructure/ui-icons/lib/Line/IconClock'
import I18n from 'i18n!speed_grader'

const theme = {
  [Button.theme]: {
    smallPadding: '0'
  }
}

export default function AssessmentAuditButton(props) {
  return (
    <ApplyTheme theme={theme}>
      <Button icon={IconClock} onClick={props.onClick} size="small" variant="link">
        {I18n.t('Assessment audit')}
      </Button>
    </ApplyTheme>
  )
}

AssessmentAuditButton.propTypes = {
  onClick: func.isRequired
}

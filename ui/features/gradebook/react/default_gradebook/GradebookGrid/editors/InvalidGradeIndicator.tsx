// @ts-nocheck
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
import {IconButton} from '@instructure/ui-buttons'
import {IconWarningLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook')

export default function InvalidGradeIndicator(props) {
  return (
    <div className="Grid__GradeCell__InvalidGrade">
      <Tooltip placement="bottom" renderTip={I18n.t('This is not a valid grade')} color="primary">
        <IconButton
          elementRef={props.elementRef}
          size="small"
          color="danger"
          withBorder={false}
          withBackground={false}
          renderIcon={IconWarningLine}
          screenReaderLabel={I18n.t('This is not a valid grade')}
        />
      </Tooltip>
    </div>
  )
}

InvalidGradeIndicator.propTypes = {
  elementRef: func.isRequired,
}

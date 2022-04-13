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
import {Button} from '@instructure/ui-buttons'
import {IconWarningLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook')

export default function InvalidGradeIndicator(props) {
  return (
    <div className="Grid__GradeCell__InvalidGrade">
      <Tooltip placement="bottom" renderTip={I18n.t('This is not a valid grade')} color="primary">
        <Button elementRef={props.elementRef} size="small" variant="icon">
          <Text color="danger">
            <IconWarningLine />
          </Text>
        </Button>
      </Tooltip>
    </div>
  )
}

InvalidGradeIndicator.propTypes = {
  elementRef: func.isRequired
}

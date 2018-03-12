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
import Button from '@instructure/ui-core/lib/components/Button'
import Text from '@instructure/ui-core/lib/components/Text'
import Tooltip from '@instructure/ui-core/lib/components/Tooltip'
import IconWarningLine from 'instructure-icons/lib/Line/IconWarningLine'
import I18n from 'i18n!gradebook'

function InvalidGradeIndicator(props) {
  return (
    <div className="Grid__AssignmentRowCell__InvalidGrade">
      <Tooltip
        placement="bottom"
        size="medium"
        tip={I18n.t('This is not a valid grade')}
        variant="inverse"
      >
        <Button buttonRef={props.elementRef} size="small" variant="icon">
          <Text color="error">
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

export default InvalidGradeIndicator

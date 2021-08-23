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

import {Flex} from '@instructure/ui-flex'
import PropTypes from 'prop-types'
import React from 'react'
import theme from '@instructure/canvas-theme'

function buildFooterStyle() {
  return {
    backgroundColor: theme.variables.colors.white,
    borderColor: theme.variables.colors.borderMedium
  }
}

const StudentFooter = ({buttons}) => (
  <div data-testid="student-footer" id="assignments-student-footer" style={buildFooterStyle()}>
    <Flex alignItems="center" height="100%" margin="0" justifyItems="space-between">
      {['left', 'right'].map(align => (
        <Flex key={align} alignItems="center" height="100%" margin="0" justifyItems="end">
          {buttons.length === 0 && <></>}
          {buttons
            .filter(button => button.align === align)
            .map(button => (
              <Flex.Item key={button.key} padding="auto small">
                {button.element}
              </Flex.Item>
            ))}
        </Flex>
      ))}
    </Flex>
  </div>
)

const buttonPropType = PropTypes.shape({
  element: PropTypes.element,
  key: PropTypes.string
})

StudentFooter.propTypes = {
  buttons: PropTypes.arrayOf(buttonPropType)
}

export default StudentFooter

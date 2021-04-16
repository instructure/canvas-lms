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

import PropTypes from 'prop-types'
import React from 'react'

import {Flex} from '@instructure/ui-flex'

export const ComposeInputWrapper = props => {
  return (
    <Flex width="100%">
      <Flex.Item size="4em" padding="xx-small">
        {props.title}
      </Flex.Item>
      <Flex.Item shouldGrow={props.shouldGrow} padding="xx-small">
        {props.input}
      </Flex.Item>
    </Flex>
  )
}

ComposeInputWrapper.propTypes = {
  title: PropTypes.element,
  input: PropTypes.element,
  shouldGrow: PropTypes.bool
}

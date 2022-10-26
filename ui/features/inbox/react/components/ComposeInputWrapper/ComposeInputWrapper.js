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
import {Text} from '@instructure/ui-text'

export const ComposeInputWrapper = props => {
  return (
    <Flex width="100%" direction="column">
      {props.title && (
        <Flex.Item padding="none none none xx-small">
          <Text weight="bold">{props.title}</Text>
        </Flex.Item>
      )}
      <Flex.Item shouldGrow={true} shouldShrink={true} padding="xx-small">
        {props.input}
      </Flex.Item>
    </Flex>
  )
}

ComposeInputWrapper.propTypes = {
  title: PropTypes.element,
  input: PropTypes.element,
}

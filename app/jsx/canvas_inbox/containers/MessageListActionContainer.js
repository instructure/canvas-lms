/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {CourseSelect} from '../components/CourseSelect/CourseSelect'
import {Flex} from '@instructure/ui-flex'
import {MailboxSelectionDropdown} from '../components/MailboxSelectionDropdown/MailboxSelectionDropdown'
import {MessageActionButtons} from '../components/MessageActionButtons/MessageActionButtons'
import PropTypes from 'prop-types'
import React from 'react'
import {View} from '@instructure/ui-view'

const MessageListActionContainer = props => {
  return (
    <View
      as="div"
      display="inline-block"
      width="100%"
      margin="none"
      padding="small"
      background="secondary"
    >
      <Flex wrap="wrap">
        <Flex.Item>
          {/* // TODO: Wire up course select with container story */}
          <CourseSelect options={[]} onCourseFilterSelect={props.onCourseFilterSelect} />
        </Flex.Item>
        <Flex.Item padding="none none none xxx-small">
          <MailboxSelectionDropdown onSelect={props.onSelectMailbox} />
        </Flex.Item>
        <Flex.Item shouldGrow shouldShrink />
        <Flex.Item>
          <MessageActionButtons />
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default MessageListActionContainer

MessageListActionContainer.propTypes = {
  onCourseFilterSelect: PropTypes.func,
  onSelectMailbox: PropTypes.func
}

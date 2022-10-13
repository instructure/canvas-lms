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

import React from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {IconGradebookLine, IconNotGradedLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'

const I18n = useI18nScope('discussion_posts')

export const InlineGrade = props => {
  const gradeStatusIcon = () => {
    if (props.isLoading) {
      return (
        <Flex.Item data-testid="inline-grade-loading-status">
          <Spinner renderTitle="Loading" size="x-small" />
        </Flex.Item>
      )
    } else if (props.isGraded) {
      return (
        <Flex.Item margin="none xx-small none" data-testid="inline-grade-graded-status">
          <IconGradebookLine color="success" />
        </Flex.Item>
      )
    }
    return (
      <Flex.Item margin="none xx-small none" data-testid="inline-grade-ungraded-status">
        <IconNotGradedLine color="error" />
      </Flex.Item>
    )
  }

  return (
    <Flex>
      {gradeStatusIcon()}
      <Flex.Item margin="none xx-small none">
        <Text>{I18n.t('Grade')}</Text>
      </Flex.Item>
      <Flex.Item margin="none xx-small none">
        <TextInput
          defaultValue={props.currentGrade}
          renderLabel={<ScreenReaderContent>{I18n.t('Enter the grade')}</ScreenReaderContent>}
          display="inline-block"
          width="3rem"
          size="small"
          onChange={event => {
            props.onGradeChange(event.target.value)
          }}
        />
      </Flex.Item>
      <Flex.Item margin="none xx-small none">
        <Text>/{props.pointsPossible}</Text>
      </Flex.Item>
    </Flex>
  )
}

InlineGrade.prototypes = {
  isGraded: PropTypes.bool,
  isLoading: PropTypes.bool,
  onGradeChange: PropTypes.func,
  pointsPossible: PropTypes.string.isRequired,
  currentGrade: PropTypes.string,
}

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
import {func, number, string, oneOf} from 'prop-types'
import I18n from 'i18n!speed_grader'
import {Menu} from '@instructure/ui-menu'
import {IconEditLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import TimeLateInput from '@canvas/grading/TimeLateInput'

const statusesMap = {
  excused: I18n.t('Excused'),
  late: I18n.t('Late'),
  missing: I18n.t('Missing'),
  none: I18n.t('None')
}

export default function SpeedGraderStatusMenu(props) {
  const handleSelection = (_, newSelection) => {
    if (newSelection === props.selection) {
      return
    }

    props.updateSubmission(newSelection)
  }

  const menuOptions = ['late', 'missing', 'excused', 'none'].map(status => (
    <Menu.Item
      key={status}
      value={status}
      selected={props.selection === status}
      onSelect={handleSelection}
    >
      {statusesMap[status]}
    </Menu.Item>
  ))

  return (
    <>
      <Flex justifyItems="end">
        <Flex.Item>
          <Menu
            withArrow={false}
            placement="bottom"
            trigger={
              <IconButton
                size="small"
                screenReaderLabel={I18n.t('Edit status')}
                margin="none none small"
              >
                <IconEditLine />
              </IconButton>
            }
          >
            <Menu.Group label={<ScreenReaderContent>{I18n.t('Menu options')}</ScreenReaderContent>}>
              {menuOptions}
            </Menu.Group>
          </Menu>
        </Flex.Item>
      </Flex>
      {props.selection === 'late' && (
        <TimeLateInput
          lateSubmissionInterval={props.lateSubmissionInterval}
          locale={props.locale}
          renderLabelBefore
          secondsLate={props.secondsLate}
          onSecondsLateUpdated={props.updateSubmission}
          width="3.3125rem"
        />
      )}
    </>
  )
}

SpeedGraderStatusMenu.propTypes = {
  lateSubmissionInterval: oneOf(['day', 'hour']).isRequired,
  locale: string.isRequired,
  secondsLate: number.isRequired,
  selection: string.isRequired,
  updateSubmission: func.isRequired
}

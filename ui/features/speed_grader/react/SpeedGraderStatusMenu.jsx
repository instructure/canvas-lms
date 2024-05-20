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
import {func, number, string, oneOf, array} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Menu} from '@instructure/ui-menu'
import {IconEditLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import TimeLateInput from '@canvas/grading/TimeLateInput'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'

const I18n = useI18nScope('speed_grader')

export default function SpeedGraderStatusMenu(props) {
  const statusesMap = {
    extended: I18n.t('Extended'),
    excused: I18n.t('Excused'),
    late: I18n.t('Late'),
    missing: I18n.t('Missing'),
    none: I18n.t('None'),
  }
  props.customStatuses?.forEach(status => {
    statusesMap[status.id] = status.name
  })
  const handleSelection = (_, newSelection) => {
    if (newSelection === props.selection) {
      return
    }
    let data = {latePolicyStatus: newSelection}
    if (newSelection === 'excused') {
      data = {excuse: true}
    } else if (newSelection === 'late') {
      data = {latePolicyStatus: newSelection, secondsLateOverride: props.secondsLate}
      // eslint-disable-next-line no-restricted-globals
    } else if (!isNaN(parseInt(newSelection, 10))) {
      data = {customGradeStatusId: newSelection}
    }
    props.updateSubmission(data)
  }

  const optionValues = ['late', 'missing', 'excused']
  if (ENV.FEATURES && ENV.FEATURES.extended_submission_state) {
    optionValues.push('extended')
  }
  props.customStatuses?.forEach(status => {
    optionValues.push(status.id)
  })
  optionValues.push('none')

  const menuOptions = optionValues.map(status => (
    <Menu.Item
      key={status}
      value={status}
      data-testid={`speedGraderStatusMenu-${status}`}
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
                data-testid="speedGraderStatusMenu-editButton"
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
        <>
          <div style={{position: 'absolute', right: '24px'}}>
            <TimeLateInput
              lateSubmissionInterval={props.lateSubmissionInterval}
              locale={props.locale}
              renderLabelBefore={true}
              secondsLate={props.secondsLate}
              onSecondsLateUpdated={props.updateSubmission}
              width="5rem"
            />
            {props.cachedDueDate ? (
              <FriendlyDatetime
                data-testid="original-due-date"
                prefix={I18n.t('Due:')}
                format={I18n.t('#date.formats.full_with_weekday')}
                dateTime={props.cachedDueDate}
              />
            ) : null}
          </div>
        </>
      )}
    </>
  )
}

SpeedGraderStatusMenu.propTypes = {
  lateSubmissionInterval: oneOf(['day', 'hour']).isRequired,
  locale: string.isRequired,
  secondsLate: number.isRequired,
  selection: string.isRequired,
  updateSubmission: func.isRequired,
  cachedDueDate: string,
  customStatuses: array,
}

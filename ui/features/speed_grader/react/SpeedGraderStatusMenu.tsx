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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Menu} from '@instructure/ui-menu'
import {IconEditLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import TimeLateInput from '@canvas/grading/TimeLateInput'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'

const I18n = useI18nScope('speed_grader')

const initialStatusesMap: Map<string, string> = new Map([
  ['extended', I18n.t('Extended')],
  ['excused', I18n.t('Excused')],
  ['late', I18n.t('Late')],
  ['missing', I18n.t('Missing')],
  ['none', I18n.t('None')],
])

type Props = {
  lateSubmissionInterval: 'day' | 'hour'
  locale: string
  secondsLate: number
  selection: string
  updateSubmission: (data: any) => void
  cachedDueDate?: string | null
  customStatuses?: Array<any>
}

export default function SpeedGraderStatusMenu({
  customStatuses,
  selection,
  secondsLate,
  updateSubmission,
  lateSubmissionInterval,
  locale,
  cachedDueDate,
}: Props) {
  const statusesMap = new Map(initialStatusesMap)
  customStatuses?.forEach(status => {
    statusesMap.set(status.id, status.name)
  })
  const handleSelection = (newSelection: string) => {
    if (newSelection === selection) {
      return
    }
    let data: {
      excuse?: boolean
      latePolicyStatus?: string
      secondsLateOverride?: number
      customGradeStatusId?: string
    } = {latePolicyStatus: newSelection}
    if (newSelection === 'excused') {
      data = {excuse: true}
    } else if (newSelection === 'late') {
      data = {latePolicyStatus: newSelection, secondsLateOverride: secondsLate}
      // eslint-disable-next-line no-restricted-globals
    } else if (!isNaN(parseInt(newSelection, 10))) {
      data = {customGradeStatusId: newSelection}
    }
    updateSubmission(data)
  }

  const optionValues = ['late', 'missing', 'excused']
  if (ENV.FEATURES?.extended_submission_state) {
    optionValues.push('extended')
  }
  customStatuses?.forEach(status => {
    optionValues.push(status.id)
  })
  optionValues.push('none')

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
              {optionValues.map(status => (
                <Menu.Item
                  key={status}
                  value={status}
                  data-testid={`speedGraderStatusMenu-${status}`}
                  selected={selection === status}
                  onSelect={(_, newSelection) => handleSelection(String(newSelection))}
                >
                  {statusesMap.get(status)}
                </Menu.Item>
              ))}
            </Menu.Group>
          </Menu>
        </Flex.Item>
      </Flex>
      {selection === 'late' && (
        <>
          <div style={{position: 'absolute', right: '24px'}}>
            <TimeLateInput
              lateSubmissionInterval={lateSubmissionInterval}
              locale={locale}
              renderLabelBefore={true}
              secondsLate={secondsLate}
              onSecondsLateUpdated={updateSubmission}
              width="5rem"
            />
            {cachedDueDate ? (
              <FriendlyDatetime
                data-testid="original-due-date"
                prefix={I18n.t('Due:')}
                format={I18n.t('#date.formats.full_with_weekday')}
                dateTime={cachedDueDate}
              />
            ) : null}
          </div>
        </>
      )}
    </>
  )
}

/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import DateOptionsModal from './DateOptionsModal'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ToggleButton, IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {Text} from '@instructure/ui-text'
import {
  IconPlaySolid,
  IconPauseSolid,
  IconCalendarClockLine,
  IconCalendarClockSolid,
  IconAnalyticsSolid,
} from '@instructure/ui-icons'

const I18n = useI18nScope('jobs_v2')

export default function JobsHeader({
  jobBucket,
  onChangeBucket,
  jobGroup,
  onChangeGroup,
  jobScope,
  onChangeScope,
  autoRefresh,
  onChangeAutoRefresh,
  startDate,
  endDate,
  timeZone,
  onChangeDateOptions,
}) {
  const [dateModalOpen, setDateModalOpen] = useState(false)

  return (
    <Flex wrap="wrap">
      <Flex.Item>
        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Job category')}</ScreenReaderContent>}
        >
          <RadioInputGroup
            name="job_bucket"
            value={jobBucket}
            onChange={onChangeBucket}
            description=""
            variant="toggle"
          >
            <RadioInput label={I18n.t('Running')} value="running" />
            <RadioInput label={I18n.t('Queued')} value="queued" />
            <RadioInput label={I18n.t('Future')} value="future" />
            <RadioInput label={I18n.t('Failed')} value="failed" context="warning" />
          </RadioInputGroup>
        </FormFieldGroup>
      </Flex.Item>
      <Flex.Item margin="0 medium">
        <Text color="secondary"> | </Text>
      </Flex.Item>
      <Flex.Item>
        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Job grouping')}</ScreenReaderContent>}
        >
          <RadioInputGroup
            name="job_group"
            value={jobGroup}
            onChange={onChangeGroup}
            description=""
            variant="toggle"
          >
            <RadioInput label={I18n.t('Tag')} value="tag" />
            <RadioInput label={I18n.t('Strand')} value="strand" />
            <RadioInput label={I18n.t('Singleton')} value="singleton" />
          </RadioInputGroup>
        </FormFieldGroup>
      </Flex.Item>
      <Flex.Item margin="0 medium">
        <Text color="secondary"> | </Text>
      </Flex.Item>
      <Flex.Item align="end" margin="0 x-small x-small 0">
        <PresentationContent>
          <strong>{I18n.t('Scope:')}</strong>
        </PresentationContent>
      </Flex.Item>
      <Flex.Item align="end" shouldGrow={true}>
        <SimpleSelect
          renderLabel={<ScreenReaderContent>{I18n.t('Scope')}</ScreenReaderContent>}
          onChange={onChangeScope}
          value={ENV.jobs_scope_filter[jobScope]}
        >
          {Object.entries(ENV.jobs_scope_filter).map(([key, value]) => {
            return (
              <SimpleSelect.Option id={key} key={key} value={value}>
                {value}
              </SimpleSelect.Option>
            )
          })}
        </SimpleSelect>
      </Flex.Item>
      <Flex.Item margin="0 0 0 xx-small">
        <Tooltip
          renderTip={
            startDate || endDate ? I18n.t('Date filter is in effect') : I18n.t('Date/Time options')
          }
          on={['hover', 'focus']}
        >
          <IconButton
            withBorder={false}
            withBackground={false}
            screenReaderLabel={I18n.t('Date/Time options')}
            onClick={() => setDateModalOpen(true)}
          >
            {startDate || endDate ? (
              <IconCalendarClockSolid color="alert" />
            ) : (
              <IconCalendarClockLine />
            )}
          </IconButton>
        </Tooltip>
        <DateOptionsModal
          open={dateModalOpen}
          startDate={startDate}
          endDate={endDate}
          timeZone={timeZone}
          onSave={onChangeDateOptions}
          onClose={() => setDateModalOpen(false)}
        />
      </Flex.Item>
      <Flex.Item>
        <Tooltip renderTip={I18n.t('Job Stats')}>
          <IconButton
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Job Stats')}
            href="/job_stats"
          >
            <IconAnalyticsSolid />
          </IconButton>
        </Tooltip>
      </Flex.Item>
      <Flex.Item>
        <ToggleButton
          status={autoRefresh ? 'pressed' : 'unpressed'}
          color={autoRefresh ? 'primary' : 'secondary'}
          renderIcon={autoRefresh ? IconPauseSolid : IconPlaySolid}
          screenReaderLabel={
            autoRefresh ? I18n.t('Pause auto-refresh') : I18n.t('Start auto-refresh')
          }
          renderTooltipContent={
            autoRefresh ? I18n.t('Pause auto-refresh') : I18n.t('Start auto-refresh')
          }
          onClick={onChangeAutoRefresh}
        />
      </Flex.Item>
    </Flex>
  )
}

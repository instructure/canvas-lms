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
import React from 'react'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('jobs_v2')

export default function JobsHeader({jobBucket, onChangeBucket, jobGroup, onChangeGroup}) {
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
      <Flex.Item margin="0 large"> | </Flex.Item>
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
    </Flex>
  )
}

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

import React, {useContext} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconButton} from '@instructure/ui-buttons'
import {IconQuestionLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {bool, func, string} from 'prop-types'
import {GroupContext} from './context'
import SelfSignupEndDate from './SelfSignupEndDate'

const I18n = createI18nScope('groups')

export const SelfSignup = ({
  onChange,
  selfSignupEndDateEnabled = false,
  endDateOnChange,
  direction,
}) => {
  const {selfSignup, bySection} = useContext(GroupContext)

  const helpText = (
    <div style={{maxWidth: '300px'}}>
      <p>
        {I18n.t(
          'You can create sets of groups where students can sign up on their own. Students are still limited to being in only one group in the set, but this way students can organize themselves into groups instead of needing the teacher to do the work.',
        )}
      </p>
      <p>
        {selfSignupEndDateEnabled
          ? I18n.t('With this option enabled, students can move themselves from one group to another. However, you can set an end date to close self sign-up to prevent students from joining or changing groups after a certain date.')
          : I18n.t('Note that as long as this option is enabled, students can move themselves from one group to another.')
        }
      </p>
    </div>
  )

  function handleChange(key, val) {
    const result = {selfSignup, bySection}
    result[key] = val
    onChange(result)
  }

  const handleEndDateUpdate = value => {
    endDateOnChange(value)
  }

  return (
    <Flex direction={direction} data-testid="group-self-sign-up-controls">
      <Flex.Item padding="none medium none none">
        <Text>{I18n.t('Self Sign-Up')}</Text>
        <Tooltip renderTip={helpText} placement="top" on={['click', 'hover', 'focus']}>
          <IconButton
            color="primary"
            size="small"
            margin="none none xx-small none"
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Toggle Tooltip')}
          >
            <IconQuestionLine />
          </IconButton>
        </Tooltip>
      </Flex.Item>
      <Flex.Item shouldGrow={true}>
        <View display="block" padding="x-small x-small" data-testid="allow-self-signup-wrapper">
          <Checkbox
            checked={selfSignup}
            label={I18n.t('Allow self sign-up')}
            data-testid="checkbox-allow-self-signup"
            onChange={e => {
              handleChange('selfSignup', e.target.checked)
            }}
          />
        </View>
        <View display="block" padding="x-small x-small">
          <Checkbox
            checked={bySection && selfSignup}
            label={I18n.t('Require group members to be in the same section')}
            data-testid="checkbox-same-section"
            disabled={!selfSignup}
            onChange={e => {
              handleChange('bySection', e.target.checked)
            }}
          />
        </View>
        {selfSignup && selfSignupEndDateEnabled && (
          <View display="block" padding="x-small x-small">
            <SelfSignupEndDate onDateChange={handleEndDateUpdate} />
          </View>
        )}
      </Flex.Item>
    </Flex>
  )
}

SelfSignup.propTypes = {
  onChange: func.isRequired,
  selfSignupEndDateEnabled: bool,
  endDateOnChange: func,
  direction: string,
}

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

import $ from 'jquery'
import '@canvas/datetime/jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {InlineList} from '@instructure/ui-list'

const I18n = useI18nScope('course_settings')

const stateMap = {
  pending: I18n.t('Ready for sync'),
  scheduled: I18n.t('Sync auto-scheduled by enrollment changes'),
  manually_scheduled: I18n.t('Sync manually scheduled'),
  running: I18n.t('Sync currently running'),
  retrying: I18n.t('Sync currently running'),
  errored: I18n.t('The sync encountered an error and did not complete'),
  completed: I18n.t('Sync completed successfully'),
  deleted: I18n.t('Sync not enabled'),
}

const MicrosoftSync = ({group, loading, children}) => {
  if (loading) {
    return (
      <View as="div" textAlign="center">
        <Spinner renderTitle={I18n.t('Loading Microsoft sync data')} />
      </View>
    )
  }

  return (
    <>
      <Text>{I18n.t('Sync and Provision Microsoft Teams with your Canvas Course')}</Text>
      <br />
      <Text>
        {I18n.t(
          'Note: Syncing is triggered by changes to course enrollments. The first time you enable Microsoft Sync, you may have to trigger a sync manually with the button below.'
        )}
      </Text>
      <br />
      <Text>
        {I18n.t(
          'Also note that Microsoft Teams is unable to support courses with greater than %{max_enrollments} enrollments or greater than %{max_owners} owners. If your course exceeds these limits, sync will likely be interrupted.',
          {
            max_enrollments: ENV.MSFT_SYNC_MAX_ENROLLMENT_MEMBERS,
            max_owners: ENV.MSFT_SYNC_MAX_ENROLLMENT_OWNERS,
          }
        )}
      </Text>
      <Flex margin="small 0 0 0">
        <Flex.Item size="8rem" margin="0 medium 0 0">
          {children}
        </Flex.Item>
        <Flex.Item>
          <InlineList delimiter="pipe">
            <InlineList.Item>
              <Text weight="bold">Status:</Text>
              <Text fontStyle="italic"> {stateMap[group.workflow_state]}</Text>
            </InlineList.Item>
            <InlineList.Item>
              <Text weight="bold">{I18n.t('Last Sync:')}</Text>
              <Text fontStyle="italic">
                {' '}
                {$.datetimeString(group.last_synced_at) || I18n.t('never')}
              </Text>
            </InlineList.Item>
            {group.workflow_state !== 'errored' && (
              <InlineList.Item>{I18n.t('No errors')}</InlineList.Item>
            )}
          </InlineList>
        </Flex.Item>
      </Flex>
    </>
  )
}

export default MicrosoftSync

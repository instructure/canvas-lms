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
import '@canvas/datetime'
import I18n from 'i18n!course_settings'
import React from 'react'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const MicrosoftSync = ({enabled, group, loading, error}) => {
  if (loading) {
    return (
      <View as="div" textAlign="center">
        <Spinner renderTitle={I18n.t('Loading Microsoft sync data')} />
      </View>
    )
  }

  return (
    <>
      <Text>{I18n.t('Sync and Provision Microsoft Teams with you Canvas Course')}</Text>
      <Flex margin="small none none none">
        <Flex.Item>
          <Button
            withBackground={false}
            color="primary"
            margin="none small none none"
            interaction={enabled ? 'enabled' : 'disabled'}
          >
            {I18n.t('Sync Now')}
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Text fontStyle="italic">
            {I18n.t('Last Sync: %{lastSyncTime}', {
              lastSyncTime: $.datetimeString(group.last_synced_at)
            })}
          </Text>
        </Flex.Item>
      </Flex>
    </>
  )
}

export default MicrosoftSync

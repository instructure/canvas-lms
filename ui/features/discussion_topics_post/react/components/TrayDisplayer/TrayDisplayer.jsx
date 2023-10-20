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

import {useScope as useI18nScope} from '@canvas/i18n'

import PropTypes from 'prop-types'
import React from 'react'

import {CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Tray} from '@instructure/ui-tray'

const I18n = useI18nScope('discussion_posts')

export function TrayDisplayer({...props}) {
  return (
    <Tray open={props.isTrayOpen} size="large" placement="end" label={props.trayTitle}>
      <View as="div" padding="medium">
        <Flex direction="column">
          <Flex.Item>
            <CloseButton
              placement="end"
              offset="small"
              screenReaderLabel="Close"
              onClick={() => {
                props.setTrayOpen(false)
              }}
              data-testid="close-tray-button"
            />
          </Flex.Item>
          <Flex.Item padding="none none medium none" shouldGrow={true} shouldShrink={true}>
            <Text size="x-large" weight="bold">
              {I18n.t('%{title}', {title: props.trayTitle})}
            </Text>
          </Flex.Item>
          {props.trayComponent}
        </Flex>
      </View>
    </Tray>
  )
}

TrayDisplayer.propTypes = {
  setTrayOpen: PropTypes.func,
  trayTitle: PropTypes.string,
  trayComponent: PropTypes.any,
  isTrayOpen: PropTypes.bool,
}

export default TrayDisplayer

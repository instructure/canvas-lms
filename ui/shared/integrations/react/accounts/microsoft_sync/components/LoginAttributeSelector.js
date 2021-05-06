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
import I18n from 'i18n!account_settings_jsx_bundle'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Tooltip} from '@instructure/ui-overlays'
import {IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-elements'
import PropTypes from 'prop-types'
import {IconInfoLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y'

export default function LoginAttributeSelector(props) {
  return (
    <View as="div" margin="small 0 small 0" maxWidth="20rem">
      <Flex>
        <Flex.Item>
          <Heading level="h3">{I18n.t('Login Attribute')}</Heading>
        </Flex.Item>
        <Flex.Item>
          <Tooltip
            tip={I18n.t(
              'The attribute to use when associating a Canvas User with a Microsoft User'
            )}
            placement="start"
            on={['hover', 'focus']}
          >
            <IconButton
              renderIcon={IconInfoLine}
              withBackground={false}
              withBorder={false}
              screenReaderLabel={I18n.t(
                'Tooltip that contains info about the Microsoft Teams Sync Login Attribute.'
              )}
            />
          </Tooltip>
        </Flex.Item>
      </Flex>

      <SimpleSelect
        renderLabel={
          <ScreenReaderContent>{I18n.t('Login Attribute Selector')}</ScreenReaderContent>
        }
        onChange={props.attributeChangedHandler}
        value={props.selectedLoginAttribute}
        id="microsoft_teams_sync_attribute_selector"
      >
        <SimpleSelect.Option id="email" value="email">
          {I18n.t('Email')}
        </SimpleSelect.Option>
        <SimpleSelect.Option id="preferred_username" value="preferred_username">
          {I18n.t('Unique User ID')}
        </SimpleSelect.Option>
        <SimpleSelect.Option id="sis_user_id" value="sis_user_id">
          {I18n.t('SIS User ID')}
        </SimpleSelect.Option>
      </SimpleSelect>
    </View>
  )
}

LoginAttributeSelector.propTypes = {
  attributeChangedHandler: PropTypes.func,
  selectedLoginAttribute: PropTypes.string
}

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

import {IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-elements'
import {TextInput} from '@instructure/ui-forms'
import {IconInfoLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-layout'
import {View} from '@instructure/ui-view'
import {Tooltip} from '@instructure/ui-overlays'
import I18n from 'i18n!account_settings_jsx_bundle'
import PropTypes from 'prop-types'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y'

export default function TenantInput(props) {
  return (
    <View as="div" margin="small 0 small 0" maxWidth="20rem">
      <Flex>
        <Flex.Item>
          <Heading level="h3">{I18n.t('Tenant Name')}</Heading>
        </Flex.Item>
        <Flex.Item>
          <Tooltip tip={I18n.t('Your Azure Active Directory Tenant Name')} on={['hover', 'focus']}>
            <IconButton
              screenReaderLabel={I18n.t('Tooltip info for tenant input')}
              renderIcon={IconInfoLine}
              withBackground={false}
              withBorder={false}
            />
          </Tooltip>
        </Flex.Item>
      </Flex>
      <TextInput
        label={<ScreenReaderContent>{I18n.t('Tenant Name Input Area')}</ScreenReaderContent>}
        type="text"
        placeholder={I18n.t('microsoft_tenant_name%{domain}', {domain: '.onmicrosoft.com'})}
        onChange={props.tenantInputHandler}
        defaultValue={props.tenant}
        messages={props.messages}
      />
    </View>
  )
}

TenantInput.propTypes = {
  tenantInputHandler: PropTypes.func,
  tenant: PropTypes.string,
  messages: PropTypes.arrayOf(
    PropTypes.shape({
      text: PropTypes.string,
      type: PropTypes.oneOf(['error', 'hint', 'success', 'screenreader-only'])
    })
  )
}

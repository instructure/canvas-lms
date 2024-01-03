/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import * as React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {IconPlusLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {useDynamicRegistrationState} from './dynamic_registration/DynamicRegistrationState'

const I18n = useI18nScope('react_developer_keys')

const developerKeyMenuItem = (title: string, onClick: () => void) => {
  const buttonIdTitle = title.toLowerCase().replace(' ', '-')
  return (
    <Menu.Item onClick={onClick} type="button" id={`add-${buttonIdTitle}-button`}>
      <Flex>
        <Flex.Item padding="0 x-small 0 0" margin="0 0 xxx-small 0">
          <IconPlusLine />
        </Flex.Item>
        <Flex.Item>
          <ScreenReaderContent>{I18n.t('Create an')}</ScreenReaderContent>
          {title}
        </Flex.Item>
      </Flex>
    </Menu.Item>
  )
}

export type NewKeyButtonsProps = {
  triggerButton: React.ReactNode
  showCreateDeveloperKey: () => void
  showCreateLtiKey: () => void
}

export const NewKeyButtons = (props: NewKeyButtonsProps) => {
  const openDynRegModal = useDynamicRegistrationState(s => () => s.open(''))

  return (
    <Menu placement="bottom" trigger={props.triggerButton} shouldHideOnSelect={true}>
      {developerKeyMenuItem(I18n.t('API Key'), props.showCreateDeveloperKey)}
      {developerKeyMenuItem(I18n.t('LTI Key'), props.showCreateLtiKey)}
      {window.ENV.FEATURES.lti_dynamic_registration &&
        developerKeyMenuItem(I18n.t('LTI Registration'), openDynRegModal)}
    </Menu>
  )
}

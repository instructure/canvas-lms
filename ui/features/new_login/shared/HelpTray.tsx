/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import HelpDialog from '@canvas/help-dialog'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import React from 'react'
import {useHelpTray, useNewLoginData} from '../context'

const I18n = createI18nScope('new_login')

const HelpTray = () => {
  const {helpLink} = useNewLoginData()
  const {isHelpTrayOpen, closeHelpTray} = useHelpTray()

  const handleFormSubmit = () => {
    closeHelpTray()
  }

  return (
    <Tray
      label={I18n.t('%{helpLinkText} Menu', {helpLinkText: helpLink?.text})}
      onDismiss={closeHelpTray}
      open={isHelpTrayOpen}
      placement="start"
      shouldCloseOnDocumentClick={true}
      id="helpTray"
    >
      <View as="div" padding="medium">
        <Flex direction="column" gap="medium">
          <Flex alignItems="center" justifyItems="space-between">
            <Flex.Item>{helpLink?.text && <Heading>{helpLink.text}</Heading>}</Flex.Item>
            <Flex.Item>
              <CloseButton
                offset="medium"
                onClick={closeHelpTray}
                placement="end"
                screenReaderLabel={I18n.t('Close help tray.')}
              />
            </Flex.Item>
          </Flex>

          <HelpDialog onFormSubmit={handleFormSubmit} />
        </Flex>
      </View>
    </Tray>
  )
}

export default HelpTray

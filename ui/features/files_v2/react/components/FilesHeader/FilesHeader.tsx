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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'
import TopLevelButtons from './TopLevelButtons'

const I18n = createI18nScope('files_v2')

interface FilesHeaderProps {
  size: 'small' | 'medium' | 'large'
  isUserContext: boolean
  shouldHideUploadButtons?: boolean
}

const FilesHeader = ({size, isUserContext, shouldHideUploadButtons = false}: FilesHeaderProps) => {
  return (
    <Flex justifyItems="center" padding="medium none none none">
      <Flex.Item shouldShrink={true} shouldGrow={true} textAlign="center">
        <Flex
          wrap="wrap"
          margin="0 0 medium"
          justifyItems="space-between"
          direction={size === 'large' ? 'row' : 'column'}
        >
          <Flex.Item padding="small small small none" align="start">
            <Heading level="h1">{isUserContext ? I18n.t('All My Files') : I18n.t('Files')}</Heading>
          </Flex.Item>
          <Flex.Item
            padding="xx-small"
            direction={size === 'small' ? 'column' : 'row'}
            align={size === 'medium' ? 'start' : undefined}
            overflowX="hidden"
          >
            <TopLevelButtons
              size={size}
              isUserContext={isUserContext}
              shouldHideUploadButtons={shouldHideUploadButtons}
            />
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

export default FilesHeader

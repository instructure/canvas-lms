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
import {FileDrop} from '@instructure/ui-file-drop'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {IconUploadLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('files_v2')

interface SubTableContentProps {
  isLoading: boolean
  isEmpty: boolean
}

const SubTableContent = ({isLoading, isEmpty}: SubTableContentProps) => {
  return isLoading ? (
    <Flex as="div" alignItems="center" justifyItems="center" padding="medium">
      <Spinner renderTitle={I18n.t('Loading data')} />
    </Flex>
  ) : (
    <View as="div" padding="large none none none">
      {isEmpty && (
        <FileDrop
          renderLabel={
            <View as="div" padding="xx-large large" background="primary">
              <IconUploadLine size="large" />
              <Heading margin="medium 0 small 0">{I18n.t('Drag a file here, or')}</Heading>
              <Text color="brand">{I18n.t('Choose a file to upload')}</Text>
            </View>
          }
        />
      )}
    </View>
  )
}

export default SubTableContent

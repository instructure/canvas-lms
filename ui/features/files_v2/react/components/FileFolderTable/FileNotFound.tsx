/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {IconDocumentLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('files_v2')

export const FileNotFound = () => {
  return (
    <Flex height="100%" alignItems="center" justifyItems="center" id="file-not-found">
      <Flex.Item>
        <View
          as="div"
          display="inline-block"
          textAlign="center"
          margin="auto"
          padding="large"
          background="primary"
          borderRadius="medium"
        >
          <Flex direction="column" alignItems="center" gap="small">
            <Flex.Item>
              <IconDocumentLine size="medium" />
            </Flex.Item>
            <Flex.Item>
              <Text size="x-large" weight="bold">
                {I18n.t('File Not Found')}
              </Text>
            </Flex.Item>
            <Flex.Item>
              <Flex gap="small">
                <Flex.Item>
                  <View as="div" display="inline-block" maxWidth="350px">
                    <Text data-testid="file-not-found-message">
                      {I18n.t(
                        'The file you are looking for could not be found or you do not have permission to view it.',
                      )}
                    </Text>
                  </View>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </View>
      </Flex.Item>
    </Flex>
  )
}

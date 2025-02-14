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

import {Flex} from "@instructure/ui-flex";
import {View} from "@instructure/ui-view";
import {IconDownloadSolid, IconOffLine} from "@instructure/ui-icons";
import {Text} from "@instructure/ui-text";
import {formatFileSize} from "@canvas/util/fileHelper";
import {Button} from "@instructure/ui-buttons";
import {useScope as createI18nScope} from '@canvas/i18n'
import React from "react";
import type {File} from "../../../interfaces/File";

const I18n = createI18nScope('files_v2')

const NoFilePreviewAvailable = ({item}: {item: File }) => (
  <Flex height="100%" alignItems="center" justifyItems="center" id="file-preview">
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
            <IconOffLine size="medium" />
          </Flex.Item>
          <Flex.Item>
            <Text size="x-large" weight="bold">
              {I18n.t('No Preview Available')}
            </Text>
          </Flex.Item>
          <Flex.Item>
            <Flex gap="small">
              <Flex.Item>
                <Text>{item.display_name}</Text>
              </Flex.Item>
              {'size' in item && (
                <Flex.Item>
                  <Text color="secondary">{formatFileSize(item.size)}</Text>
                </Flex.Item>
              )}
            </Flex>
          </Flex.Item>
          <Flex.Item padding="x-small">
            <Button
              renderIcon={<IconDownloadSolid />}
              href={item.url}
              id="download-button"
            >
              {I18n.t('Download')}
            </Button>
          </Flex.Item>
        </Flex>
      </View>
    </Flex.Item>
  </Flex>
)

export default NoFilePreviewAvailable

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
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconDocumentLine,
  IconDownloadLine,
  IconTrashLine,
  IconMsWordLine,
  IconMsExcelLine,
  IconMsPptLine,
  IconPdfLine,
  IconTextLine,
} from '@instructure/ui-icons'
import {ContextFile} from './types'

const EXTENSION_ICONS: Record<string, React.ReactElement> = {
  docx: <IconMsWordLine size="x-small" />,
  xlsx: <IconMsExcelLine size="x-small" />,
  xls: <IconMsExcelLine size="x-small" />,
  pptx: <IconMsPptLine size="x-small" />,
  pdf: <IconPdfLine size="x-small" />,
  txt: <IconTextLine size="x-small" />,
  html: <IconDocumentLine size="x-small" />,
}

const getFileIcon = (displayName: string): React.ReactElement => {
  const ext = displayName.split('.').pop()?.toLowerCase() ?? ''
  return EXTENSION_ICONS[ext] ?? <IconDocumentLine size="x-small" />
}

const I18n = createI18nScope('canvas_file_upload')

interface ContextFilePillProps {
  file: ContextFile
  onRemove?: (id: string) => void
}

const ContextFilePill: React.FC<ContextFilePillProps> = ({file, onRemove}) => {
  return (
    <View
      as="div"
      borderWidth="small"
      borderRadius="large"
      padding="x-small small"
      background="primary"
    >
      <Flex alignItems="center" gap="x-small">
        <Flex.Item>{getFileIcon(file.display_name)}</Flex.Item>
        <Flex.Item>
          <Text size="small">{file.display_name}</Text>
        </Flex.Item>
        <Flex.Item>
          <IconButton
            href={file.url}
            data-testid={`download-file-${file.id}`}
            screenReaderLabel={I18n.t('Download %{name}', {name: file.display_name})}
            withBackground={false}
            withBorder={false}
            size="small"
          >
            <IconDownloadLine />
          </IconButton>
        </Flex.Item>
        {onRemove && (
          <Flex.Item>
            <IconButton
              data-testid={`remove-file-${file.id}`}
              screenReaderLabel={I18n.t('Remove %{name}', {name: file.display_name})}
              onClick={() => onRemove(file.id)}
              withBackground={false}
              withBorder={false}
              size="small"
              color="danger"
            >
              <IconTrashLine />
            </IconButton>
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}

export default ContextFilePill

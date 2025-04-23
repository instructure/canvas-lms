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

import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import React, {forwardRef, useRef} from 'react'

const I18n = createI18nScope('files_v2')

type ButtonRef = React.ComponentRef<typeof Button>

export interface FileInputButtonProps {
  onFileChange: (e: React.ChangeEvent<HTMLInputElement>) => void
}
export const FileInputButton = forwardRef<ButtonRef, FileInputButtonProps>(function FileInputButton(
  {onFileChange}: FileInputButtonProps,
  ref,
) {
  const fileInputRef = useRef<HTMLInputElement>(null)

  return (
    <>
      <input
        name="content"
        type="file"
        onChange={onFileChange}
        accept=".srt,.vtt"
        ref={fileInputRef}
        data-testid="file-input"
        hidden
      />
      <Flex gap="small">
        <Flex.Item>
          <Button size="small" onClick={() => fileInputRef.current?.click()} ref={ref}>
            {I18n.t('Choose File')}
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Text color="primary-inverse">{I18n.t('No File Chosen')}</Text>
        </Flex.Item>
      </Flex>
    </>
  )
})

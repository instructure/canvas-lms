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

import React, {useCallback} from 'react'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {FileDrop} from '@instructure/ui-file-drop'
import {Billboard} from '@instructure/ui-billboard'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {sharedHandleFileDrop} from '../../handlers/addItemHandlers'
import {RocketSVG} from '@instructure/canvas-media'
import {Action} from 'redux'

const I18n = createI18nScope('context_modules_v2')

const FILE_DROP_HEIGHT = '350px'

export interface ModuleFileDropProps {
  itemType: 'file' | 'folder' | string
  onChange: (field: string, value: any) => void
  dispatch?: React.Dispatch<Action>
  nameError?: string | null
  shouldAllowMultiple?: boolean
}

export const ModuleFileDrop: React.FC<ModuleFileDropProps> = ({
  itemType,
  onChange,
  dispatch,
  nameError,
  shouldAllowMultiple = true,
}) => {
  const handleDrop = useCallback(
    (
      accepted: ArrayLike<File | DataTransferItem>,
      _rejected: ArrayLike<File | DataTransferItem>,
      _e: React.DragEvent,
    ) => {
      sharedHandleFileDrop(accepted, {onChange, dispatch})
    },
    [onChange, dispatch],
  )

  if (itemType !== 'file') {
    return null
  }

  return (
    <View as="div" padding="small" display="block">
      <form data-testid="module-file-drop">
        <FileDrop
          height={FILE_DROP_HEIGHT}
          shouldAllowMultiple={shouldAllowMultiple}
          onDrop={handleDrop}
          messages={nameError ? [{text: nameError, type: 'newError'}] : []}
          renderLabel={
            <Flex direction="column" height="100%" alignItems="center" justifyItems="center">
              <Billboard
                size="small"
                hero={<RocketSVG width="3em" height="3em" />}
                as="div"
                headingAs="span"
                headingLevel="h2"
                heading={I18n.t('Drop files here to upload')}
                message={<Text color="brand">{I18n.t('or choose files')}</Text>}
              />
            </Flex>
          }
        />
      </form>
    </View>
  )
}

export default ModuleFileDrop

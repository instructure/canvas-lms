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

import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconEyeLine} from '@instructure/ui-icons'
import {useBlockContentEditorContext} from '../BlockContentEditorContext'

const I18n = createI18nScope('block_content_editor')

const PreviewButton = (props: {
  active: boolean
  onClick: () => void
}) => {
  return (
    <IconButton
      screenReaderLabel={I18n.t('preview')}
      color={props.active ? 'primary' : 'secondary'}
      renderIcon={<IconEyeLine />}
      onClick={props.onClick}
    />
  )
}

export const Toolbar = () => {
  const {
    editor: {mode, setMode},
  } = useBlockContentEditorContext()
  const isPreviewMode = mode === 'preview'

  return (
    <Flex direction="row">
      <PreviewButton
        active={isPreviewMode}
        onClick={() => setMode(isPreviewMode ? 'default' : 'preview')}
      />
    </Flex>
  )
}

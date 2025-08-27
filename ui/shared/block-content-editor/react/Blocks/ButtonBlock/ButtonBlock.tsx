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

import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {BaseBlockHOC} from '../BaseBlock'
import {ButtonBlockSettings} from './ButtonBlockSettings'
import {useSave2} from '../BaseBlock/useSave'
import {ButtonBlockProps} from './types'
import {Flex} from '@instructure/ui-flex'
import {TitleView} from '../BlockItems/Title/TitleView'
import {ButtonDisplay} from './ButtonDisplay'
import {TitleEditPreview} from '../BlockItems/Title/TitleEditPreview'
import {useFocusElement} from '../../hooks/useFocusElement'
import {TitleEdit} from '../BlockItems/Title/TitleEdit'

const I18n = createI18nScope('block_content_editor')

const ButtonBlockView = (props: ButtonBlockProps) => {
  return (
    <Flex direction="column" gap="mediumSmall">
      {props.settings.includeBlockTitle && (
        <TitleView title={props.title} contentColor={props.settings.textColor} />
      )}
      <ButtonDisplay dataTestId="button-block-view" settings={props.settings} />
    </Flex>
  )
}

const ButtonBlockEditView = (props: ButtonBlockProps) => {
  return (
    <Flex direction="column" gap="mediumSmall">
      {props.settings.includeBlockTitle && (
        <TitleEditPreview title={props.title} contentColor={props.settings.textColor} />
      )}
      <ButtonDisplay
        dataTestId="button-block-edit-preview"
        settings={props.settings}
        onButtonClick={() => {}}
      />
    </Flex>
  )
}

const ButtonBlockEdit = (props: ButtonBlockProps) => {
  const [title, setTitle] = useState(props.title)

  const {focusHandler} = useFocusElement()
  useSave2(() => ({title}))

  return (
    <Flex direction="column" gap="mediumSmall">
      {props.settings.includeBlockTitle && (
        <TitleEdit title={title} onTitleChange={setTitle} focusHandler={focusHandler} />
      )}
      <ButtonDisplay
        dataTestId="button-block-edit"
        settings={props.settings}
        focusHandler={props.settings.includeBlockTitle ? undefined : focusHandler}
        onButtonClick={() => {}}
      />
    </Flex>
  )
}

export const ButtonBlock = (props: ButtonBlockProps) => {
  return (
    <BaseBlockHOC
      ViewComponent={ButtonBlockView}
      EditComponent={ButtonBlockEdit}
      EditViewComponent={ButtonBlockEditView}
      componentProps={props}
      title={ButtonBlock.craft.displayName}
      backgroundColor={props.settings.backgroundColor}
    />
  )
}

ButtonBlock.craft = {
  displayName: I18n.t('Button') as string,
  related: {
    settings: ButtonBlockSettings,
  },
}

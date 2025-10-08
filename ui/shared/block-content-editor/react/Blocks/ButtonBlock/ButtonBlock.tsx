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
import {BaseBlock} from '../BaseBlock'
import {ButtonBlockSettings} from './ButtonBlockSettings'
import {useSave} from '../BaseBlock/useSave'
import {ButtonBlockProps} from './types'
import {Flex} from '@instructure/ui-flex'
import {TitleView} from '../BlockItems/Title/TitleView'
import {ButtonBlockLayout} from './ButtonBlockLayout'
import {ButtonView, ButtonEdit, ButtonEditView} from '../BlockItems/Button'
import {TitleEditPreview} from '../BlockItems/Title/TitleEditPreview'
import {useFocusElement} from '../../hooks/useFocusElement'
import {TitleEdit} from '../BlockItems/Title/TitleEdit'
import {defaultProps} from './defaultProps'
import {buttonBackgroundContrast} from '../../accessibilityChecker/rules/buttonBackgroundContrast'
import {getContrastingTextColorCached} from '../../utilities/getContrastingTextColor'

const I18n = createI18nScope('block_content_editor')

const ButtonBlockView = (props: ButtonBlockProps) => {
  return (
    <Flex direction="column" gap="mediumSmall">
      {props.includeBlockTitle && !!props.title && (
        <TitleView title={props.title} contentColor={props.titleColor} />
      )}
      <ButtonBlockLayout dataTestId="button-block-view" {...props} ButtonComponent={ButtonView} />
    </Flex>
  )
}

const ButtonBlockEditView = (props: ButtonBlockProps) => {
  return (
    <Flex direction="column" gap="mediumSmall">
      {props.includeBlockTitle && (
        <TitleEditPreview title={props.title} contentColor={props.titleColor} />
      )}
      <ButtonBlockLayout
        dataTestId="button-block-edit-preview"
        {...props}
        ButtonComponent={ButtonEditView}
      />
    </Flex>
  )
}

const ButtonBlockEdit = (props: ButtonBlockProps) => {
  const [title, setTitle] = useState(props.title)
  const labelColor = getContrastingTextColorCached(props.backgroundColor)

  const {focusHandler} = useFocusElement()
  useSave(() => ({title}))

  return (
    <Flex direction="column" gap="mediumSmall">
      {props.includeBlockTitle && (
        <TitleEdit
          title={title}
          onTitleChange={setTitle}
          focusHandler={focusHandler}
          labelColor={labelColor}
        />
      )}
      <ButtonBlockLayout
        dataTestId="button-block-edit"
        {...props}
        focusHandler={props.includeBlockTitle ? undefined : focusHandler}
        ButtonComponent={ButtonEdit}
      />
    </Flex>
  )
}

export const ButtonBlock = (props: Partial<ButtonBlockProps>) => {
  const componentProps = {...defaultProps, ...props}
  return (
    <BaseBlock
      ViewComponent={ButtonBlockView}
      EditComponent={ButtonBlockEdit}
      EditViewComponent={ButtonBlockEditView}
      componentProps={componentProps}
      title={ButtonBlock.craft.displayName}
      backgroundColor={componentProps.backgroundColor}
      customAccessibilityCheckRules={[buttonBackgroundContrast]}
    />
  )
}

ButtonBlock.craft = {
  displayName: I18n.t('Button') as string,
  related: {
    settings: ButtonBlockSettings,
  },
}

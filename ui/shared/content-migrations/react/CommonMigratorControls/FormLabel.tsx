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

import React, {type ReactNode} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('app_shared_components')

type FormLabelProps = {
  children?: ReactNode
  htmlFor?: string
}

type RequiredFormLabelProps = {
  showErrorState: boolean
  children?: ReactNode
  htmlFor?: string
}

export const FormLabel = ({children, htmlFor}: FormLabelProps) => {
  return (
    <label htmlFor={htmlFor}>
      <Text weight="bold">
        {children}
      </Text>
    </label>
  )
}

export const RequiredFormLabel = ({children, showErrorState, htmlFor}: RequiredFormLabelProps) => {
  return (
    <FormLabel htmlFor={htmlFor}>
      {children}
      <Text color={showErrorState ? 'danger' : 'primary'}>
        <span aria-hidden={true}> *</span>
        <ScreenReaderContent>{I18n.t('Required')}</ScreenReaderContent>
      </Text>
    </FormLabel>
  )
}

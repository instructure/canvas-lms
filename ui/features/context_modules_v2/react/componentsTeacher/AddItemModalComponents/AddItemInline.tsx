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
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useAddItemInline} from '../../hooks/mutations/useAddItemInline'
import ModuleFileDrop from './ModuleFileDrop'
const I18n = createI18nScope('context_modules_v2')

interface AddItemInlineProps {
  moduleId: string
  itemCount: number
}

const AddItemInline: React.FC<AddItemInlineProps> = ({moduleId, itemCount}) => {
  const {handleSubmit, isLoading} = useAddItemInline({
    moduleId,
    itemCount,
  })

  return isLoading && itemCount === 0 ? (
    <View as="div" textAlign="center" padding="medium">
      <Spinner renderTitle={I18n.t('Loading module items')} size="small" />
    </View>
  ) : (
    <ModuleFileDrop
      itemType="file"
      onChange={(field, value) => {
        const handlers = {
          file: handleSubmit,
        }
        handlers[field as keyof typeof handlers]?.(value)
      }}
    />
  )
}

export default AddItemInline

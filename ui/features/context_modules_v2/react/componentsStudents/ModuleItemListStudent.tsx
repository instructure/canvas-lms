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

import React, {memo} from 'react'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import ModuleItemStudent from './ModuleItemStudent'
import {useScope as createI18nScope} from '@canvas/i18n'
import {validateModuleItemStudentRenderRequirements} from '../utils/utils'
import type {CompletionRequirement, ModuleItem, ModuleProgression} from '../utils/types'

const I18n = createI18nScope('context_modules_v2')

const MemoizedModuleItemStudent = memo(
  ModuleItemStudent,
  validateModuleItemStudentRenderRequirements,
)

export interface ModuleItemListStudentProps {
  moduleItems: ModuleItem[]
  completionRequirements?: CompletionRequirement[]
  requireSequentialProgress?: boolean
  progression?: ModuleProgression
  isLoading: boolean
  error: any
}

const ModuleItemListStudent: React.FC<ModuleItemListStudentProps> = ({
  moduleItems,
  completionRequirements,
  requireSequentialProgress,
  progression,
  isLoading,
  error,
}) => {
  return (
    <View as="div" overflowX="hidden">
      {isLoading ? (
        <View as="div" textAlign="center" padding="medium">
          <Spinner renderTitle={I18n.t('Loading module items')} size="small" />
        </View>
      ) : error ? (
        <View as="div" textAlign="center" padding="medium">
          <Text color="danger">{I18n.t('Error loading module items')}</Text>
        </View>
      ) : moduleItems.length === 0 ? (
        <View as="div" textAlign="center" padding="medium">
          <Text>{I18n.t('No items in this module')}</Text>
        </View>
      ) : (
        moduleItems.map((item, index) => (
          <View as="div" key={item._id}>
            <MemoizedModuleItemStudent
              {...item}
              index={index}
              completionRequirements={completionRequirements}
              requireSequentialProgress={!!requireSequentialProgress}
              progression={progression}
            />
          </View>
        ))
      )}
    </View>
  )
}

export default ModuleItemListStudent

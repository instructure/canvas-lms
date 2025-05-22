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
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {IconGroupLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useContextModule} from '../../hooks/useModuleContext'
import {Prerequisite} from '../../utils/types'
import {handleOpeningModuleUpdateTray} from '../../handlers/modulePageActionHandlers'
import {useModuleItems} from '../../hooks/queries/useModuleItems'
import {useModules} from '../../hooks/queries/useModules'

const I18n = createI18nScope('context_modules_v2')

export interface ViewAssignToProps {
  moduleId: string
  moduleName: string
  expanded: boolean
  isMenuOpen: boolean
  prerequisites?: Prerequisite[]
}

const ViewAssignTo: React.FC<ViewAssignToProps> = ({
  moduleId,
  moduleName,
  expanded,
  isMenuOpen,
  prerequisites,
}) => {
  const {courseId} = useContextModule()
  const {data} = useModules(courseId)
  const {data: moduleItems, isLoading: isModuleItemsLoading} = useModuleItems(
    moduleId,
    expanded || isMenuOpen,
  )

  const handleOpenRef = useCallback(() => {
    handleOpeningModuleUpdateTray(
      data,
      courseId,
      moduleId,
      moduleName,
      prerequisites,
      'assign-to',
      moduleItems?.moduleItems,
    )
  }, [data, courseId, moduleId, moduleName, prerequisites, moduleItems])

  return (
    <View>
      <Flex justifyItems="end" alignItems="center" margin="xx-small none none">
        <Flex alignItems="center" gap="x-small">
          <IconGroupLine inline />
          <Link onClick={handleOpenRef} isWithinText={false} disabled={isModuleItemsLoading}>
            {I18n.t('View Assign To')}
          </Link>
        </Flex>
      </Flex>
    </View>
  )
}

export default ViewAssignTo

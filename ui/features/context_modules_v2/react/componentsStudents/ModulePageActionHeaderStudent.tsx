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

import React, { useCallback } from 'react'
import { View } from '@instructure/ui-view'
import { Button } from '@instructure/ui-buttons'
import { Flex } from '@instructure/ui-flex'
import {
  IconCollapseLine,
  IconExpandLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules_v2')

interface ModulePageActionHeaderStudentProps {
  onCollapseAll: () => void
  onExpandAll: () => void
  anyModuleExpanded?: boolean
}

const ModulePageActionHeaderStudent: React.FC<ModulePageActionHeaderStudentProps> = ({
  onCollapseAll,
  onExpandAll,
  anyModuleExpanded = true,
}) => {
  const handleCollapseExpandClick = useCallback(() => {
    if (anyModuleExpanded) {
      onCollapseAll()
    } else {
      onExpandAll()
    }
  }, [anyModuleExpanded, onCollapseAll, onExpandAll])

  return (
    <View as="div" padding="small">
      <Flex justifyItems="space-between" gap="small">
        <Flex.Item>
          <Button
            renderIcon={anyModuleExpanded ? <IconCollapseLine /> : <IconExpandLine />}
            onClick={handleCollapseExpandClick}
          >
            {anyModuleExpanded ? I18n.t('Collapse All') : I18n.t('Expand All')}
          </Button>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default ModulePageActionHeaderStudent

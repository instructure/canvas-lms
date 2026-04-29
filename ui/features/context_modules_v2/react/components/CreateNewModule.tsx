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

import {IconModuleSolid} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {handleAddModule} from '../handlers/moduleActionHandlers'
import {View} from '@instructure/ui-view'
import {InfiniteData} from '@tanstack/react-query'
import {ModulesResponse} from '../utils/types'

const I18n = createI18nScope('context_modules_v2')

interface CreateNewModuleProps {
  courseId: string
  data: InfiniteData<ModulesResponse, unknown>
}

const CreateNewModule: React.FC<CreateNewModuleProps> = ({courseId, data}) => {
  return (
    <View as="div" textAlign="center" padding="large">
      <ul className="ic-EmptyStateList">
        <li className="ic-EmptyStateList__Item">
          <div className="ic-EmptyStateList__BillboardWrapper">
            <button
              type="button"
              className="ic-EmptyStateButton"
              onClick={() => handleAddModule(courseId, data)}
            >
              <IconModuleSolid className="ic-EmptyStateButton__SVG" />
              <span className="ic-EmptyStateButton__Text">{I18n.t('Create a new Module')}</span>
            </button>
          </div>
        </li>
      </ul>
    </View>
  )
}

export default CreateNewModule

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

import React from 'react'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {NoResultsFound} from './NoResultsFound'

const I18n = createI18nScope('files_v2')

interface SubTableContentProps {
  isLoading: boolean
  isEmpty: boolean
  searchString: string
}

const SubTableContent = ({isLoading, isEmpty, searchString}: SubTableContentProps) => {
  if (isLoading) {
    return (
      <Flex as="div" alignItems="center" justifyItems="center" padding="medium">
        <Spinner renderTitle={I18n.t('Loading data')} />
      </Flex>
    )
  }

  if (isEmpty && searchString) {
    return (
      <View as="div" padding="medium 0 0 0">
        <NoResultsFound searchTerm={searchString} />
      </View>
    )
  }
}

export default SubTableContent

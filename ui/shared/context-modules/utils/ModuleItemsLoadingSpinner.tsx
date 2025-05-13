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
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modulespublic')

type ModuleItemsLoadingProps = {
  isLoading: boolean
}

export const ModuleItemsLoadingSpinner = ({isLoading}: ModuleItemsLoadingProps) => {
  if (!isLoading) return null
  return (
    <View
      as="div"
      textAlign="center"
      minHeight="3em"
      minWidth="3em"
      className="module-spinner-container"
    >
      <Alert
        variant="info"
        screenReaderOnly={true}
        liveRegion={() => document.querySelector('#flash_screenreader_holder') as HTMLElement}
      >
        {I18n.t('Loading items')}
      </Alert>
      <Spinner size="small" renderTitle={I18n.t('Loading items')} />
    </View>
  )
}

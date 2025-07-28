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

import {useContext, useMemo} from 'react'
import {HorizonToggleContext} from '../HorizonToggleContext'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {ContentItems} from './ContentItems'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('horizon_toggle_page')

export const ContentPublished = () => {
  const data = useContext(HorizonToggleContext)
  const publishedContent = data?.errors?.assignments?.filter(item => item.errors.workflow_state)
  if (!publishedContent || publishedContent.length === 0) {
    return null
  }
  return (
    <View as="div">
      <Heading level="h3">{I18n.t('Published Content')}</Heading>
      <Text as="p">
        {I18n.t(
          `Published content that isn't part of a module will be automatically unpublished. You'll have the option to publish this content once it's added to a module.`,
        )}
      </Text>
      <ContentItems
        label={I18n.t(
          {
            one: 'Content to be Unpublished (%{count} item)',
            other: 'Content to be Unpublished (%{count} items)',
          },
          {count: publishedContent.length},
        )}
        screenReaderLabel={I18n.t('Content to be Unpublished')}
        contents={publishedContent}
      />
    </View>
  )
}

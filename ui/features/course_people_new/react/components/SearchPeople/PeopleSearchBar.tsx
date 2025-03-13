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

import React, {type FC} from 'react'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {IconButton} from '@instructure/ui-buttons'
import {Alert} from '@instructure/ui-alerts'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getLiveRegion} from '../../../util/utils'

const I18n = createI18nScope('course_people')

export type PeopleSearchBarType = {
  searchTerm: string
  numberOfResults: number
  isLoading: boolean
  onChangeHandler: (event: React.ChangeEvent<HTMLInputElement>) => void
  onClearHandler: () => void
}

const PeopleSearchBar: FC<PeopleSearchBarType> = ({
  searchTerm,
  numberOfResults,
  isLoading,
  onChangeHandler,
  onClearHandler,
}) => (
  <>
    <View as="div" position="relative">
      <TextInput
        type="search"
        size="medium"
        placeholder={I18n.t('Search people...')}
        value={searchTerm}
        renderLabel={
          <ScreenReaderContent>
            {I18n.t('Search people')}
          </ScreenReaderContent>
        }
        onChange={onChangeHandler}
        interaction={'enabled'}
        renderBeforeInput={<IconSearchLine inline={false} data-testid="search-icon"/>}
        renderAfterInput={
          searchTerm.length > 0
            ? (
                <IconButton
                  type="button"
                  size="small"
                  withBackground={false}
                  withBorder={false}
                  screenReaderLabel={I18n.t('Clear search')}
                  onClick={onClearHandler}
                  data-testid="clear-search-icon"
                >
                  <IconTroubleLine />
                </IconButton>
              )
            : null
        }
        shouldNotWrap
      />
    </View>
    {!isLoading && (
      <Alert
        liveRegion={getLiveRegion}
        liveRegionPoliteness="polite"
        screenReaderOnly
      >
        {I18n.t(
          {
            zero: 'No people found',
            one: '1 person found',
            other: '%{count} people found',
          },
          {
            count: numberOfResults,
          },
        )}
      </Alert>
    )}
  </>
)

export default PeopleSearchBar

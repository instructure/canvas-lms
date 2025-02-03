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
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconEndSolid, IconFilterLine, IconSearchLine} from '@instructure/ui-icons'
import useDebouncedSearch from '../../hooks/useDebouncedSearch'
import useDiscoverQueryParams from '../../hooks/useDiscoverQueryParams'
import useBreakpoints from '../../hooks/useBreakpoints'
import {instructorAppsHash, instructorAppsRoute} from '../../utils/routes'

const I18n = createI18nScope('lti_registrations')

export const SearchAndFilter = (props: {setIsTrayOpen: (isOpen: boolean) => void}) => {
  const disableQueryParams =
    window.location.href.includes(instructorAppsRoute) &&
    window.location.hash !== instructorAppsHash
  const {queryParams, updateQueryParams} = useDiscoverQueryParams()
  const {searchValue, handleSearchInputChange} = useDebouncedSearch({
    initialValue: queryParams.search,
    delay: 300,
    updateQueryParams,
    isDisabled: disableQueryParams,
  })
  const {isMaxMobile} = useBreakpoints()

  return (
    <Flex gap="small" margin="0 0 small 0" direction={isMaxMobile ? 'column-reverse' : 'row'}>
      <Flex.Item shouldGrow={true} overflowY="visible">
        <View as="div">
          <TextInput
            renderLabel={
              <ScreenReaderContent>{I18n.t('Search by app or company name')}</ScreenReaderContent>
            }
            placeholder="Search by app or company name"
            value={searchValue}
            onChange={handleSearchInputChange}
            renderBeforeInput={<IconSearchLine inline={false} />}
            renderAfterInput={
              queryParams.search ? (
                <IconButton
                  size="small"
                  screenReaderLabel={I18n.t('Clear search field')}
                  withBackground={false}
                  withBorder={false}
                  onClick={() => updateQueryParams({search: ''})}
                >
                  <IconEndSolid size="x-small" data-testid="clear-search-icon" />
                </IconButton>
              ) : null
            }
            shouldNotWrap={true}
          />
        </View>
      </Flex.Item>
      <Button
        id="apply_filter" // EVAL-4232
        data-testid="apply-filters-button"
        renderIcon={() => <IconFilterLine />}
        onClick={() => props.setIsTrayOpen(true)}
      >
        {I18n.t('Filters')}
      </Button>
    </Flex>
  )
}

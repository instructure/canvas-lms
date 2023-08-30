// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {connect} from 'react-redux'
import {useScope as useI18nScope} from '@canvas/i18n'
import {paceContextsActions} from '../actions/pace_contexts'

import {Flex} from '@instructure/ui-flex'
import {Button, IconButton} from '@instructure/ui-buttons'
import {APIPaceContextTypes, OrderType, SortableColumn, StoreState} from '../types'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {getSearchTerm} from '../reducers/course_paces'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('course_paces_search')

interface StoreProps {
  readonly searchTerm: string
  readonly currentSortBy: SortableColumn
  readonly currentOrderType: OrderType
}

interface DispatchProps {
  fetchPaceContexts: typeof paceContextsActions.fetchPaceContexts
  setSearchTerm: typeof paceContextsActions.setSearchTerm
}

export interface PassedProps {
  readonly contextType: APIPaceContextTypes
}

type ComponentProps = StoreProps & DispatchProps & PassedProps

export const Search = ({
  searchTerm,
  fetchPaceContexts,
  setSearchTerm,
  contextType,
  currentOrderType,
  currentSortBy,
}: ComponentProps) => {
  const handleClear = e => {
    e.stopPropagation()
    setSearchTerm('')
    fetchPaceContexts({contextType, page: 1, searchTerm: ''})
  }

  const handleSearch = e => {
    e.preventDefault()

    fetchPaceContexts({
      contextType,
      page: 1,
      searchTerm,
      sortBy: currentSortBy,
      orderType: currentOrderType,
      afterFetch: contexts =>
        showFlashAlert({
          message: I18n.t(
            {
              zero: 'No results found',
              one: 'Showing 1 result below',
              other: 'Showing %{count} results below',
            },
            {count: contexts.length}
          ),
          srOnly: true,
          err: null,
        }),
    })
  }

  const renderClearButton = () => {
    if (!searchTerm.length) return

    return (
      <IconButton
        type="button"
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel={I18n.t('Clear search')}
        onClick={handleClear}
      >
        <IconTroubleLine />
      </IconButton>
    )
  }

  const placeholderText = () => {
    if (contextType === 'section') {
      return I18n.t('Search for sections')
    } else if (contextType === 'student_enrollment') {
      return I18n.t('Search for students')
    }
  }

  return (
    <View as="div" padding="none">
      <form
        name="activatedSearchExample"
        onSubmit={handleSearch}
        style={{marginBottom: '0'}}
        autoComplete="off"
      >
        <Flex>
          <Flex.Item shouldGrow={true}>
            <TextInput
              renderLabel={<ScreenReaderContent>{placeholderText()}</ScreenReaderContent>}
              placeholder={placeholderText()}
              value={searchTerm}
              onChange={(_event, value) => {
                setSearchTerm(value)
              }}
              renderBeforeInput={<IconSearchLine inline={false} />}
              renderAfterInput={renderClearButton()}
              data-testid="search-input"
            />
          </Flex.Item>
          <Flex.Item>
            <Button
              color="primary"
              margin="0 0 0 small"
              onClick={handleSearch}
              data-testid="search-button"
            >
              {I18n.t('Search')}
            </Button>
          </Flex.Item>
        </Flex>
      </form>
    </View>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    searchTerm: getSearchTerm(state),
    currentSortBy: state.paceContexts.sortBy,
    currentOrderType: state.paceContexts.order,
  }
}

export default connect(mapStateToProps, {
  fetchPaceContexts: paceContextsActions.fetchPaceContexts,
  setSearchTerm: paceContextsActions.setSearchTerm,
})(Search)

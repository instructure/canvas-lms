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

import React, {useEffect, useRef, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Tray} from '@instructure/ui-tray'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import type {FilterItem, LtiFilter} from '../model/Filter'
import FilterOptions from './FilterOptions'
import {View} from '@instructure/ui-view'
import type {DiscoverParams} from './useDiscoverQueryParams'

const I18n = useI18nScope('lti_registrations')

export type LtiFilterTrayProps = {
  isTrayOpen: boolean
  setIsTrayOpen: (isOpen: boolean) => void
  filterValues: LtiFilter
  setQueryParams: (params: Partial<DiscoverParams>) => void
  queryParams: DiscoverParams
}

export default function LtiFilterTray({
  isTrayOpen,
  setIsTrayOpen,
  filterValues,
  setQueryParams,
  queryParams,
}: LtiFilterTrayProps) {
  const closeRef = useRef<HTMLElement>()
  // Need to duplicate for the apply button's behaviour
  const [localFilters, setLocalFilters] = useState<LtiFilter>({})

  const setFilterValue = (filterItem: FilterItem, value: boolean, category: string) => {
    if (value) {
      setLocalFilters(prev => {
        return {
          ...prev,
          [category]: prev[category] ? [...prev[category], filterItem] : [filterItem],
        }
      })
    } else {
      setLocalFilters(prev => {
        return {...prev, [category]: prev[category].filter(filter => filter.id !== filterItem.id)}
      })
    }
  }

  const applyFilters = () => {
    setQueryParams({filters: localFilters})
    setIsTrayOpen(false)
  }

  const resetFilterValues = () => {
    setLocalFilters({})
    setQueryParams({search: queryParams.search})
  }

  const cancelClick = () => {
    setLocalFilters(queryParams.filters)
    setIsTrayOpen(false)
  }

  useEffect(() => {
    if (isTrayOpen) {
      setLocalFilters(queryParams.filters)
    }
  }, [isTrayOpen, queryParams])

  return (
    <Tray
      placement="end"
      label="Tray Example"
      open={isTrayOpen}
      onDismiss={() => {
        setIsTrayOpen(false)
      }}
      shouldCloseOnDocumentClick={true}
    >
      <Flex direction="column" height="100vh">
        <Flex.Item padding="medium">
          <Flex>
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <Heading level="h3" as="h1">
                {I18n.t('Filter')}
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                elementRef={ref => {
                  if (ref instanceof HTMLElement) {
                    closeRef.current = ref
                  }
                }}
                screenReaderLabel="Close"
                onClick={() => {
                  setIsTrayOpen(false)
                }}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item padding="0 medium" shouldGrow={true} shouldShrink={true}>
          {Object.keys(filterValues).map(category => {
            return (
              <FilterOptions
                key={category}
                categoryName={category}
                options={filterValues[category]}
                filterIds={!!localFilters[category] && localFilters[category].map(f => f.id)}
                setFilterValue={(filterItem: FilterItem, value: boolean) =>
                  setFilterValue(filterItem, value, category)
                }
                limit={category === 'companies' ? 10 : undefined}
              />
            )
          })}
        </Flex.Item>

        <View background="secondary" borderWidth="small none none none" padding="small">
          <Flex>
            <Flex.Item shouldGrow={true}>
              <Button onClick={() => resetFilterValues()}> {I18n.t('Reset')}</Button>
            </Flex.Item>
            <Flex.Item>
              <Button onClick={() => cancelClick()}>{I18n.t('Cancel')}</Button>
            </Flex.Item>
            <Flex.Item margin="0 0 0 x-small">
              <Button color="primary" onClick={() => applyFilters()}>
                {I18n.t('Apply')}
              </Button>
            </Flex.Item>
          </Flex>
        </View>
      </Flex>
    </Tray>
  )
}

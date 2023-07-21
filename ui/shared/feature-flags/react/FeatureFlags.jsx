/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useEffect, useState} from 'react'
import {debounce, groupBy} from 'lodash'

import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {IconSearchLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'

import useFetchApi from '@canvas/use-fetch-api-hook'
import FeatureFlagTable from './FeatureFlagTable'
import * as flagUtils from './util'

const I18n = useI18nScope('feature_flags')

const SEARCH_DELAY = 350

export default function FeatureFlags({hiddenFlags, disableDefaults}) {
  const [isLoading, setLoading] = useState(false)
  const [features, setFeatures] = useState([])
  const [groupedFeatures, setGroupedFeatures] = useState()
  const [searchInput, setSearchInput] = useState('')
  const [searchQuery, setSearchQuery] = useState('')
  const [stateFilter, setStateFilter] = useState('all')

  useFetchApi({
    success: setFeatures,
    loading: setLoading,
    path: `/api/v1${ENV.CONTEXT_BASE_URL}/features`,
    fetchAllPages: true,
    params: {
      hide_inherited_enabled: true,
      per_page: 50,
    },
  })

  const filterableStateOf = x => (x.state === 'hidden' ? 'off' : x.state)
  function matchesState(flag) {
    if (stateFilter === 'all') {
      return true
    }
    const transitions = flagUtils.buildTransitions(
      flag,
      flagUtils.doesAllowDefaults(flag, disableDefaults)
    )
    if (stateFilter === 'enabled') {
      return [transitions.enabled, 'allowed_on'].includes(filterableStateOf(flag))
    } else {
      return [transitions.disabled, 'allowed'].includes(filterableStateOf(flag))
    }
  }

  const containsSearchQuery = value => value.toLowerCase().includes(searchQuery.toLowerCase())
  const matchesFilters = feature =>
    (containsSearchQuery(feature.feature) || containsSearchQuery(feature.display_name)) &&
    matchesState(feature.feature_flag)

  useEffect(() => {
    const groupings = groupBy(
      features.filter(
        feat => (!hiddenFlags || !hiddenFlags.includes(feat.feature)) && matchesFilters(feat)
      ),
      'applies_to'
    )

    if (groupings.Account || groupings.RootAccount) {
      groupings.Account = (groupings.Account || []).concat(groupings.RootAccount || [])
    }

    setGroupedFeatures(groupings)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hiddenFlags, disableDefaults, features, searchQuery, stateFilter])

  const categories = [
    {
      id: 'SiteAdmin',
      title: I18n.t('Site Admin'),
    },
    {
      id: 'Account',
      title: I18n.t('Account'),
    },
    {
      id: 'Course',
      title: I18n.t('Course'),
    },
    {
      id: 'User',
      title: I18n.t('User'),
    },
  ]

  const updateSearchQuery = debounce(setSearchQuery, SEARCH_DELAY, {
    leading: false,
    trailing: true,
  })

  const acceptSearchInput = (_e, val) => {
    setSearchInput(val)
    if (val !== searchInput && val.length > 2) {
      updateSearchQuery(val)
    } else if (val.length === 0) {
      updateSearchQuery('')
    }
  }

  const updateStateFilter = (_e, val) => setStateFilter(val.value)

  const clearFilters = () => {
    setSearchQuery('')
    setSearchInput('')
    setStateFilter('all')
  }

  return (
    <View as="div">
      {isLoading ? (
        <Spinner renderTitle={I18n.t('Loading feature options')} />
      ) : (
        <>
          <Flex justifyItems="start">
            <Flex.Item padding="small">
              <SimpleSelect
                assistiveText={I18n.t('Use arrow keys to navigate options.')}
                renderLabel={<ScreenReaderContent>{I18n.t('Filter by')}</ScreenReaderContent>}
                onChange={updateStateFilter}
                width="10rem"
                value={stateFilter}
              >
                <SimpleSelect.Option id="All" value="all">
                  {I18n.t('All')}
                </SimpleSelect.Option>
                <SimpleSelect.Option id="Enabled" value="enabled">
                  {I18n.t('Enabled')}
                </SimpleSelect.Option>
                <SimpleSelect.Option id="Disabled" value="disabled">
                  {I18n.t('Disabled')}
                </SimpleSelect.Option>
              </SimpleSelect>
            </Flex.Item>
            <Flex.Item padding="small">
              <TextInput
                renderLabel={<ScreenReaderContent>{I18n.t('Search Features')}</ScreenReaderContent>}
                placeholder={I18n.t('Search by name or id')}
                type="search"
                value={searchInput}
                onChange={acceptSearchInput}
                renderBeforeInput={<IconSearchLine inline={false} />}
                display="inline-block"
              />
            </Flex.Item>
            <Flex.Item padding="small">
              <Button color="primary" onClick={clearFilters}>
                {I18n.t('Clear')}
              </Button>
            </Flex.Item>
          </Flex>

          {categories.map(cat => {
            if (!groupedFeatures?.[cat.id]?.length) {
              return null
            }
            return (
              <FeatureFlagTable
                key={cat.id}
                title={cat.title}
                rows={groupedFeatures[cat.id]}
                disableDefaults={disableDefaults}
                filterByState={stateFilter}
              />
            )
          })}
        </>
      )}
    </View>
  )
}

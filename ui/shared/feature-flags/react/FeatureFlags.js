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

import React, {useState} from 'react'
import I18n from 'i18n!feature_flags'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {groupBy, debounce} from 'lodash'
import FeatureFlagTable from './FeatureFlagTable'
import FeatureFlagFilter from './FeatureFlagFilter'

import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'

const SEARCH_DELAY = 350

export default function FeatureFlags({hiddenFlags, disableDefaults}) {
  const [isLoading, setLoading] = useState(false)
  const [features, setFeatures] = useState([])
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedFeatureStates, setSelectedFeatureStates] = useState([])

  const categories = [
    {
      id: 'SiteAdmin',
      title: I18n.t('Site Admin')
    },
    {
      id: 'Account',
      title: I18n.t('Account')
    },
    {
      id: 'Course',
      title: I18n.t('Course')
    },
    {
      id: 'User',
      title: I18n.t('User')
    },
    {
      id: 'feature_option',
      title: I18n.t('Feature Previews')
    },
    {
      id: 'setting',
      title: I18n.t('Stable Features')
    }
  ]

  useFetchApi({
    success: setFeatures,
    loading: setLoading,
    path: `/api/v1${ENV.CONTEXT_BASE_URL}/features`,
    fetchAllPages: true,
    params: {
      hide_inherited_enabled: true,
      per_page: 50
    }
  })

  let groupedFeatures = {}

  if (ENV.FEATURES?.feature_flag_filters) {
    groupedFeatures = features.reduce((accum, feat) => {
      if (
        (!hiddenFlags || !hiddenFlags.includes(feat.feature)) &&
        feat.display_name.toLowerCase().includes(searchQuery.toLowerCase()) &&
        (!selectedFeatureStates.length || selectedFeatureStates.some(state => feat[state]))
      ) {
        let {applies_to} = feat
        if (applies_to === 'RootAccount') {
          applies_to = 'Account'
        }
        accum[feat.type] = accum[feat.type] || {}
        for (const category of categories) {
          accum[feat.type][category.title] = accum[feat.type][category.title] || []
          if (category.id === applies_to) {
            accum[feat.type][category.title] = accum[feat.type][category.title].concat(feat)
          }
        }
      }
      return accum
    }, {})
  } else {
    groupedFeatures = groupBy(
      features.filter(
        feat =>
          (!hiddenFlags || !hiddenFlags.includes(feat.feature)) &&
          feat.display_name.toLowerCase().includes(searchQuery.toLowerCase()) &&
          (!selectedFeatureStates.length || selectedFeatureStates.some(state => feat[state]))
      ),
      'applies_to'
    )

    if (groupedFeatures.Account || groupedFeatures.RootAccount) {
      groupedFeatures.Account = (groupedFeatures.Account || []).concat(
        groupedFeatures.RootAccount || []
      )
    }
  }

  const handleQueryChange = debounce(setSearchQuery, SEARCH_DELAY, {
    leading: false,
    trailing: true
  })

  function featureStatusFilter() {
    if (ENV.FEATURES?.feature_flag_filters) {
      return (
        <Flex.Item shouldGrow shouldShrink margin="0 0 0 small">
          <FeatureFlagFilter
            options={[
              {id: 'beta', label: I18n.t('Active Development')},
              {id: 'pending_enforcement', label: I18n.t('Pending Enforcement')}
            ]}
            onChange={statuses => setSelectedFeatureStates(statuses)}
          />
        </Flex.Item>
      )
    }
  }

  return (
    <View as="div">
      {isLoading ? (
        <Spinner renderTitle={I18n.t('Loading features')} />
      ) : (
        <>
          <Flex margin="0 0 medium 0" alignItems="start">
            <Flex.Item>
              <TextInput
                renderLabel={<ScreenReaderContent>{I18n.t('Search Features')}</ScreenReaderContent>}
                placeholder={I18n.t('Search')}
                display="inline-block"
                type="search"
                onChange={(_e, val) => handleQueryChange(val)}
                renderBeforeInput={<IconSearchLine inline={false} />}
              />
            </Flex.Item>
            {featureStatusFilter()}
          </Flex>

          {categories.map(cat => {
            if (!groupedFeatures[cat.id] || !Object.keys(groupedFeatures[cat.id]).length) {
              return null
            }
            return (
              <FeatureFlagTable
                key={cat.id}
                title={cat.title}
                rows={groupedFeatures[cat.id]}
                disableDefaults={disableDefaults}
                showTitle={Object.keys(groupedFeatures[cat.id]).length > 0}
              />
            )
          })}
        </>
      )}
    </View>
  )
}

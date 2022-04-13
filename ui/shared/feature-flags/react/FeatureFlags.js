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
import React, {useState} from 'react'
import {groupBy, debounce} from 'lodash'

import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'

import useFetchApi from '@canvas/use-fetch-api-hook'
import FeatureFlagTable from './FeatureFlagTable'

const I18n = useI18nScope('feature_flags')

const SEARCH_DELAY = 350

export default function FeatureFlags({hiddenFlags, disableDefaults}) {
  const [isLoading, setLoading] = useState(false)
  const [features, setFeatures] = useState([])
  const [searchQuery, setSearchQuery] = useState('')

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

  const groupedFeatures = groupBy(
    features.filter(
      feat =>
        (!hiddenFlags || !hiddenFlags.includes(feat.feature)) &&
        feat.display_name.toLowerCase().includes(searchQuery.toLowerCase())
    ),
    'applies_to'
  )
  if (groupedFeatures.Account || groupedFeatures.RootAccount) {
    groupedFeatures.Account = (groupedFeatures.Account || []).concat(
      groupedFeatures.RootAccount || []
    )
  }
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
    }
  ]

  const handleQueryChange = debounce(setSearchQuery, SEARCH_DELAY, {
    leading: false,
    trailing: true
  })

  return (
    <View as="div">
      {isLoading ? (
        <Spinner renderTitle={I18n.t('Loading feature options')} />
      ) : (
        <>
          <View as="div" margin="0 0 medium">
            <Flex.Item>
              <TextInput
                renderLabel={<ScreenReaderContent>{I18n.t('Search Features')}</ScreenReaderContent>}
                placeholder={I18n.t('Search')}
                display="inline-block"
                type="search"
                onChange={(_e, val) => handleQueryChange(val)}
                renderBeforeInput={<IconSearchLine display="block" />}
              />
            </Flex.Item>
          </View>

          {categories.map(cat => {
            if (!groupedFeatures[cat.id]?.length) {
              return null
            }
            return (
              <FeatureFlagTable
                key={cat.id}
                title={cat.title}
                rows={groupedFeatures[cat.id]}
                disableDefaults={disableDefaults}
              />
            )
          })}
        </>
      )}
    </View>
  )
}

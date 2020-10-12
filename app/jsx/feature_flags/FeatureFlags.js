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
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-layout'
import useFetchApi from 'jsx/shared/effects/useFetchApi'
import {groupBy} from 'lodash'
import FeatureFlagTable from './FeatureFlagTable'

export default function FeatureFlags({hiddenFlags, disableDefaults}) {
  const [isLoading, setLoading] = useState(false)
  const [features, setFeatures] = useState([])

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
    features.filter(feat => !hiddenFlags || !hiddenFlags.includes(feat.feature)),
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

  return (
    <View as="div">
      {isLoading ? (
        <Spinner renderTitle={I18n.t('Loading features')} />
      ) : (
        <>
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

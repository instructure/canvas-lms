/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import I18n from 'i18n!dashboard_pages_AppsList'
import React from 'react'
import PropTypes from 'prop-types'

import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'

import K5AppLink, {AppShape} from './K5AppLink'
import LoadingSkeleton from './LoadingSkeleton'

const AppsList = ({isLoading, apps}) => {
  const skeletons = []
  for (let i = 0; i < 3; i++) {
    skeletons.push(
      <View
        key={`skeleton-${i}`}
        display="inline-block"
        width="16em"
        height="2.875em"
        margin="small"
      >
        <LoadingSkeleton width="100%" height="100%" screenReaderLabel={I18n.t('Loading apps...')} />
      </View>
    )
  }

  return (
    <View as="section">
      {(isLoading || apps.length > 0) && (
        <Heading level="h2" margin="large 0 0">
          {I18n.t('Student Applications')}
        </Heading>
      )}
      {isLoading ? skeletons : apps.map(app => <K5AppLink key={app.id} app={app} />)}
    </View>
  )
}

AppsList.propTypes = {
  isLoading: PropTypes.bool,
  apps: PropTypes.arrayOf(PropTypes.shape(AppShape)).isRequired
}

export default AppsList

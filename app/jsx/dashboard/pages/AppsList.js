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
import K5AppLink, {AppShape} from 'jsx/dashboard/pages/K5AppLink'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'

export default function AppsList({isLoading, apps}) {
  return (
    <View as="section">
      {isLoading && (
        <View as="div" textAlign="center" margin="large 0">
          <Spinner renderTitle={I18n.t('Loading apps...')} size="large" />
        </View>
      )}
      {apps.length > 0 && (
        <>
          <Heading level="h3" as="h2" margin="medium 0 0">
            {I18n.t('Student Applications')}
          </Heading>
          {apps.map(app => (
            <K5AppLink key={app.id} app={app} />
          ))}
        </>
      )}
    </View>
  )
}

AppsList.propTypes = {
  isLoading: PropTypes.bool,
  apps: PropTypes.arrayOf(PropTypes.shape(AppShape)).isRequired
}

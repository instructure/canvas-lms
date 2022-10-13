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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'

import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'

import K5AppLink, {AppShape} from './K5AppLink'
import LoadingWrapper from './LoadingWrapper'

const I18n = useI18nScope('apps_list')

const AppsList = ({isLoading, apps, courseId}) => {
  return (
    <View as="section">
      {(isLoading || apps.length > 0) && (
        <Heading level="h2" margin="large 0 0">
          {I18n.t('Student Applications')}
        </Heading>
      )}
      <LoadingWrapper
        id={`apps-${courseId || 'dashboard'}`}
        isLoading={isLoading}
        display="inline-block"
        skeletonsNum={apps.length}
        // apps.length is 0 when mounting, setting an initial skeletons number will avoid
        // showing an empty page when loading
        defaultSkeletonsNum={3}
        width="16em"
        height="2.875em"
        screenReaderLabel={I18n.t('Loading apps...')}
      >
        {apps?.map(app => (
          <K5AppLink key={app.id} app={app} />
        ))}
      </LoadingWrapper>
    </View>
  )
}

AppsList.propTypes = {
  isLoading: PropTypes.bool,
  apps: PropTypes.arrayOf(PropTypes.shape(AppShape)).isRequired,
  courseId: PropTypes.string,
}

export default AppsList

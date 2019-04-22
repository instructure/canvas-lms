/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import I18n from 'i18n!assignments_2'
import React from 'react'
import View from '@instructure/ui-layout/lib/components/View'
import Text from '@instructure/ui-elements/lib/components/Text'
import {string} from 'prop-types'

function ErrorPageHeader(props) {
  return (
    <React.Fragment>
      <View margin="large auto" display="block">
        <img alt="" src={props.imageUrl} />
      </View>
      <View margin="small" display="block">
        <Text margin="x-small">{I18n.t('Something broke unexpectedly.')}</Text>
      </View>
    </React.Fragment>
  )
}

ErrorPageHeader.propTypes = {
  imageUrl: string.isRequired
}

export default React.memo(ErrorPageHeader)

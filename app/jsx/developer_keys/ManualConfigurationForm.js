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
import I18n from 'i18n!react_developer_keys'
import PropTypes from 'prop-types'
import React from 'react'

import Heading from '@instructure/ui-elements/lib/components/Heading'
import View from '@instructure/ui-layout/lib/components/View'

export default class ManualConfigurationForm extends React.Component {
  state = {
    toolConfiguration: {}
  }

  get toolConfiguration() {
    return this.state.toolConfiguration
  }

  render() {
    return (
      <View>
        <Heading level="h3" as="h3" margin="0 0 x-small">
          {I18n.t('Manual Configuration')}
        </Heading>
        placeholder...
      </View>
    )
  }
}

ManualConfigurationForm.propTypes = {
  toolConfiguration: PropTypes.object.isRequired
}

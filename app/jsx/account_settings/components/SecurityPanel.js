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

import React, {Component} from 'react'
import I18n from 'i18n!security_panel'
import {connect} from 'react-redux'
import {bool, oneOf, string, func} from 'prop-types'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'

import {getCspEnabled, setCspEnabled} from '../actions'

export class SecurityPanel extends Component {
  static propTypes = {
    context: oneOf(['course', 'account']).isRequired,
    contextId: string.isRequired,
    cspEnabled: bool.isRequired,
    getCspEnabled: func.isRequired,
    setCspEnabled: func.isRequired
  }

  handleCspToggleChange = e => {
    this.props.setCspEnabled(this.props.context, this.props.contextId, e.currentTarget.checked)
  }

  componentDidMount() {
    this.props.getCspEnabled(this.props.context, this.props.contextId)
  }

  render() {
    return (
      <div>
        <Heading margin="small 0" level="h3" as="h2" border="bottom">
          {I18n.t('Canvas Content Security Policy')}
        </Heading>
        <View as="div" margin="small 0">
          <Text>
            {I18n.t(
              `This allows you to restrict custom JavaScript that runs in your instance of Canvas.
               This will be enabled by an updated Content Security Policy (CSP).
               Domains will be added to your whitelist with the ability to manually add domains.
               There is a a 100 domain limit on the whitelist.`
            )}
          </Text>
        </View>
        <Checkbox
          variant="toggle"
          label={I18n.t('Enable Content Security Policy')}
          onChange={this.handleCspToggleChange}
          checked={this.props.cspEnabled}
        />
      </div>
    )
  }
}

function mapStateToProps(state, ownProps) {
  return {
    ...ownProps,
    cspEnabled: state.cspEnabled
  }
}

const mapDispatchToProps = {
  getCspEnabled,
  setCspEnabled
}

export const ConnectedSecurityPanel = connect(
  mapStateToProps,
  mapDispatchToProps
)(SecurityPanel)

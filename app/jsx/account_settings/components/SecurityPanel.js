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
import Grid, {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import RadioInput from '@instructure/ui-forms/lib/components/RadioInput'
import RadioInputGroup from '@instructure/ui-forms/lib/components/RadioInputGroup'
import List, {ListItem} from '@instructure/ui-elements/lib/components/List'
import {
  getCspEnabled,
  setCspEnabled,
  getCurrentWhitelist,
  getCspInherited,
  setCspInherited
} from '../actions'
import {ConnectedWhitelist} from './Whitelist'

import {CONFIG} from '../index'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

export class SecurityPanel extends Component {
  static propTypes = {
    context: oneOf(['course', 'account']).isRequired,
    contextId: string.isRequired,
    cspEnabled: bool.isRequired,
    cspInherited: bool.isRequired,
    getCspEnabled: func.isRequired,
    setCspEnabled: func.isRequired,
    getCspInherited: func.isRequired,
    setCspInherited: func.isRequired,
    getCurrentWhitelist: func.isRequired,
    isSubAccount: bool
  }

  static defaultProps = {
    isSubAccount: false
  }

  handleCspToggleChange = e => {
    this.props.setCspEnabled(this.props.context, this.props.contextId, e.currentTarget.checked)
  }

  handleSubAccountCspToggleChange = e => {
    if (e.currentTarget.value === 'inherit') {
      this.props.setCspInherited(this.props.context, this.props.contextId, true)
    } else {
      this.props.setCspEnabled(
        this.props.context,
        this.props.contextId,
        e.currentTarget.value === 'on'
      )
      this.props.setCspInherited(this.props.context, this.props.contextId, false)
    }
  }

  getSubAccountStatus = () => {
    if (this.props.cspInherited) {
      return 'inherit'
    }
    if (this.props.cspEnabled) {
      return 'on'
    }
    return 'off'
  }

  componentDidMount() {
    this.props.getCspEnabled(this.props.context, this.props.contextId)
    this.props.getCurrentWhitelist(this.props.context, this.props.contextId)
    if (this.props.isSubAccount) {
      this.props.getCspInherited(this.props.context, this.props.contextId)
    }
  }

  render() {
    return (
      <div>
        <Heading margin="small 0" level="h3" as="h2" border="bottom">
          {I18n.t('Canvas Content Security Policy')}
        </Heading>
        <View as="div" margin="small 0">
          <Text as="p">
            {I18n.t(
              `This allows you to restrict custom JavaScript that runs in your instance of Canvas.
               This will be enabled by an updated Content Security Policy (CSP).
               Domains will be added to your whitelist with the ability to manually add domains.
               There is a a %{max_domains} domain limit on the whitelist.`,
              {
                max_domains: CONFIG.max_domains
              }
            )}
          </Text>
          {this.props.isSubAccount && (
            <React.Fragment>
              <Text as="p">{I18n.t('Sub-accounts can choose one of three options:')}</Text>
              <List>
                <ListItem>{I18n.t('Off - Policy will not apply to this sub-account')}</ListItem>
                <ListItem>
                  {I18n.t(
                    'Inherit - Whitelist will be inherited from the parent account.  Domains can be added but will not be enforced until you change this setting to On.'
                  )}
                </ListItem>
                <ListItem>
                  {I18n.t(
                    'On - Whitelist will only be the domains which have been added explicitly to this account.'
                  )}
                </ListItem>
              </List>
            </React.Fragment>
          )}
        </View>
        <Grid>
          <GridRow>
            <GridCol>
              {this.props.isSubAccount ? (
                <RadioInputGroup
                  name="csp_subaccount_toggle"
                  description={
                    <ScreenReaderContent>Content Security Policy Selection</ScreenReaderContent>
                  }
                  variant="toggle"
                  size="large"
                  value={this.getSubAccountStatus()}
                  onChange={this.handleSubAccountCspToggleChange}
                >
                  <RadioInput label="Off" value="off" context="off" />
                  <RadioInput label="Inherit" value="inherit" />
                  <RadioInput label="On" value="on" />
                </RadioInputGroup>
              ) : (
                <Checkbox
                  variant="toggle"
                  label={I18n.t('Enable Content Security Policy')}
                  onChange={this.handleCspToggleChange}
                  checked={this.props.cspEnabled}
                />
              )}
            </GridCol>
          </GridRow>
          <GridRow>
            <GridCol>
              <ConnectedWhitelist
                context={this.props.context}
                contextId={this.props.contextId}
                isSubAccount={this.props.isSubAccount}
              />
            </GridCol>
          </GridRow>
        </Grid>
      </div>
    )
  }
}

function mapStateToProps(state, ownProps) {
  return {
    ...ownProps,
    cspEnabled: state.cspEnabled,
    cspInherited: state.cspInherited
  }
}

const mapDispatchToProps = {
  getCspEnabled,
  setCspEnabled,
  getCspInherited,
  setCspInherited,
  getCurrentWhitelist
}

export const ConnectedSecurityPanel = connect(
  mapStateToProps,
  mapDispatchToProps
)(SecurityPanel)

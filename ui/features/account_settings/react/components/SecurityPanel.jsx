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
import {useScope as useI18nScope} from '@canvas/i18n'
import {connect} from 'react-redux'
import {bool, oneOf, string, func, number, arrayOf, element} from 'prop-types'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'
import {Checkbox} from '@instructure/ui-checkbox'
import {
  getCspEnabled,
  setCspEnabled,
  getCurrentWhitelist,
  getCspInherited,
  setCspInherited,
} from '../actions'
import {ConnectedWhitelist} from './Whitelist'

const I18n = useI18nScope('security_panel')

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
    isSubAccount: bool,
    whitelistsHaveLoaded: bool,
    maxDomains: number.isRequired,
    accountId: string.isRequired,
    liveRegion: arrayOf(element).isRequired,
  }

  static defaultProps = {
    isSubAccount: false,
  }

  handleCspToggleChange = e => {
    this.props.setCspEnabled(this.props.context, this.props.contextId, e.currentTarget.checked)
  }

  handleCspInheritChange = e => {
    this.props.setCspInherited(this.props.context, this.props.contextId, e.currentTarget.checked)
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
              `The Content Security Policy allows you to restrict custom
               JavaScript that runs in your instance of Canvas. You can manually add
               up to %{max_domains} allowed domains. Wild cards are recommended
               (e.g. *.instructure.com). Canvas and Instructure domains are included
               automatically and do not count against your 50 domain limit.`,
              {
                max_domains: this.props.maxDomains,
              }
            )}
          </Text>
        </View>
        <Grid>
          <Grid.Row>
            <Grid.Col>
              {this.props.isSubAccount && (
                <View margin="0 xx-small">
                  <Checkbox
                    variant="toggle"
                    label={I18n.t('Inherit Content Security Policy')}
                    onChange={this.handleCspInheritChange}
                    checked={this.props.cspInherited}
                  />
                </View>
              )}
              <Checkbox
                variant="toggle"
                label={I18n.t('Enable Content Security Policy')}
                onChange={this.handleCspToggleChange}
                checked={this.props.cspEnabled}
                disabled={this.props.cspInherited && this.props.isSubAccount}
              />
            </Grid.Col>
          </Grid.Row>
          <Grid.Row>
            <Grid.Col>
              {!this.props.whitelistsHaveLoaded ? (
                <View as="div" margin="large" padding="large" textAlign="center">
                  <Spinner size="large" renderTitle={I18n.t('Loading')} />
                </View>
              ) : (
                <ConnectedWhitelist
                  context={this.props.context}
                  contextId={this.props.contextId}
                  isSubAccount={this.props.isSubAccount}
                  inherited={this.props.cspInherited}
                  maxDomains={this.props.maxDomains}
                  accountId={this.props.accountId}
                  liveRegion={this.props.liveRegion}
                />
              )}
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </div>
    )
  }
}

function mapStateToProps(state, ownProps) {
  return {
    ...ownProps,
    cspEnabled: state.cspEnabled,
    cspInherited: state.cspInherited,
    whitelistsHaveLoaded: state.whitelistsHaveLoaded,
  }
}

const mapDispatchToProps = {
  getCspEnabled,
  setCspEnabled,
  getCspInherited,
  setCspInherited,
  getCurrentWhitelist,
}

export const ConnectedSecurityPanel = connect(mapStateToProps, mapDispatchToProps)(SecurityPanel)

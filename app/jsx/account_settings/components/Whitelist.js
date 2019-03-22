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
import {arrayOf, bool, func, objectOf, oneOf, shape, string} from 'prop-types'
import Alert from '@instructure/ui-alerts/lib/components/Alert'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Button from '@instructure/ui-buttons/lib/components/Button'
import IconPlus from '@instructure/ui-icons/lib/Solid/IconPlus'
import List, {ListItem} from '@instructure/ui-elements/lib/components/List'
import Table from '@instructure/ui-elements/lib/components/Table'
import View from '@instructure/ui-layout/lib/components/View'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Billboard from '@instructure/ui-billboard/lib/components/Billboard'
import IconTrash from '@instructure/ui-icons/lib/Line/IconTrash'
import isValidDomain from 'is-valid-domain'

import EmptyDesert from '../../shared/EmptyDesert'

import {addDomain, removeDomain, copyInheritedIfNeeded} from '../actions'
import {CONFIG} from '../index'

const PROTOCOL_REGEX = /^(?:(ht|f)tp(s?)\:\/\/)?/

export class Whitelist extends Component {
  static propTypes = {
    addDomain: func.isRequired,
    removeDomain: func.isRequired,
    context: oneOf(['course', 'account']).isRequired,
    contextId: string.isRequired,
    copyInheritedIfNeeded: func.isRequired,
    inherited: bool,
    isSubAccount: bool,
    whitelistedDomains: shape({
      account: arrayOf(string),
      effective: arrayOf(string),
      inherited: arrayOf(string),
      tools: objectOf(arrayOf(shape({id: string, name: string, account_id: string})))
    }).isRequired
  }

  static defaultProps = {
    inherited: false
  }

  state = {
    addDomainInputValue: '',
    errors: []
  }

  deleteButtons = []

  addDomainBtn = null

  validateInput = input => {
    const domainOnly = input.replace(PROTOCOL_REGEX, '')
    const parts = domainOnly.split('.')
    const isWildcard = parts[0] === '*'
    if (isWildcard) {
      parts.shift()
      return isValidDomain(parts.join('.'))
    }
    return isValidDomain(domainOnly)
  }

  handleSubmit = () => {
    if (this.validateInput(this.state.addDomainInputValue)) {
      this.setState(curState => {
        this.props.addDomain(this.props.context, this.props.contextId, curState.addDomainInputValue)
        this.props.copyInheritedIfNeeded(this.props.context, this.props.contextId, {
          add: curState.addDomainInputValue
        })
        return {
          errors: [],
          addDomainInputValue: ''
        }
      })
    } else {
      this.setState({
        errors: [
          {
            text: I18n.t('Invalid domain'),
            type: 'error'
          }
        ]
      })
    }
  }

  handleRemoveDomain = domain => {
    const deletedIndex = this.props.whitelistedDomains.account.findIndex(x => x === domain)
    let newIndex = 0
    if (deletedIndex > 0) {
      newIndex = deletedIndex - 1
    }
    this.props.removeDomain(this.props.context, this.props.contextId, domain)
    const newDomainToFocus = this.props.whitelistedDomains.account[newIndex]
    if (deletedIndex <= 0) {
      this.addDomainBtn.focus()
    } else {
      this.deleteButtons[newDomainToFocus].focus()
    }
    this.props.copyInheritedIfNeeded(this.props.context, this.props.contextId, {delete: domain})
  }

  render() {
    const domainLimitReached =
      this.props.whitelistedDomains.account.length >= CONFIG.max_domains && !this.props.inherited
    const toolsWhitelistKeys = this.props.whitelistedDomains.tools
      ? Object.keys(this.props.whitelistedDomains.tools)
      : []

    const whitelistToShow = this.props.inherited
      ? this.props.whitelistedDomains.inherited
      : this.props.whitelistedDomains.account

    return (
      <div>
        <Heading margin="small 0" level="h4" as="h3" border="bottom">
          {this.props.inherited
            ? I18n.t('Whitelist')
            : I18n.t('Whitelist (%{count}/%{max})', {
                count: this.props.whitelistedDomains.account.length,
                max: CONFIG.max_domains
              })}
        </Heading>
        <form
          onSubmit={e => {
            e.preventDefault()
            this.handleSubmit()
          }}
        >
          {domainLimitReached && (
            <Alert variant="error" margin="small 0">
              {I18n.t(
                `You have reached the domain limit.  You can add more domains by deleting existing domains in your whitelist.`
              )}
            </Alert>
          )}

          {this.props.inherited && this.props.isSubAccount && (
            <Alert variant="info" margin="small 0">
              {I18n.t(
                `Whitelist editing is disabled when security settings are inherited from a parent account.`
              )}
            </Alert>
          )}

          <Flex>
            <FlexItem grow shrink padding="0 medium 0 0">
              <TextInput
                label={I18n.t('Domain Name')}
                placeholder="http://somedomain.com"
                value={this.state.addDomainInputValue}
                messages={this.state.errors}
                disabled={(this.props.inherited && this.props.isSubAccount) || domainLimitReached}
                onChange={e => {
                  this.setState({addDomainInputValue: e.currentTarget.value})
                }}
              />
            </FlexItem>
            <FlexItem align={this.state.errors.length ? 'center' : 'end'}>
              <Button
                aria-label={I18n.t('Add Domain')}
                ref={c => (this.addDomainBtn = c)}
                type="submit"
                margin="0 x-small 0 0"
                icon={IconPlus}
                disabled={(this.props.inherited && this.props.isSubAccount) || domainLimitReached}
              >
                {I18n.t('Domain')}
              </Button>
            </FlexItem>
          </Flex>
        </form>
        {whitelistToShow.length <= 0 ? (
          <Billboard
            size="small"
            heading={I18n.t('No domains whitelisted')}
            hero={<EmptyDesert />}
          />
        ) : (
          <Table
            caption={<ScreenReaderContent>{I18n.t('Whitelisted Domains')}</ScreenReaderContent>}
          >
            <thead>
              <tr>
                <th scope="col">Domain Name</th>
                <th scope="col">
                  <ScreenReaderContent>{I18n.t('Actions')}</ScreenReaderContent>
                </th>
              </tr>
            </thead>
            <tbody>
              {whitelistToShow.map(domain => (
                <tr key={domain}>
                  <td>{domain}</td>
                  <td style={{textAlign: 'end'}}>
                    <Button
                      ref={c => (this.deleteButtons[domain] = c)}
                      variant="icon"
                      icon={IconTrash}
                      onClick={() => this.handleRemoveDomain(domain)}
                      data-testid={`delete-button-${domain}`}
                      disabled={this.props.inherited && this.props.isSubAccount}
                    >
                      <ScreenReaderContent>
                        {I18n.t('Remove %{domain} from the whitelist', {domain})}
                      </ScreenReaderContent>
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </Table>
        )}
        {toolsWhitelistKeys && toolsWhitelistKeys.length > 0 && (
          <View as="div" margin="large 0">
            <Heading level="h4" as="h3">
              {I18n.t('Whitelisted Tool Domains')}
            </Heading>
            <p>
              {I18n.t(
                `The following domains have automatically been added to your
                 whitelist from tools already existing in your account.
                 To remove these domains, remove the associated tools.`
              )}
            </p>
            <p>
              {I18n.t(
                `NOTE: Associated tools are only listed once, even if they have
                been installed in multiple subaccounts.`
              )}
            </p>
            <Table
              caption={
                <ScreenReaderContent>{I18n.t('Whitelisted Tool Domains')}</ScreenReaderContent>
              }
            >
              <thead>
                <tr>
                  <th scope="col">Domain Name</th>
                  <th scope="col">Associated Tools</th>
                </tr>
              </thead>
              <tbody>
                {toolsWhitelistKeys.map(domain => (
                  <tr key={domain}>
                    <td>{domain}</td>
                    <td>
                      <List variant="unstyled">
                        {this.props.whitelistedDomains.tools[domain].map(associatedTool => (
                          <ListItem key={associatedTool.id}>{associatedTool.name}</ListItem>
                        ))}
                      </List>
                    </td>
                  </tr>
                ))}
              </tbody>
            </Table>
          </View>
        )}
      </div>
    )
  }
}

function mapStateToProps(state, ownProps) {
  return {...ownProps, whitelistedDomains: state.whitelistedDomains}
}

const mapDispatchToProps = {
  addDomain,
  removeDomain,
  copyInheritedIfNeeded
}

export const ConnectedWhitelist = connect(
  mapStateToProps,
  mapDispatchToProps
)(Whitelist)

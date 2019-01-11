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
import {arrayOf, func, objectOf, oneOf, shape, string} from 'prop-types'
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
import IconTrash from '@instructure/ui-icons/lib/Line/IconTrash'
import isValidDomain from 'is-valid-domain'

import {addDomain, removeDomain} from '../actions'
import {CONFIG} from '../index'

const PROTOCOL_REGEX = /^(?:(ht|f)tp(s?)\:\/\/)?/

export class Whitelist extends Component {
  static propTypes = {
    addDomain: func.isRequired,
    removeDomain: func.isRequired,
    context: oneOf(['course', 'account']).isRequired,
    contextId: string.isRequired,
    whitelistedDomains: shape({
      account: arrayOf(string),
      effective: arrayOf(string),
      tools: objectOf(arrayOf(shape({id: string, name: string, account_id: string})))
    }).isRequired
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
  }

  render() {
    const domainLimitReached = this.props.whitelistedDomains.account.length >= CONFIG.max_domains
    const toolsWhitelistKeys = this.props.whitelistedDomains.tools
      ? Object.keys(this.props.whitelistedDomains.tools)
      : []
    return (
      <div>
        <Heading margin="small 0" level="h4" as="h3" border="bottom">
          {I18n.t('Whitelist (%{count}/%{max})', {
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
            <Alert variant="error" margin="small">
              {I18n.t(
                `You have reached the domain limit, if you wish to add more to your whitelist, please remove others first.`
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
                disabled={domainLimitReached}
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
                disabled={domainLimitReached}
              >
                {I18n.t('Domain')}
              </Button>
            </FlexItem>
          </Flex>
        </form>
        <Table caption={<ScreenReaderContent>{I18n.t('Whitelisted Domains')}</ScreenReaderContent>}>
          <thead>
            <tr>
              <th scope="col">Domain Name</th>
              <th scope="col">
                <ScreenReaderContent>{I18n.t('Actions')}</ScreenReaderContent>
              </th>
            </tr>
          </thead>
          <tbody>
            {this.props.whitelistedDomains.account.map(domain => (
              <tr key={domain}>
                <td>{domain}</td>
                <td style={{textAlign: 'end'}}>
                  <Button
                    ref={c => (this.deleteButtons[domain] = c)}
                    variant="icon"
                    icon={IconTrash}
                    onClick={() => this.handleRemoveDomain(domain)}
                    data-testid={`delete-button-${domain}`}
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
        {toolsWhitelistKeys && toolsWhitelistKeys.length > 0 && (
          <View as="div" margin="large 0">
            <Heading level="h4" as="h3">
              {I18n.t('Whitelisted Tool Domains')}
            </Heading>
            <p>
              {I18n.t(
                `These domains have automatically been added to your whitelist.
              If you wish to remove them, you should remove the associated tool.`
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
  removeDomain
}

export const ConnectedWhitelist = connect(
  mapStateToProps,
  mapDispatchToProps
)(Whitelist)

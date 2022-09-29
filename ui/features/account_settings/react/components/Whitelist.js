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
import {arrayOf, bool, func, objectOf, oneOf, shape, string, number} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {List} from '@instructure/ui-list'
import {Heading} from '@instructure/ui-heading'
import {Table} from '@instructure/ui-table'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconPlusSolid, IconTrashLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Billboard} from '@instructure/ui-billboard'
import isValidDomain from 'is-valid-domain'

import EmptyDesert from '@canvas/images/react/EmptyDesert'

import {addDomain, removeDomain, copyInheritedIfNeeded} from '../actions'

const I18n = useI18nScope('security_panel')

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
      tools: objectOf(arrayOf(shape({id: string, name: string, account_id: string}))),
    }).isRequired,
    maxDomains: number.isRequired,
  }

  static defaultProps = {
    inherited: false,
  }

  state = {
    addDomainInputValue: '',
    errors: [],
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
          add: curState.addDomainInputValue,
        })
        return {
          errors: [],
          addDomainInputValue: '',
        }
      })
    } else {
      this.setState({
        errors: [
          {
            text: I18n.t('Invalid domain'),
            type: 'error',
          },
        ],
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
      this.props.whitelistedDomains.account.length >= this.props.maxDomains && !this.props.inherited
    const toolsWhitelistKeys = this.props.whitelistedDomains.tools
      ? Object.keys(this.props.whitelistedDomains.tools)
      : []

    const whitelistToShow = this.props.inherited
      ? this.props.whitelistedDomains.inherited
      : this.props.whitelistedDomains.account

    return (
      <div>
        <View
          as="div"
          margin="none none small none"
          padding="xxx-small"
          background="primary"
          borderWidth="none none small none"
        >
          <Flex justifyItems="space-between">
            <Flex.Item>
              <Heading margin="small" level="h4" as="h3">
                {this.props.inherited
                  ? I18n.t('Domains')
                  : I18n.t('Domains (%{count}/%{max})', {
                      count: this.props.whitelistedDomains.account.length,
                      max: this.props.maxDomains,
                    })}
              </Heading>
            </Flex.Item>
          </Flex>
        </View>

        <form
          onSubmit={e => {
            e.preventDefault()
            this.handleSubmit()
          }}
        >
          {domainLimitReached && (
            <Alert variant="error" margin="small 0">
              {I18n.t(
                `You have reached the domain limit. You can add more domains by deleting existing domains in your allowed list.`
              )}
            </Alert>
          )}

          {this.props.inherited && this.props.isSubAccount && (
            <Alert variant="info" margin="small 0">
              {I18n.t(
                `Domain editing is disabled when security settings are inherited from a parent account.`
              )}
            </Alert>
          )}

          <Flex>
            <Flex.Item shouldGrow={true} shouldShrink={true} padding="0 medium 0 0">
              <TextInput
                renderLabel={I18n.t('Domain Name')}
                placeholder="http://somedomain.com"
                value={this.state.addDomainInputValue}
                messages={this.state.errors}
                disabled={(this.props.inherited && this.props.isSubAccount) || domainLimitReached}
                onChange={e => {
                  this.setState({addDomainInputValue: e.currentTarget.value})
                }}
              />
            </Flex.Item>
            <Flex.Item align={this.state.errors.length ? 'center' : 'end'}>
              <Button
                aria-label={I18n.t('Add Domain')}
                ref={c => (this.addDomainBtn = c)}
                type="submit"
                margin="0 x-small 0 0"
                renderIcon={IconPlusSolid}
                disabled={(this.props.inherited && this.props.isSubAccount) || domainLimitReached}
              >
                {I18n.t('Domain')}
              </Button>
            </Flex.Item>
          </Flex>
        </form>
        {whitelistToShow.length <= 0 ? (
          <Billboard size="small" heading={I18n.t('No allowed domains')} hero={<EmptyDesert />} />
        ) : (
          <Table caption={I18n.t('Allowed Domains')}>
            <Table.Head>
              <Table.Row>
                <Table.ColHeader id="allowed-domain-name">
                  {I18n.t('Allowed Domains')}
                </Table.ColHeader>
                <Table.ColHeader id="allowed-domain-actions">
                  <ScreenReaderContent>{I18n.t('Actions')}</ScreenReaderContent>
                </Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {whitelistToShow.map(domain => (
                <Table.Row key={domain}>
                  <Table.Cell>{domain}</Table.Cell>
                  <Table.Cell textAlign="end">
                    <IconButton
                      ref={c => (this.deleteButtons[domain] = c)}
                      renderIcon={IconTrashLine}
                      withBackground={false}
                      withBorder={false}
                      onClick={() => this.handleRemoveDomain(domain)}
                      data-testid={`delete-button-${domain}`}
                      disabled={this.props.inherited && this.props.isSubAccount}
                      screenReaderLabel={I18n.t('Remove %{domain} as an allowed domain', {domain})}
                    />
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table.Body>
          </Table>
        )}
        {toolsWhitelistKeys && toolsWhitelistKeys.length > 0 && (
          <View as="div" margin="large 0">
            <Heading level="h4" as="h3">
              {I18n.t('Associated Tool Domains')}
            </Heading>
            <p>
              {I18n.t(
                `The following domains have automatically been allowed from tools that already exist in your account.
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
                <ScreenReaderContent>{I18n.t('Associated Tool Domains')}</ScreenReaderContent>
              }
            >
              <Table.Head>
                <Table.Row>
                  <Table.ColHeader id="whitelisted-tools-domain-name">Domain Name</Table.ColHeader>
                  <Table.ColHeader id="whitelisted-tools-tools">Associated Tools</Table.ColHeader>
                </Table.Row>
              </Table.Head>
              <Table.Body>
                {toolsWhitelistKeys.map(domain => (
                  <Table.Row key={domain}>
                    <Table.Cell>{domain}</Table.Cell>
                    <Table.Cell>
                      <List isUnstyled={true}>
                        {this.props.whitelistedDomains.tools[domain].map(associatedTool => (
                          <List.Item key={associatedTool.id}>{associatedTool.name}</List.Item>
                        ))}
                      </List>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table.Body>
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
  copyInheritedIfNeeded,
}

export const ConnectedWhitelist = connect(mapStateToProps, mapDispatchToProps)(Whitelist)

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
import {arrayOf, func, oneOf, string} from 'prop-types'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Button from '@instructure/ui-buttons/lib/components/Button'
import IconPlus from '@instructure/ui-icons/lib/Solid/IconPlus'
import Table from '@instructure/ui-elements/lib/components/Table'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import isValidDomain from 'is-valid-domain'

import {addDomain} from '../actions'

const PROTOCOL_REGEX = /^(?:(ht|f)tp(s?)\:\/\/)?/

export class Whitelist extends Component {
  static propTypes = {
    addDomain: func.isRequired,
    context: oneOf(['course', 'account']).isRequired,
    contextId: string.isRequired,
    whitelistedDomains: arrayOf(string).isRequired
  }

  state = {
    addDomainInputValue: '',
    errors: []
  }

  validateInput = input => {
    const domainOnly = input.replace(PROTOCOL_REGEX, '')
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

  render() {
    return (
      <div>
        <Heading margin="small 0" level="h4" as="h3" border="bottom">
          {I18n.t('Whitelist (%{count}/%{max})', {
            count: this.props.whitelistedDomains.length,
            max: 100
          })}
        </Heading>
        <form
          onSubmit={e => {
            e.preventDefault()
            this.handleSubmit()
          }}
        >
          <Flex>
            <FlexItem grow shrink padding="0 medium 0 0">
              <TextInput
                label={I18n.t('Add Domain')}
                placeholder="http://somedomain.com"
                value={this.state.addDomainInputValue}
                messages={this.state.errors}
                onChange={e => {
                  this.setState({addDomainInputValue: e.currentTarget.value})
                }}
              />
            </FlexItem>
            <FlexItem align={this.state.errors.length ? 'center' : 'end'}>
              <Button type="submit" margin="0 x-small 0 0" icon={IconPlus}>
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
                <ScreenReaderContent>Actions</ScreenReaderContent>
              </th>
            </tr>
          </thead>
          <tbody>
            {this.props.whitelistedDomains.map(domain => (
              <tr key={domain}>
                <td>{domain}</td>
                <td />
              </tr>
            ))}
          </tbody>
        </Table>
      </div>
    )
  }
}

function mapStateToProps(state, ownProps) {
  return {...ownProps, whitelistedDomains: state.whitelistedDomains}
}

const mapDispatchToProps = {
  addDomain
}

export const ConnectedWhitelist = connect(
  mapStateToProps,
  mapDispatchToProps
)(Whitelist)

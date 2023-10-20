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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import ScopesMethod from './ScopesMethod'
import DeveloperKeyScope from './Scope'

const I18n = useI18nScope('react_developer_keys')

export default class ScopesGroup extends React.Component {
  state = {groupChecked: this.allScopesAreSelected(this.props)}

  UNSAFE_componentWillReceiveProps(nextProps) {
    this.setState({
      groupChecked: this.allScopesAreSelected(nextProps),
    })
  }

  shouldComponentUpdate(nextProps, _nextState) {
    // Get the symmetric difference of old selected scopes and new selected scopes
    const selectedDiff = nextProps.selectedScopes
      .filter(scope => !this.props.selectedScopes.includes(scope))
      .concat(this.props.selectedScopes.filter(scope => !nextProps.selectedScopes.includes(scope)))

    // Rerender if a scope owned by this group changed
    if (this.props.scopes.filter(scope => selectedDiff.includes(scope.scope)).length > 0) {
      return true
    }
    return false
  }

  allScopesAreSelected(props) {
    const allScopes = this.allScopesInGroup()
    const diff = allScopes.filter(s => !props.selectedScopes.includes(s))
    return diff.length === 0
  }

  selectedMethods() {
    const methodSet = this.props.scopes.reduce((result, scope) => {
      if (this.props.selectedScopes.includes(scope.scope)) {
        result.add(`${scope.verb}`)
      }

      return result
    }, new Set())

    return (
      <span>
        {[...methodSet].sort().map(method => (
          <ScopesMethod
            method={method}
            margin="none none none x-small"
            key={`${this.props.name}-${method}`}
          />
        ))}
      </span>
    )
  }

  groupSummary() {
    return (
      <Flex justifyItems="space-between">
        <Flex.Item padding="0 x-small 0 0">
          <Text size="medium">{this.props.name}</Text>
        </Flex.Item>
        <Flex.Item>{this.selectedMethods()}</Flex.Item>
      </Flex>
    )
  }

  allScopesInGroup() {
    return this.props.scopes.map(s => s.scope)
  }

  handleGroupChange = event => {
    const scopesInGroup = this.allScopesInGroup()
    let newScopes = []

    if (event.currentTarget.checked) {
      newScopes = scopesInGroup.concat(this.props.selectedScopes)
    } else {
      newScopes = this.props.selectedScopes.filter(s => !scopesInGroup.includes(s))
    }

    this.props.setSelectedScopes(newScopes)
    this.setState({
      groupChecked: event.currentTarget.checked,
    })
  }

  handleSingleChange = event => {
    let newScopes = this.props.selectedScopes.slice()
    const checkbox = event.currentTarget

    if (checkbox.checked) {
      newScopes.push(checkbox.value)
    } else {
      newScopes = newScopes.filter(s => s !== checkbox.value)
    }

    this.props.setSelectedScopes(newScopes)
    this.setState({
      groupChecked: false,
    })
  }

  render() {
    return (
      <View as="div" borderWidth="none none small none" data-automation="scopes-group">
        <Flex alignItems="start" padding="small none small small">
          <Flex.Item padding="none small none none">
            <Checkbox
              label={
                <ScreenReaderContent>
                  {I18n.t('All %{scopeName} scopes', {scopeName: this.props.name})}
                </ScreenReaderContent>
              }
              inline={true}
              checked={this.state.groupChecked}
              onChange={this.handleGroupChange}
            />
          </Flex.Item>
          <Flex.Item shouldGrow={true} padding="none small none none">
            <div data-automation="toggle-scope-group">
              <ToggleDetails summary={this.groupSummary()} fluidWidth={true}>
                {this.props.scopes.map(scope => (
                  <DeveloperKeyScope
                    checked={this.props.selectedScopes.includes(scope.scope)}
                    scope={scope}
                    key={scope.scope}
                    onChange={this.handleSingleChange}
                  />
                ))}
              </ToggleDetails>
            </div>
          </Flex.Item>
        </Flex>
      </View>
    )
  }
}

ScopesGroup.propTypes = {
  setSelectedScopes: PropTypes.func.isRequired,
  scopes: PropTypes.arrayOf(
    PropTypes.shape({
      scope: PropTypes.string,
      verb: PropTypes.string.isRequired,
    })
  ).isRequired,
  selectedScopes: PropTypes.arrayOf(PropTypes.string).isRequired,
  name: PropTypes.string.isRequired,
}

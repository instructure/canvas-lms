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
import LazyLoad from 'react-lazy-load'
import PropTypes from 'prop-types'
import React from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import ScopesGroup from './ScopesGroup'
import ScopesMethod from './ScopesMethod'

const I18n = useI18nScope('react_developer_keys')

export default class ScopesList extends React.Component {
  constructor(props) {
    super(props)
    const formattedScopesArray = Object.keys(this.props.availableScopes).map(k => ({
      [k]: this.props.availableScopes[k],
    }))

    this.state = {
      formattedScopesArray,
      availableScopes: formattedScopesArray.slice(0, 8), // Only load 8 groups on initial render
      selectedScopes: this.props.selectedScopes,
      readOnlySelected: this.onlySelectGet(this.uniqueSelectedScopes(this.props.selectedScopes)),
    }
  }

  componentDidMount() {
    this.delayedRender()
  }

  onlySelectGet(selectedScopes) {
    const allAvailableGetScopes = this.availableGetScopes()
    if (selectedScopes.length !== allAvailableGetScopes.length) {
      return false
    }
    const nonGetScopes = selectedScopes.filter(s => !allAvailableGetScopes.includes(s))
    if (nonGetScopes.length > 0) {
      return false
    }
    return true
  }

  setSelectedScopes = scope => {
    const selectedScopes = this.uniqueSelectedScopes(scope)
    this.setState({
      selectedScopes,
      readOnlySelected: this.onlySelectGet(selectedScopes),
    })
    this.props.dispatch(this.props.listDeveloperKeyScopesSet(selectedScopes))
  }

  uniqueSelectedScopes(selectedScopes) {
    return [...new Set(selectedScopes)]
  }

  delayedRender = () => {
    // Load the rest of the groups once the modal is open
    setTimeout(() => {
      this.setState(oldState => ({availableScopes: oldState.formattedScopesArray.slice()}))
    }, 0)
  }

  handleReadOnlySelected = event => {
    let newScopes = []
    if (event.currentTarget.checked) {
      newScopes = this.availableGetScopes()
    } else {
      newScopes = []
    }

    this.setState({
      selectedScopes: newScopes,
      readOnlySelected: event.currentTarget.checked,
    })

    this.props.dispatch(this.props.listDeveloperKeyScopesSet(newScopes))
  }

  noFilter() {
    return this.props.filter === '' || !this.props.filter
  }

  availableGetScopes() {
    return this.allScopes(this.props.availableScopes)
      .filter(s => s.verb === 'GET')
      .map(s => s.scope)
  }

  allScopes(availableScopes) {
    return Object.values(availableScopes).reduce((accumulator, currentValue) => {
      return accumulator.concat(currentValue)
    }, [])
  }

  render() {
    return (
      <div data-automation="scopes-list">
        <View borderRadius="small" display="block" borderWidth="small">
          <Flex height="564px" width="100%" as="div" direction="column">
            <Flex.Item padding="none" textAlign="start">
              <View padding="small" display="block" borderWidth="none none medium none">
                <Flex>
                  <Flex.Item>
                    <Checkbox
                      label={
                        <ScreenReaderContent>
                          {this.state.readOnlySelected
                            ? I18n.t('Disable all read only scopes.')
                            : I18n.t('Enable all read only scopes.')}
                        </ScreenReaderContent>
                      }
                      onChange={this.handleReadOnlySelected}
                      checked={this.state.readOnlySelected}
                      inline={true}
                    />
                    <PresentationContent>
                      <Text size="medium" weight="bold">
                        {I18n.t('Read only')}
                      </Text>
                      <ScopesMethod method="get" margin="none small none small" />
                    </PresentationContent>
                  </Flex.Item>
                </Flex>
              </View>
            </Flex.Item>
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              {this.state.availableScopes.map(scopeGroup => {
                return Object.keys(scopeGroup).reduce((result, key) => {
                  if (
                    this.noFilter() ||
                    key.toLowerCase().indexOf(this.props.filter.toLowerCase()) > -1
                  ) {
                    result.push(
                      <LazyLoad
                        offset={1000}
                        debounce={false}
                        height={50}
                        width="100%"
                        key={`${key}-scope-group`}
                      >
                        <ScopesGroup
                          scopes={this.props.availableScopes[key]}
                          name={key}
                          selectedScopes={this.state.selectedScopes}
                          setSelectedScopes={this.setSelectedScopes}
                        />
                      </LazyLoad>
                    )
                  }
                  return result
                }, [])
              })}
            </Flex.Item>
          </Flex>
        </View>
      </div>
    )
  }
}

ScopesList.propTypes = {
  dispatch: PropTypes.func.isRequired,
  listDeveloperKeyScopesSet: PropTypes.func.isRequired,
  availableScopes: PropTypes.objectOf(
    PropTypes.arrayOf(
      PropTypes.shape({
        resource: PropTypes.string,
        scope: PropTypes.string,
      })
    )
  ).isRequired,
  filter: PropTypes.string.isRequired,
  selectedScopes: PropTypes.arrayOf(PropTypes.string),
}

ScopesList.defaultProps = {
  selectedScopes: [],
}

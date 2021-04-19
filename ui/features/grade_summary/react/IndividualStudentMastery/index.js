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

import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!IndividualStudentMasteryIndex'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {Spinner} from '@instructure/ui-spinner'
import natcompare from '@canvas/util/natcompare'
import OutcomeGroup from './OutcomeGroup'
import fetchOutcomes from './fetchOutcomes'
import {Set} from 'immutable'
import * as shapes from './shapes'

class IndividualStudentMastery extends React.Component {
  static propTypes = {
    courseId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
    studentId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
    onExpansionChange: PropTypes.func,
    outcomeProficiency: shapes.outcomeProficiencyShape
  }

  static defaultProps = {
    onExpansionChange: () => {},
    outcomeProficiency: null
  }

  constructor() {
    super()
    this.state = {loading: true, error: null, expandedGroups: Set(), expandedOutcomes: Set()}
  }

  componentDidMount() {
    const {courseId, studentId} = this.props
    return fetchOutcomes(courseId, studentId)
      .then(({outcomeGroups, outcomes}) => {
        this.setState({outcomeGroups, outcomes})
      })
      .then(() => this.setState({loading: false}))
      .catch(e => this.setState({loading: false, error: e}))
  }

  onElementExpansionChange = (type, id, newState) => {
    let groups = this.state.expandedGroups
    let outcomes = this.state.expandedOutcomes
    if (type === 'group') {
      if (newState) {
        groups = groups.add(id)
      } else {
        groups = groups.delete(id)
        const idsToRemove = this.state.outcomes
          .filter(o => o.groupId === id)
          .map(o => o.expansionId)
        outcomes = outcomes.filterNot(oid => idsToRemove.includes(oid))
      }
    } else if (type === 'outcome') {
      if (newState) {
        outcomes = outcomes.add(id)
      } else {
        outcomes = outcomes.delete(id)
      }
    }
    this.setState(
      {
        expandedGroups: groups,
        expandedOutcomes: outcomes
      },
      () => this.notifyExpansionChange()
    )
  }

  contract() {
    this.setState(
      {
        expandedGroups: Set(),
        expandedOutcomes: Set()
      },
      () => this.notifyExpansionChange()
    )
  }

  expand() {
    this.setState(
      oldState => {
        const {outcomeGroups, outcomes} = oldState
        return {
          expandedGroups: Set(outcomeGroups.map(g => g.id)),
          expandedOutcomes: Set(outcomes.map(o => o.expansionId))
        }
      },
      () => this.notifyExpansionChange()
    )
  }

  notifyExpansionChange() {
    this.props.onExpansionChange(this.anyExpanded(), this.anyContracted())
  }

  anyExpanded() {
    return this.state.expandedGroups.size > 0 || this.state.expandedOutcomes.size > 0
  }

  anyContracted() {
    return (
      this.state.outcomeGroups.length > this.state.expandedGroups.size ||
      this.state.outcomes.length > this.state.expandedOutcomes.size
    )
  }

  renderLoading() {
    return (
      <Flex justifyItems="center" alignItems="center" padding="medium">
        <Flex.Item>
          <Spinner size="large" renderTitle={I18n.t('Loading outcome results')} />
        </Flex.Item>
      </Flex>
    )
  }

  renderError() {
    return (
      <Flex justifyItems="start" alignItems="center" padding="medium 0">
        <Flex.Item>
          <Text color="danger">{I18n.t('An error occurred loading outcomes data.')}</Text>
        </Flex.Item>
      </Flex>
    )
  }

  renderEmpty() {
    return (
      <Flex justifyItems="start" alignItems="center" padding="medium 0">
        <Flex.Item>
          <Text>{I18n.t('There are no outcomes in the course.')}</Text>
        </Flex.Item>
      </Flex>
    )
  }

  renderGroups() {
    const {outcomeGroups, outcomes} = this.state
    const {outcomeProficiency} = this.props
    return (
      <div>
        <List variant="unstyled">
          {outcomeGroups.sort(natcompare.byKey('title')).map(outcomeGroup => (
            <List.Item key={outcomeGroup.id}>
              <OutcomeGroup
                outcomeGroup={outcomeGroup}
                outcomes={outcomes.filter(o => o.groupId.toString() === outcomeGroup.id.toString())}
                expanded={this.state.expandedGroups.has(outcomeGroup.id)}
                expandedOutcomes={this.state.expandedOutcomes}
                onExpansionChange={this.onElementExpansionChange}
                outcomeProficiency={outcomeProficiency}
              />
            </List.Item>
          ))}
        </List>
      </div>
    )
  }

  render() {
    const {error, loading, outcomeGroups} = this.state

    if (loading) {
      return this.renderLoading()
    } else if (error) {
      return this.renderError()
    } else if (outcomeGroups.length === 0) {
      return this.renderEmpty()
    } else {
      return this.renderGroups()
    }
  }
}

export default IndividualStudentMastery

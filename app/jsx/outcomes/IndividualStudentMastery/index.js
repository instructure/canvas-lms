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
import I18n from 'i18n!outcomes'
import Flex, { FlexItem } from '@instructure/ui-layout/lib/components/Flex'
import List, { ListItem } from '@instructure/ui-elements/lib/components/List'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import Text from '@instructure/ui-elements/lib/components/Text'
import OutcomeGroup from './OutcomeGroup'
import fetchOutcomes from './fetchOutcomes'

// eslint-disable-next-line
class IndividualStudentMastery extends React.Component {
  static propTypes = {
    courseId: PropTypes.number.isRequired,
    studentId: PropTypes.number.isRequired,
    onExpansionChange: PropTypes.func
  }

  static defaultProps = {
    onExpansionChange: () => {}
  }

  constructor () {
    super()
    this.state = { loading: true, error: null }
  }

  componentDidMount () {
    const { courseId, studentId } = this.props
    fetchOutcomes(courseId, studentId)
      .then(({ outcomeGroups, outcomes }) => {
        this.setState({ outcomeGroups, outcomes })
      })
      .then(() => this.setState({ loading: false }))
      .catch((e) => this.setState({ loading: false, error: e }))
  }

  contract () {
    if (this.groups) {
      this.groups.forEach((g) => {
        if (g) {
          g.contract()
        }
      })
    }
  }

  expand () {
    if (this.groups) {
      this.groups.forEach((g) => {
        if (g) {
          g.expand()
        }
      })
    }
  }

  renderLoading () {
    return (
      <Flex justifyItems="center" alignItems="center" padding="medium">
        <FlexItem><Spinner size="large" title={I18n.t('Loading outcome results')} /></FlexItem>
      </Flex>
    )
  }

  renderError () {
    return (
      <Flex justifyItems="start" alignItems="center" padding="medium 0">
        <FlexItem><Text color="error">{ I18n.t('An error occurred loading outcomes data.') }</Text></FlexItem>
      </Flex>
    )
  }

  renderEmpty () {
    return (
      <Flex justifyItems="start" alignItems="center" padding="medium 0">
        <FlexItem><Text>{ I18n.t('There are no outcomes in the course.') }</Text></FlexItem>
      </Flex>
    )
  }

  renderGroups () {
    const { onExpansionChange } = this.props
    const { outcomes, outcomeGroups } = this.state
    this.groups = []
    return (
      <div>
        <List variant="unstyled">
          {
            outcomeGroups.map((outcomeGroup) => (
              <ListItem key={outcomeGroup.id}>
                <OutcomeGroup
                  outcomeGroup={outcomeGroup}
                  outcomes={outcomes.filter((o) => (o.groupId.toString() === outcomeGroup.id.toString() ))}
                  onExpansionChange={onExpansionChange}
                  ref={(group) => this.groups.push(group)}
               />
              </ListItem>
            ))
          }
        </List>
      </div>
    )
  }

  render () {
    const { error, loading, outcomeGroups } = this.state
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

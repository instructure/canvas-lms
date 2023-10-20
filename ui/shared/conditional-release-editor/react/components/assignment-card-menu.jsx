/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {IconMoreLine, IconEditLine, IconUpdownLine, IconTrashLine} from '@instructure/ui-icons'
import {List, Map} from 'immutable'

import Path from '../assignment-path'
import * as actions from '../actions'
import {useScope as useI18nScope} from '@canvas/i18n'
import {transformScore} from '../score-helpers'

const I18n = useI18nScope('conditional_release')

const {object, func} = PropTypes

export class AssignmentCardMenu extends React.Component {
  static get propTypes() {
    return {
      path: object.isRequired,
      ranges: object.isRequired,
      assignment: object.isRequired,
      removeAssignment: func.isRequired,
      triggerAssignment: object,

      // action props
      moveAssignment: func.isRequired,
      setAriaAlert: func.isRequired,
    }
  }

  handleMoveSelect(range, i) {
    const movePath = new Path(i, 0)
    this.props.moveAssignment(this.props.path, movePath, this.props.assignment.get('id').toString())

    this.props.setAriaAlert(
      I18n.t('Moved assignment %{name} to scoring range %{lower} - %{upper}', {
        name: this.props.assignment.get('name'),
        lower: transformScore(range.get('lower_bound'), this.props.triggerAssignment, false),
        upper: transformScore(range.get('upper_bound'), this.props.triggerAssignment, true),
      })
    )
  }

  createMoveSelectCallback(range, i) {
    return this.handleMoveSelect.bind(this, range, i)
  }

  renderMoveOptions() {
    return this.props.ranges
      .map((range, i) => {
        return (
          <Menu.Item key={range.get('id') || i} onSelect={this.createMoveSelectCallback(range, i)}>
            <IconUpdownLine />
            <View margin="0 0 0 x-small">
              {I18n.t('Move to %{lower} - %{upper}', {
                lower: transformScore(
                  range.get('lower_bound'),
                  this.props.triggerAssignment,
                  false
                ),
                upper: transformScore(range.get('upper_bound'), this.props.triggerAssignment, true),
              })}
            </View>
          </Menu.Item>
        )
      })
      .filter((range, i) => i !== this.props.path.range)
  }

  render() {
    return (
      <Menu
        trigger={
          <Button renderIcon={IconMoreLine}>
            <ScreenReaderContent>
              {I18n.t('assignment %{name} options', {name: this.props.assignment.get('name')})}
            </ScreenReaderContent>
          </Button>
        }
        placement="bottom start"
      >
        <Menu.Item
          onClick={() => window.open(this.props.assignment.get('html_url') + '/edit', '_blank')}
        >
          <IconEditLine /> <View margin="0 0 0 x-small">{I18n.t('Edit')}</View>
        </Menu.Item>
        {this.renderMoveOptions()}
        <Menu.Item onSelect={this.props.removeAssignment}>
          <IconTrashLine /> <View margin="0 0 0 x-small">{I18n.t('Remove')}</View>
        </Menu.Item>
      </Menu>
    )
  }
}

const ConnectedAssignmentCardMenu = connect(
  state => ({
    ranges: state.getIn(['rule', 'scoring_ranges'], List()),
    triggerAssignment: state.get('trigger_assignment', Map()),
  }),
  dispatch =>
    bindActionCreators(
      {
        moveAssignment: actions.moveAssignment,
        setAriaAlert: actions.setAriaAlert,
      },
      dispatch
    )
)(AssignmentCardMenu)

export default ConnectedAssignmentCardMenu

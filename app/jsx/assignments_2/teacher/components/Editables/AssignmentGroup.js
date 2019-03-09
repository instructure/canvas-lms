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
import {arrayOf, bool, func, oneOf, string} from 'prop-types'
import I18n from 'i18n!assignments_2'

import Text from '@instructure/ui-elements/lib/components/Text'

import SelectableText from './SelectableText'
import {AssignmentGroupShape} from '../../assignmentData'

export default class AssignmentGroup extends React.Component {
  static propTypes = {
    mode: oneOf(['edit', 'view']).isRequired,
    onChange: func.isRequired,
    onChangeMode: func.isRequired,
    onAddAssignmentGroup: func, // .isRequired  TODO: when support + New Assignment Group
    assignmentGroupList: arrayOf(AssignmentGroupShape),
    selectedAssignmentGroupId: string, // the group lid
    readOnly: bool
  }

  static defaultProps = {
    assignmentGroupList: [],
    readOnly: true
  }

  assignmentGroupPlaceholder = I18n.t('No Assignment Group Assigned')

  handleGroupChange = selection => {
    this.props.onChange(selection && selection.value)
  }

  handleGroupChangeMode = mode => {
    if (!this.props.readOnly) {
      this.props.onChangeMode(mode)
    }
  }

  // TODO: support +Group
  // handleChangeSelection = selection => {
  //   const add = !!selection.find(s => s.value === 'add')
  //   if (add) {
  //     const currentSelected = selection.filter(s => s.value !== 'add')
  //     // 1. open a popup to create a new group
  //     // 2. tell our client about the new group
  //     // 3. the client should
  //     //    i. create the group (synchronously?)
  //     //    ii. add this group to the groupList and set selectedAssignmentGroupId
  //     this.props.onAddAssignmentGroup({name: 'new mod'}, currentSelected)
  //   }
  // }

  getAssignmentGroupOptions() {
    let opts = [] // TODO: support adding [{label: I18n.t('+ Assignment Group'), value: 'add'}]
    if (this.props.assignmentGroupList) {
      opts = opts.concat(this.props.assignmentGroupList.map(g => ({label: g.name, value: g.lid})))
    }
    return opts
  }

  renderGroupView = groupOption => {
    const selectedGroup =
      groupOption && this.props.assignmentGroupList.find(g => g.lid === groupOption.value)
    if (!selectedGroup) {
      return <Text weight="light">{this.assignmentGroupPlaceholder}</Text>
    } else {
      return <Text>{selectedGroup.name}</Text>
    }
  }

  render() {
    const options = this.getAssignmentGroupOptions()
    const group = options.find(g => g.value === this.props.selectedAssignmentGroupId)
    return (
      <div data-testid="AssignmentGroup">
        <SelectableText
          mode={this.props.mode}
          label={I18n.t('Assignment Group')}
          value={group}
          onChange={this.handleGroupChange}
          onChangeMode={this.handleGroupChangeMode}
          onChangeSelection={this.handleChangeSelection}
          renderView={this.renderGroupView}
          size="medium"
          readOnly={this.props.readOnly}
          options={options}
        />
      </div>
    )
  }
}

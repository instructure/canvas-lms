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
import {useScope as createI18nScope} from '@canvas/i18n'
import produce from 'immer'
import get from 'lodash/get'
import set from 'lodash/set'
import {Query} from '@apollo/client/react/components'
import {Text} from '@instructure/ui-text'
import SelectableText from './SelectableText'
import {
  COURSE_ASSIGNMENT_GROUPS_QUERY,
  COURSE_ASSIGNMENT_GROUPS_QUERY_LOCAL,
} from '../../assignmentData'

const I18n = createI18nScope('assignments_2')

interface AssignmentGroupUIProps {
  mode: 'edit' | 'view'
  onChange: (group: any) => void
  onChangeMode: (mode: string) => void
  onAddAssignmentGroup?: (group: any, selected: any) => void
  assignmentGroupList?: any[]
  selectedAssignmentGroup?: any
  readOnly?: boolean
  isLoading?: boolean
  courseId?: string
  onAddModule?: any
}

interface AssignmentGroupProps {
  mode: 'edit' | 'view'
  onChange: (group: any) => void
  onChangeMode: (mode: string) => void
  onAddAssignmentGroup?: (group: any, selected: any) => void
  assignmentGroupList?: any[]
  selectedAssignmentGroup?: any
  readOnly?: boolean
  courseId?: string
}

const assignmentGroupPlaceholder = I18n.t('No Assignment Group Assigned')

class AssignmentGroupUI extends React.Component<AssignmentGroupUIProps> {
  static defaultProps = {
    assignmentGroupList: [],
    readOnly: false,
    isLoading: false,
  }

  handleGroupChange = (selection: any) => {
    const group = this.props.assignmentGroupList?.find(g => g.lid === selection.value)
    this.props.onChange(group)
  }

  handleGroupChangeMode = (mode: string) => {
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
    let opts: Array<{label: string; value: string}> = [] // TODO: support adding [{label: I18n.t('+ Assignment Group'), value: 'add'}]
    if (this.props.assignmentGroupList && this.props.assignmentGroupList.length) {
      opts = opts.concat(this.props.assignmentGroupList.map(g => ({label: g.name, value: g.lid})))
    } else if (this.props.selectedAssignmentGroup) {
      opts.push({
        label: this.props.selectedAssignmentGroup.name,
        value: this.props.selectedAssignmentGroup.lid,
      })
    }
    return opts
  }

  renderGroupView = (groupOption: any) => {
    if (!groupOption) {
      return <Text weight="light">{assignmentGroupPlaceholder}</Text>
    } else {
      return <Text>{groupOption.label}</Text>
    }
  }

  render() {
    const options = this.getAssignmentGroupOptions()
    const group =
      this.props.selectedAssignmentGroup &&
      options.find(g => g.value === this.props.selectedAssignmentGroup.lid)
    return (
      <div data-testid="AssignmentGroup">
        <SelectableText
          key="assignment-group-select"
          id="assignment-group"
          mode={this.props.mode}
          label={I18n.t('Assignment Group')}
          value={group}
          onChange={this.handleGroupChange}
          onChangeMode={this.handleGroupChangeMode}
          onChangeSelection={undefined}
          renderView={this.renderGroupView}
          size="medium"
          readOnly={this.props.readOnly}
          options={options}
          loadingText={this.props.isLoading ? I18n.t('Loading...') : null}
        />
      </div>
    )
  }
}
const AssignmentGroup = function (props: AssignmentGroupProps) {
  const q =
    props.mode === 'edit' ? COURSE_ASSIGNMENT_GROUPS_QUERY : COURSE_ASSIGNMENT_GROUPS_QUERY_LOCAL
  let groups = []
  let isLoading = false
  return (
    <Query query={q} variables={{courseId: props.courseId}}>
      {({data, loading, fetchMore}: any) => {
        if (loading) {
          isLoading = true
        } else if (props.mode === 'edit') {
          isLoading = depaginate(fetchMore, data)
        } else {
          isLoading = false
        }
        groups = get(data, 'course.assignmentGroupsConnection.nodes')
        return (
          <AssignmentGroupUI
            key="assignment-group"
            mode={props.mode}
            courseId={props.courseId}
            selectedAssignmentGroup={props.selectedAssignmentGroup}
            assignmentGroupList={isLoading ? null : groups}
            onChange={props.onChange}
            onChangeMode={props.onChangeMode}
            onAddModule={(props as any).onAddModule}
            readOnly={props.readOnly}
            isLoading={isLoading}
          />
        )
      }}
    </Query>
  )
}

AssignmentGroup.defaultProps = {
  assignmentGroupList: [],
  readOnly: false,
}

// As long's as there's another page of data, go get it
function depaginate(fetchMore: any, data: any) {
  let isLoading = false
  // We no longer have a request in-flight, see if we need to get another page
  if (data.course.assignmentGroupsConnection.pageInfo.hasNextPage) {
    fetchMore({
      variables: {cursor: data.course.assignmentGroupsConnection.pageInfo.endCursor},
      updateQuery: mergeThePage,
    })
    isLoading = true
  }
  return isLoading
}

// merge the new result into the existing data
function mergeThePage(previousResult: any, {fetchMoreResult}: any) {
  const newGroups = fetchMoreResult.course.assignmentGroupsConnection.nodes
  const pageInfo = fetchMoreResult.course.assignmentGroupsConnection.pageInfo
  // using immer.produce let's me base the merge result on
  // fetchMoreResult w/o having to do a deep copy first
  const result = produce(fetchMoreResult, (draft: any) => {
    let r = set(draft, 'course.pageInfo', pageInfo)
    r = set(
      r,
      'course.assignmentGroupsConnection.nodes',
      previousResult.course.assignmentGroupsConnection.nodes.concat(newGroups),
    )
    return r
  })
  return result
}

export default AssignmentGroup
export {AssignmentGroupUI}

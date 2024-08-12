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
import {useScope as useI18nScope} from '@canvas/i18n'
import produce from 'immer'
import get from 'lodash/get'
import set from 'lodash/set'
import {Query, withApollo} from 'react-apollo'

import {Text} from '@instructure/ui-text'

import SelectableText from './SelectableText'
import {ModuleShape, COURSE_MODULES_QUERY, COURSE_MODULES_QUERY_LOCAL} from '../../assignmentData'

const I18n = useI18nScope('assignments_2')

const AssignmentModulesPropTypes = {
  mode: oneOf(['edit', 'view']).isRequired,
  onChange: func.isRequired,
  onChangeMode: func.isRequired,
  onAddModule: func, // .isRequired TODO when support +Module,
  moduleList: arrayOf(ModuleShape),
  selectedModules: arrayOf(ModuleShape),
  readOnly: bool,
}

// eslint doesn't deal with the prop types being defined this way
/* eslint-disable react/default-props-match-prop-types */
const AssignmentModulesDefaultProps = {
  moduleList: [],
  selectedModules: [],
  readOnly: true,
}
/* eslint-enable react/default-props-match-prop-types */

class AssignmentModulesUI extends React.Component {
  static propTypes = {
    ...AssignmentModulesPropTypes,
    isLoading: bool,
  }

  static defaultProps = {
    ...AssignmentModulesDefaultProps,
    isLoading: false,
  }

  modulePlaceholder = I18n.t('No Module Assigned')

  handleModulesChange = selection => {
    const selectedModules = selection.map(s => ({
      lid: s.value,
      name: s.label,
    }))
    this.props.onChange(selectedModules)
  }

  handleModulesChangeMode = mode => {
    if (!this.props.readOnly) {
      this.props.onChangeMode(mode)
    }
  }

  // TODO: support +Module
  // handleChangeSelection = selection => {
  //   const add = !!selection.find(s => s.value === 'add')
  //   if (add) {
  //     const currentSelected = selection.filter(s => s.value !== 'add')
  //     // 1. open a popup to create a new module
  //     // 2. tell our client about the new module
  //     // 3. the client should
  //     //    i. create the modal (synchronously?)
  //     //    ii. add this module to the moduleList and selectedModules
  //     this.props.onAddModule({name: 'new mod'}, currentSelected)
  //   }
  // }

  renderModulesView = selectedModuleOptions => {
    if (selectedModuleOptions.length) {
      // TODO: this used to use TruncateText but that has perf. issues. Do something else.
      return <Text>{selectedModuleOptions.map(module => module.label).join(' | ')}</Text>
    }
    return <Text weight="light">{this.modulePlaceholder}</Text>
  }

  // This confused me. While the <options> passed as children to the Select
  // are option elements, the selectedOption prop and the selection passed back to the onChange
  // handler are not, but something with the shape {label, value} plus other optional props
  // (see SelectMultiple/index.js in the instui repo)
  // From the outside, lets interact with SelectableText using the {label, value} objects.
  getModuleOptions() {
    let selected = []
    const common = [] // TODO: when support +Module [{label: I18n.t('+ Module'), value: 'add'}]
    let opts = []
    if (this.props.moduleList && this.props.moduleList.length) {
      opts = this.props.moduleList.map(m => {
        const opt = {label: m.name, value: m.lid}
        if (this.props.selectedModules.find(mod => mod.lid === m.lid)) {
          selected.push(opt)
        }
        return opt
      })
    } else if (this.props.selectedModules && this.props.selectedModules.length) {
      opts = selected = this.props.selectedModules.map(m => ({label: m.name, value: m.lid}))
    }
    return {allOptions: common.concat(opts), selectedOptions: selected}
  }

  render() {
    const {allOptions, selectedOptions} = this.getModuleOptions()
    return (
      <div data-testid="AssignmentModules">
        <SelectableText
          mode={this.props.mode}
          label={I18n.t('modules')}
          value={selectedOptions}
          onChange={this.handleModulesChange}
          onChangeMode={this.handleModulesChangeMode}
          onChangeSelection={this.handleChangeSelection}
          renderView={this.renderModulesView}
          size="medium"
          multiple={true}
          options={allOptions}
          readOnly={this.props.readOnly}
          loadingText={this.props.isLoading ? I18n.t('Loading...') : null}
        />
      </div>
    )
  }
}

const AssignmentModules = function (props) {
  const q = props.mode === 'edit' ? COURSE_MODULES_QUERY : COURSE_MODULES_QUERY_LOCAL

  let modules = []
  let isLoading = false
  return (
    <Query query={q} variables={{courseId: props.courseId}}>
      {({data, loading, fetchMore}) => {
        if (loading) {
          isLoading = true
        } else if (props.mode === 'edit') {
          isLoading = depaginate(fetchMore, data)
        } else {
          isLoading = false
        }
        modules = get(data, 'course.modulesConnection.nodes')
        return (
          <AssignmentModulesUI
            key="assignment-modules"
            mode={props.mode}
            selectedModules={props.selectedModules}
            moduleList={isLoading ? null : modules}
            onChange={props.onChange}
            onChangeMode={props.onChangeMode}
            onAddModule={props.onAddModule}
            readOnly={props.readOnly}
            isLoading={isLoading}
          />
        )
      }}
    </Query>
  )
}

AssignmentModules.propTypes = {
  ...AssignmentModulesPropTypes,
  courseId: string.isRequired,
}

AssignmentModules.defaultProps = AssignmentModulesDefaultProps

// As long as there's another page of data, go get it
function depaginate(fetchMore, data) {
  let isLoading = false
  if (data.course.modulesConnection.pageInfo.hasNextPage) {
    fetchMore({
      variables: {cursor: data.course.modulesConnection.pageInfo.endCursor},
      updateQuery: mergeThePage,
    })
    isLoading = true
  }
  return isLoading
}

// merge the new result into the existing data
function mergeThePage(previousResult, {fetchMoreResult}) {
  const newModules = fetchMoreResult.course.modulesConnection.nodes
  const pageInfo = fetchMoreResult.course.modulesConnection.pageInfo
  // using immer.produce let's me base the merge result on
  // fetchMoreResult w/o having to do a deep copy first
  const result = produce(fetchMoreResult, draft => {
    let r = set(draft, 'course.pageInfo', pageInfo)
    r = set(
      r,
      'course.modulesConnection.nodes',
      previousResult.course.modulesConnection.nodes.concat(newModules)
    )
    return r
  })
  return result
}

export default withApollo(AssignmentModules)
export {AssignmentModulesUI}

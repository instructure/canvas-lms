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
import {arrayOf, bool, func, oneOf} from 'prop-types'
import I18n from 'i18n!assignments_2'

import Text from '@instructure/ui-elements/lib/components/Text'
import TruncateText from '@instructure/ui-elements/lib/components/TruncateText'

import SelectableText from './SelectableText'
import {ModuleShape} from '../../assignmentData'

export default class AssignmentModules extends React.Component {
  static propTypes = {
    mode: oneOf(['edit', 'view']).isRequired,
    onChange: func.isRequired,
    onChangeMode: func.isRequired,
    onAddModule: func, // .isRequired TODO when support +Module,
    moduleList: arrayOf(ModuleShape),
    selectedModules: arrayOf(ModuleShape),
    readOnly: bool
  }

  static defaultProps = {
    selectedModules: [],
    readOnly: true
  }

  modulePlaceholder = I18n.t('No Module Assigned')

  handleModulesChange = selection => {
    const selectedModuleIds = selection.map(s => s.value)
    const selectedModules = this.moduleIdsToModules(selectedModuleIds)
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

  // given an array of module IDs, return the corresponding array of modules
  // always returns a (possibly empty) array
  moduleIdsToModules(moduleIds) {
    let selectedModules = []
    if (moduleIds) {
      selectedModules = this.props.moduleList.reduce((list, currentModule) => {
        if (moduleIds.find(mid => mid === currentModule.lid)) {
          list.push(currentModule)
        }
        return list
      }, [])
    }
    return selectedModules
  }

  renderModulesView = selectedModuleOptions => {
    const selectedModuleIds = selectedModuleOptions && selectedModuleOptions.map(m => m.value)
    const selectedModules = this.moduleIdsToModules(selectedModuleIds)

    if (selectedModuleOptions.length) {
      return (
        <Text>
          <TruncateText>{selectedModules.map(module => module.name).join(' | ')}</TruncateText>
        </Text>
      )
    }
    return <Text weight="light">{this.modulePlaceholder}</Text>
  }

  // This confused me. While the <options> passed as children to the Select
  // are option elements, the selectedOption prop and the selection passed back to the onChange
  // handler are not, but something with the shape {label, value} plus other optional props
  // (see SelectMultiple/index.js in the instui repo)
  // From the outside, lets interact with SelectableText using the {label, value} objects.
  getModuleOptions() {
    const selected = []
    const common = [] // TODO: when support +Module [{label: I18n.t('+ Module'), value: 'add'}]
    let opts = []
    opts = this.props.moduleList.map(m => {
      const opt = {label: m.name, value: m.lid}
      if (this.props.selectedModules.find(mod => mod.lid === m.lid)) {
        selected.push(opt)
      }
      return opt
    })
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
          multiple
          options={allOptions}
          readOnly={this.props.readOnly}
        />
      </div>
    )
  }
}

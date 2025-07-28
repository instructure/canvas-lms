/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {createRoot} from 'react-dom/client'
import {connect, Provider} from 'react-redux'
import BreakdownGraphs from './components/breakdown-graphs'
import BreakdownDetails from './components/breakdown-details'

const Graphs = connect(state => ({
  assignment: state.assignment,
  ranges: state.ranges,
  enrolled: state.enrolled,
  isLoading: state.isInitialDataLoading,
}))(BreakdownGraphs)

const Details = connect(state => ({
  isStudentDetailsLoading: state.isStudentDetailsLoading,
  selectedPath: state.selectedPath,
  assignment: state.assignment,
  ranges: state.ranges,
  students: state.studentCache,
  showDetails: state.showDetails,
}))(BreakdownDetails)

export default class CRSApp {
  constructor(store, actions) {
    this.store = store
    this.actions = actions
    this.graphsRoot = null
    this.detailsRoot = null
  }

  renderGraphs(root) {
    if (!root) {
      throw new Error('Failed to find the graphs root element')
    }
    const actions = {
      openSidebar: this.actions.openSidebar,
      selectRange: this.actions.selectRange,
    }

    if (!this.graphsRoot) {
      this.graphsRoot = createRoot(root)
    }
    this.graphsRoot.render(
      <Provider store={this.store}>
        <Graphs {...actions} />
      </Provider>,
    )
  }

  renderDetails(root) {
    if (!root) {
      throw new Error('Failed to find the details root element')
    }
    const detailActions = {
      selectRange: this.actions.selectRange,
      selectStudent: this.actions.selectStudent,
      closeSidebar: this.actions.closeSidebar,
    }

    if (!this.detailsRoot) {
      this.detailsRoot = createRoot(root)
    }
    this.detailsRoot.render(
      <Provider store={this.store}>
        <Details {...detailActions} />
      </Provider>,
    )
  }
}

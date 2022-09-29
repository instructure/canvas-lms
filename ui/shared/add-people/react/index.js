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
import ReactDOM from 'react-dom'
import {bindActionCreators} from 'redux'
import {connect, Provider} from 'react-redux'
import natcompare from '@canvas/util/natcompare'
import {createStore, defaultState} from './store'
import {actions} from './actions'
import reducer from './reducer'
import AddPeople from './components/add_people'

export default class AddPeopleApp {
  constructor(root, props) {
    this.root = root // DOM node we render into
    this.closer = this.close.bind(this) // close us
    this.onCloseCallback = props.onClose // tell our parent
    this.theme = props.theme || 'canvas'

    // natural sort the sections by name
    let sections = props.sections || []
    sections = sections.slice().sort(natcompare.byKey('name'))

    // create the store with its initial state
    // some values are default, some come from props
    this.store = createStore(reducer, {
      courseParams: {
        courseId: props.courseId || 0,
        courseName: props.courseName || '',
        defaultInstitutionName: props.defaultInstitutionName || '',
        roles: props.roles || [],
        sections,
        inviteUsersURL: props.inviteUsersURL,
      },
      inputParams: {
        searchType: defaultState.inputParams.searchType,
        nameList: defaultState.inputParams.nameList,
        role: props.roles.length ? props.roles[0].id : '',
        section: sections.length ? sections[0].id : '',
        canReadSIS: props.canReadSIS,
      },
      apiState: defaultState.apiState,
      userValidationResult: defaultState.userValidationResult,
      usersToBeEnrolled: defaultState.usersToBeEnrolled,
    })

    // when ConnectedApp is rendered, these state members are passed as props
    function mapStateToProps(state) {
      return {...state}
    }

    // when ConnectedApp is rendered, all the action dispatch functions are passed as props
    const mapDispatchToProps = dispatch => bindActionCreators(actions, dispatch)

    // connect our top-level component to redux
    this.ConnectedApp = connect(mapStateToProps, mapDispatchToProps)(AddPeople)
  }

  open() {
    this.render(true)
  }

  close() {
    this.render(false)
    if (typeof this.onCloseCallback === 'function') {
      this.onCloseCallback()
    }
  }

  // used by the roster page to decide if it has to requry for the course's
  // enrollees
  usersHaveBeenEnrolled() {
    return this.store.getState().usersEnrolled
  }

  unmount() {
    ReactDOM.unmountComponentAtNode(this.root)
  }

  render(isOpen) {
    const ConnectedApp = this.ConnectedApp
    ReactDOM.render(
      <Provider store={this.store}>
        <ConnectedApp isOpen={isOpen} onClose={this.closer} theme={this.theme} />
      </Provider>,
      this.root
    )
  }
}

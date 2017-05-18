/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from 'i18n!blueprint_courses'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'

import BlueprintModal from './BlueprintModal'
import MasterChildStack from './MasterChildStack'
import { ConnectedChildChangeLog as ChildChangeLog } from './ChildChangeLog'

import actions from '../actions'
import propTypes from '../propTypes'

export default class ChildContent extends Component {
  static propTypes = {
    realRef: PropTypes.func,
    isChangeLogOpen: PropTypes.bool.isRequired,
    goTo: PropTypes.func.isRequired,
    selectChangeLog: PropTypes.func.isRequired,
    terms: propTypes.termList.isRequired,
    childCourse: propTypes.courseInfo.isRequired,
    masterCourse: propTypes.courseInfo.isRequired,
  }

  static defaultProps = {
    realRef: () => {},
  }

  componentDidMount () {
    this.props.realRef(this)
  }

  clearRoutes = () => {
    this.props.goTo('')
  }

  showChangeLog (changeId) {
    this.props.selectChangeLog({ changeId })
  }

  hideChangeLog () {
    this.props.selectChangeLog({ changeId: null })
  }

  render () {
    const { terms, childCourse, masterCourse, isChangeLogOpen } = this.props
    const childTerm = terms.find(term => term.id === childCourse.enrollment_term_id)
    const childTermName = childTerm ? childTerm.name : ''

    return (
      <div className="bcc__wrapper">
        <BlueprintModal
          wide
          title={I18n.t('Blueprint Course Information: %{term} - %{course}', { term: childTermName, course: childCourse.name })}
          isOpen={isChangeLogOpen}
          onCancel={this.clearRoutes}
        >
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <MasterChildStack
                terms={terms}
                child={childCourse}
                master={masterCourse}
              />
              <div style={{ width: '870px' }}>
                <ChildChangeLog />
              </div>
            </div>
          </div>
        </BlueprintModal>
      </div>
    )
  }
}

const connectState = state => ({
  isChangeLogOpen: !!state.selectedChangeLog,
  childCourse: state.course,
  masterCourse: state.masterCourse,
  terms: state.terms,
})
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedChildContent = connect(connectState, connectActions)(ChildContent)

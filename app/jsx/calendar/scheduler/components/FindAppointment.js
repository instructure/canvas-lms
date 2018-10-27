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
import PropTypes from 'prop-types'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Modal, {ModalBody, ModalFooter} from '../../../shared/components/InstuiModal'
import I18n from 'i18n!react_scheduler'
import Actions from '../../../calendar/scheduler/actions'
import preventDefault from 'compiled/fn/preventDefault'

export default class FindAppointment extends React.Component {
  static propTypes = {
    courses: PropTypes.array.isRequired,
    store: PropTypes.object.isRequired
  }

  state = {
    isModalOpen: false,
    selectedCourse: {}
  }

  handleSubmit() {
    this.props.store.dispatch(Actions.actions.setCourse(this.state.selectedCourse))
    this.props.store.dispatch(Actions.actions.setFindAppointmentMode(!this.props.store.getState().inFindAppointmentMode))
    this.setState({
      isModalOpen: false,
      selectedCourse: {}
    })
  }
  selectCourse(courseId) {
    this.setState({
      selectedCourse: this.props.courses.filter(c => c.id === courseId)[0]
    })
  }
  openModal() {
    this.setState({
      isModalOpen: true,
      selectedCourse: this.props.courses.length > 0 ? this.props.courses[0] : {}
    })
  }
  endAppointmentMode() {
    this.props.store.dispatch(Actions.actions.setFindAppointmentMode(false))
    this.setState({isModalOpen: false})
  }

  render() {
    return (
      <div>
        <h2>{I18n.t('Appointments')}</h2>
        {this.props.store.getState().inFindAppointmentMode ? (
          <button
            onClick={() => this.endAppointmentMode()}
            id="FindAppointmentButton"
            className="Button"
          >
            {I18n.t('Close')}
          </button>
        ) : (
          <button onClick={() => this.openModal()} id="FindAppointmentButton" className="Button">
            {I18n.t('Find Appointment')}
          </button>
        )}
        <Modal
          as="form"
          onSubmit={preventDefault(() => this.handleSubmit())}
          open={this.state.isModalOpen}
          ref={c => (this.modal = c)}
          size="small"
          onDismiss={() => this.setState({isModalOpen: false})}
          label={I18n.t('Select Course')}
        >
          <ModalBody>
            <div className="ic-Form-control">
              <select
                onChange={e => this.selectCourse(e.target.value)}
                value={this.state.selectedCourse.id}
                className="ic-Input"
              >
                {this.props.courses.map(c =>
                  <option key={c.id} value={c.id}>{c.name}</option>
                )}
              </select>
            </div>
          </ModalBody>
          <ModalFooter>
            <Button variant="primary" type="submit">{I18n.t('Submit')}</Button>
          </ModalFooter>
        </Modal>
      </div>
    )
  }
}

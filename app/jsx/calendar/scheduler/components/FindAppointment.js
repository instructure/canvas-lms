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
import Modal from 'react-modal'
import I18n from 'i18n!react_scheduler'
import Actions from '../../../calendar/scheduler/actions'

  class FindAppointment extends React.Component {

    static propTypes = {
      courses: PropTypes.array.isRequired,
      store: PropTypes.object.isRequired,
    }

    constructor (props) {
      super(props)
      this.state = {
        isModalOpen: false,
        selectedCourse: {}
      }
      this.openModal = this.openModal.bind(this)
      this.closeModal = this.closeModal.bind(this)
      this.handleSubmit = this.handleSubmit.bind(this)
      this.endAppointmentMode = this.endAppointmentMode.bind(this)
      this.selectCourse = this.selectCourse.bind(this)
    }

    handleSubmit () {
      document.getElementById("FindAppointmentButton").focus()
      this.props.store.dispatch(Actions.actions.setCourse(this.state.selectedCourse))
      this.props.store.dispatch(Actions.actions.setFindAppointmentMode(!this.props.store.getState().inFindAppointmentMode))
      this.setState ({
        isModalOpen: false,
        selectedCourse: {}
      })
    }
    selectCourse (e) {
      this.setState({
        selectedCourse: this.props.courses.filter((c) => c.id === e.target.value)[0]
      })
    }
    openModal () {
      this.setState({
        isModalOpen: true,
        selectedCourse: (this.props.courses.length > 0) ? this.props.courses[0] : {}
      })
    }
    endAppointmentMode () {
      this.props.store.dispatch(Actions.actions.setFindAppointmentMode(false))
      this.setState({
        isModalOpen: false,
      })
    }

    closeModal () {
      document.getElementById("FindAppointmentButton").focus()
      this.setState({
        isModalOpen: false,
      })
    }

    render () {
      return (
        <div>
          <h2>{I18n.t('Appointments')}</h2>
          {
            this.props.store.getState().inFindAppointmentMode ?
              <button onClick={this.endAppointmentMode} id="FindAppointmentButton" className="Button">{I18n.t('Close')}</button>
              :
              <button onClick={this.openModal} id="FindAppointmentButton" className="Button">{I18n.t('Find Appointment')}</button>
          }
          <Modal
            isOpen={this.state.isModalOpen}
            ref={c => this.modal = c}
            title={I18n.t("Select Course")}
            className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
          >
          <div className="ReactModal__Layout">
            <div className="ReactModal__Header">
              <div className="ReactModal__Header-Title">
                <h4>{I18n.t('Select Course')}</h4>
              </div>
              <div className="ReactModal__Header-Actions">
                <button className="Button Button--icon-action" type="button" onClick={this.closeModal}>
                  <i className="icon-x"></i>
                  <span className="screenreader-only">Close</span>
                </button>
              </div>
            </div>
            <div className="ReactModal__Body">
              <div className="ic-Form-control">
                <select onChange={this.selectCourse} value={this.state.selectedCourse.id} className="ic-Input">
                  {this.props.courses.map((c, index) => {
                    return(<option key={c.id} value={c.id}>{c.name}</option>)
                  })}
                </select>
              </div>
            </div>
            <div className="ReactModal__Footer-Scheduler">
              <div className="ReactModal__Footer-Actions">
                <button type="submit" onClick={this.handleSubmit} className="btn btn-primary">Submit</button>
              </div>
            </div>
          </div>
          </Modal>
        </div>
      );
    }
  }

export default FindAppointment

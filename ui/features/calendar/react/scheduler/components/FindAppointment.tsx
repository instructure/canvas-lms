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
import {Button} from '@instructure/ui-buttons'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {useScope as createI18nScope} from '@canvas/i18n'
import Actions from '../actions'
import preventDefault from '@canvas/util/preventDefault'

const I18n = createI18nScope('react_scheduler')

export default class FindAppointment extends React.Component {
  static propTypes = {
    courses: PropTypes.array.isRequired,
    store: PropTypes.object.isRequired,
  }

  state = {
    isModalOpen: false,
    selectedCourse: {},
  }

  handleSubmit() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.store.dispatch(Actions.actions.setCourse(this.state.selectedCourse))
    // @ts-expect-error TS2339 (typescriptify)
    this.props.store.dispatch(
      // @ts-expect-error TS2339 (typescriptify)
      Actions.actions.setFindAppointmentMode(!this.props.store.getState().inFindAppointmentMode),
    )
    this.setState({
      isModalOpen: false,
      selectedCourse: {},
    })
  }

  // @ts-expect-error TS7006 (typescriptify)
  selectCourse(courseId) {
    this.setState({
      // @ts-expect-error TS2339,TS7006 (typescriptify)
      selectedCourse: this.props.courses.filter(c => c.id === courseId)[0],
    })
  }

  openModal() {
    this.setState({
      isModalOpen: true,
      // @ts-expect-error TS2339 (typescriptify)
      selectedCourse: this.props.courses.length > 0 ? this.props.courses[0] : {},
    })
  }

  endAppointmentMode() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.store.dispatch(Actions.actions.setFindAppointmentMode(false))
    this.setState({isModalOpen: false})
  }

  render() {
    return (
      <div>
        <h2>{I18n.t('Appointments')}</h2>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.props.store.getState().inFindAppointmentMode ? (
          <button
            type="button"
            onClick={() => this.endAppointmentMode()}
            id="FindAppointmentButton"
            className="Button"
            data-testid="find-appointment-close-button"
          >
            {I18n.t('Close')}
          </button>
        ) : (
          <button
            type="button"
            onClick={() => this.openModal()}
            id="FindAppointmentButton"
            className="Button"
            data-testid="find-appointment-button"
          >
            {I18n.t('Find Appointment')}
          </button>
        )}
        <Modal
          as="form"
          onSubmit={preventDefault(() => this.handleSubmit())}
          open={this.state.isModalOpen}
          size="small"
          onDismiss={() => this.setState({isModalOpen: false})}
          label={I18n.t('Select Course')}
        >
          <Modal.Body>
            <div className="ic-Form-control">
              <select
                onChange={e => this.selectCourse(e.target.value)}
                // @ts-expect-error TS2339 (typescriptify)
                value={this.state.selectedCourse.id}
                className="ic-Input"
                data-testid="select-course"
              >
                {/* @ts-expect-error TS2339,TS7006 (typescriptify) */}
                {this.props.courses.map(c => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
          </Modal.Body>
          <Modal.Footer>
            <Button color="primary" type="submit">
              {I18n.t('Submit')}
            </Button>
          </Modal.Footer>
        </Modal>
      </div>
    )
  }
}

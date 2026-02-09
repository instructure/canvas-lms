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

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Button} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Checkbox} from '@instructure/ui-checkbox'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import '@canvas/rails-flash-notifications'
import '@canvas/jquery/jquery.instructure_forms'
import {unfudgeDateForProfileTimezone} from '@instructure/moment-utils'
import EventDataSource from '@canvas/calendar/jquery/EventDataSource'
import MessageParticipantsDialog from '@canvas/calendar/jquery/MessageParticipantsDialog'
import axios from '@canvas/axios'
import {assignLocation} from '@canvas/util/globalUtils'
import AppointmentGroupList from './AppointmentGroupList'
import ContextSelector from './ContextSelector'
import TimeBlockSelector from './TimeBlockSelector'

const I18n = createI18nScope('appointment_groups')

// @ts-expect-error TS7006 (typescriptify)
const parseFormValues = data => ({
  description: data.description,
  location: data.location_name,
  title: data.title,
  limitUsersPerSlot: data.participants_per_appointment,
  limitSlotsPerUser: data.max_appointments_per_participant,
  allowStudentsToView: data.participant_visibility === 'protected',
  allowObserverSignup: data.allow_observer_signup,
})

// @ts-expect-error TS7006 (typescriptify)
const parseTimeData = appointmentGroup => {
  if (!appointmentGroup.appointments) {
    return []
  }
  // @ts-expect-error TS7006 (typescriptify)
  return appointmentGroup.appointments.map(appointment => ({
    timeData: {
      date: appointment.start_at,
      startTime: appointment.start_at,
      endTime: appointment.end_at,
    },
    slotEventId: appointment.id.toString(),
  }))
}

// @ts-expect-error TS7006 (typescriptify)
const nullTimeFilter = timeBlock =>
  timeBlock.timeData.date != null ||
  timeBlock.timeData.startTime != null ||
  timeBlock.timeData.endTime != null

class EditPage extends React.Component {
  static propTypes = {
    appointment_group_id: PropTypes.string,
  }

  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)
    this.state = {
      appointmentGroup: {
        title: '',
        context_codes: [],
        sub_context_codes: [],
      },
      formValues: {
        title: '',
        description: '',
        location: '',
        limitUsersPerSlot: '',
        limitSlotsPerUser: '',
        allowStudentsToView: false,
        allowObserverSignup: false,
        timeblocks: [],
      },
      contexts: [],
      isDeleting: false,
      showDeleteModal: false,
      eventDataSource: null,
      selectedContexts: new Set(),
      selectedSubContexts: new Set(),
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  setSelectedContexts = selectedContexts => {
    this.setState({selectedContexts})
  }

  // @ts-expect-error TS7006 (typescriptify)
  setSelectedSubContexts = selectedSubContexts => {
    this.setState({selectedSubContexts})
  }

  componentDidMount() {
    axios
      .get(
        // @ts-expect-error TS2339 (typescriptify)
        `/api/v1/appointment_groups/${this.props.appointment_group_id}?include[]=appointments&include[]=child_events`,
      )
      .then(response => {
        const formValues = parseFormValues(response.data)
        this.setState(
          {
            formValues,
            appointmentGroup: response.data,
            selectedContexts: new Set(response.data.context_codes),
            selectedSubContexts: new Set(response.data.sub_context_codes),
          },
          () => {
            // Handle setting some pesky values
            // @ts-expect-error TS2339 (typescriptify)
            $('.EditPage__Options-LimitUsersPerSlot', this.optionFields).val(
              formValues.limitUsersPerSlot,
            )
            // @ts-expect-error TS2339 (typescriptify)
            $('.EditPage__Options-LimitSlotsPerUser', this.optionFields).val(
              formValues.limitSlotsPerUser,
            )
          },
        )
      })

    axios.get('/api/v1/calendar_events/visible_contexts').then(response => {
      // @ts-expect-error TS7006 (typescriptify)
      const contexts = response.data.contexts.filter(context =>
        context.asset_string.match(/^course_/),
      )
      this.setState({
        contexts,
        eventDataSource: new EventDataSource(contexts),
      })
    })
  }

  setTimeBlocks = (newTimeBlocks = []) => {
    // @ts-expect-error TS2339 (typescriptify)
    const formValues = Object.assign(this.state.formValues, {timeblocks: newTimeBlocks})
    this.setState({formValues})
  }

  // @ts-expect-error TS7006 (typescriptify)
  handleChange = e => {
    // @ts-expect-error TS2339 (typescriptify)
    const formValues = Object.assign(this.state.formValues, {
      [e.target.name]: e.target.value,
    })

    this.setState({formValues})
  }

  // @ts-expect-error TS7006 (typescriptify)
  handleCheckboxChange = e => {
    // @ts-expect-error TS2339 (typescriptify)
    const formValues = Object.assign(this.state.formValues, {
      [e.target.name]: e.target.checked,
    })

    this.setState({formValues})
  }

  messageStudents = () => {
    const messageStudentsDialog = new MessageParticipantsDialog({
      // @ts-expect-error TS2339 (typescriptify)
      group: this.state.appointmentGroup,
      // @ts-expect-error TS2339 (typescriptify)
      dataSource: this.state.eventDataSource,
    })
    messageStudentsDialog.show()
  }

  groupSubContextsSelected = () =>
    // @ts-expect-error TS2339 (typescriptify)
    [...this.state.selectedSubContexts].some(code => code.startsWith('group_'))

  observerSignupAllowed = () =>
    // @ts-expect-error TS2339 (typescriptify)
    this.state.contexts?.length > 0 &&
    !this.groupSubContextsSelected() &&
    // @ts-expect-error TS2339 (typescriptify)
    [...this.state.selectedContexts].every(
      context_code =>
        // @ts-expect-error TS2339,TS7006 (typescriptify)
        this.state.contexts.find(c => c.asset_string === context_code)
          ?.allow_observers_in_appointment_groups,
    )

  openDeleteModal = () => {
    this.setState({showDeleteModal: true})
  }

  closeDeleteModal = () => {
    this.setState({showDeleteModal: false})
  }

  confirmDelete = () => {
    this.setState({showDeleteModal: false}, () => {
      this.performDelete()
    })
  }

  performDelete = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.state.isDeleting) {
      this.setState({isDeleting: true}, () => {
        axios
          // @ts-expect-error TS2339 (typescriptify)
          .delete(`/api/v1/appointment_groups/${this.props.appointment_group_id}`)
          .then(() => {
            assignLocation('/calendar')
          })
          .catch(() => {
            $.flashError(I18n.t('An error occurred while deleting the appointment group'))
            this.setState({isDeleting: false})
          })
      })
    }
  }

  deleteGroup = () => {
    this.openDeleteModal()
  }

  handleSave = () => {
    // @ts-expect-error TS2339 (typescriptify)
    const formValues = {...this.state.formValues}
    if (formValues.limitUsersPerSlot) {
      // @ts-expect-error TS2339 (typescriptify)
      const $element = $('.EditPage__Options-LimitUsersPerSlot', this.optionFields)
      const value = $element.val()
      if (!value) {
        $element.errorBox(I18n.t('You must provide a value or unselect the option.'))
        return
        // @ts-expect-error TS2365 (typescriptify)
      } else if (value < 1) {
        $element.errorBox(I18n.t('You must allow at least one appointment per time slot.'))
        return
      }
      formValues.usersPerSlotLimit = value
    } else {
      formValues.usersPerSlotLimit = null
    }
    if (formValues.limitSlotsPerUser) {
      // @ts-expect-error TS2339 (typescriptify)
      const $element = $('.EditPage__Options-LimitSlotsPerUser', this.optionFields)
      const value = $element.val()
      if (!value) {
        $element.errorBox(I18n.t('You must provide a value or unselect the option.'))
        return
        // @ts-expect-error TS2365 (typescriptify)
      } else if (value < 1) {
        $element.errorBox(I18n.t('You must allow at least one appointment per participant.'))
        return
      }
      formValues.slotsPerUserLimit = value
    } else {
      formValues.slotsPerUserLimit = null
    }
    // @ts-expect-error TS2339 (typescriptify)
    const url = `/api/v1/appointment_groups/${this.props.appointment_group_id}`

    formValues.timeblocks = formValues.timeblocks || []

    const requestObj = {
      appointment_group: {
        title: formValues.title,
        description: formValues.description,
        location_name: formValues.location,
        participants_per_appointment: formValues.usersPerSlotLimit,
        participant_visibility: formValues.allowStudentsToView ? 'protected' : 'private',
        max_appointments_per_participant: formValues.slotsPerUserLimit,
        new_appointments: formValues.timeblocks
          .filter(nullTimeFilter)
          // @ts-expect-error TS7006 (typescriptify)
          .map(tb => [
            unfudgeDateForProfileTimezone(tb.timeData.startTime),
            unfudgeDateForProfileTimezone(tb.timeData.endTime),
          ]),
        // @ts-expect-error TS2339 (typescriptify)
        context_codes: [...this.state.selectedContexts],
        // @ts-expect-error TS2339 (typescriptify)
        sub_context_codes: [...this.state.selectedSubContexts],
        allow_observer_signup: this.observerSignupAllowed() && formValues.allowObserverSignup,
      },
    }

    axios
      .put(url, requestObj)
      .then(() => {
        assignLocation('/calendar?edit_appointment_group_success=1')
      })
      .catch(() => {
        $.flashError(I18n.t('An error occurred while saving the appointment group'))
      })
  }

  render() {
    return (
      <div className="EditPage" data-testid="edit-page">
        <Breadcrumb label={I18n.t('You are here:')}>
          <Breadcrumb.Link href="/calendar">{I18n.t('Calendar')}</Breadcrumb.Link>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          {...(this.state.appointmentGroup.title
            ? [
                <Breadcrumb.Link>
                  {/* @ts-expect-error TS2339 (typescriptify) */}
                  {I18n.t('Edit %{pageTitle}', {pageTitle: this.state.appointmentGroup.title})}
                </Breadcrumb.Link>,
              ]
            : [])}
        </Breadcrumb>
        <ScreenReaderContent>
          <h1>
            {I18n.t('Edit %{pageTitle}', {
              // @ts-expect-error TS2339 (typescriptify)
              pageTitle: this.state.appointmentGroup.title,
            })}
          </h1>
        </ScreenReaderContent>
        <div className="EditPage__Header">
          <Grid vAlign="middle">
            <Grid.Row hAlign="end">
              <Grid.Col width="auto">
                {/* @ts-expect-error TS2339 (typescriptify) */}
                <Button onClick={this.deleteGroup} disabled={this.state.isDeleting}>
                  {I18n.t('Delete Group')}
                </Button>
                &nbsp;
                <Button href="/calendar">{I18n.t('Cancel')}</Button>
                &nbsp;
                <Button onClick={this.handleSave} color="primary">
                  {I18n.t('Save')}
                </Button>
              </Grid.Col>
            </Grid.Row>
          </Grid>
        </div>
        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Edit Assignment Group')}</ScreenReaderContent>}
        >
          <FormFieldGroup description={I18n.t('Calendars')} layout="inline" vAlign="top">
            <ContextSelector
              // @ts-expect-error TS2322 (typescriptify)
              id="context"
              // @ts-expect-error TS2339 (typescriptify)
              appointmentGroup={this.state.appointmentGroup}
              // @ts-expect-error TS2339 (typescriptify)
              contexts={this.state.contexts}
              // @ts-expect-error TS2339 (typescriptify)
              selectedContexts={this.state.selectedContexts}
              // @ts-expect-error TS2339 (typescriptify)
              selectedSubContexts={this.state.selectedSubContexts}
              setSelectedContexts={this.setSelectedContexts}
              setSelectedSubContexts={this.setSelectedSubContexts}
            />
          </FormFieldGroup>
          <TextInput
            renderLabel={I18n.t('Title')}
            name="title"
            // @ts-expect-error TS2339 (typescriptify)
            value={this.state.formValues.title}
            onChange={this.handleChange}
            layout="inline"
            // @ts-expect-error TS2322 (typescriptify)
            vAlign="top"
          />
          <FormFieldGroup description={I18n.t('Time Block')} layout="inline" vAlign="top">
            <TimeBlockSelector
              // @ts-expect-error TS2339 (typescriptify)
              timeData={parseTimeData(this.state.appointmentGroup)}
              onChange={this.setTimeBlocks}
            />
          </FormFieldGroup>
          <TextInput
            renderLabel={I18n.t('Location')}
            name="location"
            // @ts-expect-error TS2339 (typescriptify)
            value={this.state.formValues.location}
            onChange={this.handleChange}
            layout="inline"
            // @ts-expect-error TS2322 (typescriptify)
            vAlign="top"
          />
          <TextArea
            resize="vertical"
            layout="inline"
            label={I18n.t('Details')}
            name="description"
            // @ts-expect-error TS2339 (typescriptify)
            value={this.state.formValues.description}
            onChange={this.handleChange}
          />
          <div
            ref={c => {
              // @ts-expect-error TS2339 (typescriptify)
              this.optionFields = c
            }}
            className="EditPage__Options"
          >
            <FormFieldGroup
              description={I18n.t('Options')}
              rowSpacing="small"
              layout="inline"
              vAlign="top"
            >
              <div className="ic-Form-control ic-Form-control--checkbox">
                <input
                  type="checkbox"
                  // @ts-expect-error TS2339 (typescriptify)
                  checked={this.state.formValues.limitUsersPerSlot}
                  id="limit_users_per_slot"
                  name="limitUsersPerSlot"
                  onChange={this.handleCheckboxChange}
                />
                {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
                <label
                  className="ic-Label"
                  htmlFor="limit_users_per_slot"
                  dangerouslySetInnerHTML={{
                    __html: I18n.t('Limit each time slot to %{input_value} user(s). ', {
                      input_value:
                        '<input class="ic-Input EditPage__Options-Input EditPage__Options-LimitUsersPerSlot" />',
                    }),
                  }}
                />
              </div>
              <Checkbox
                label={I18n.t(
                  'Allow students to see who was signed up for time slots that are still available',
                )}
                // @ts-expect-error TS2339 (typescriptify)
                checked={this.state.formValues.allowStudentsToView}
                name="allowStudentsToView"
                onChange={this.handleCheckboxChange}
              />
              <div className="ic-Form-control ic-Form-control--checkbox">
                <input
                  type="checkbox"
                  // @ts-expect-error TS2339 (typescriptify)
                  checked={this.state.formValues.limitSlotsPerUser}
                  id="limit_slots_per_user"
                  name="limitSlotsPerUser"
                  onChange={this.handleCheckboxChange}
                />
                {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
                <label
                  className="ic-Label"
                  htmlFor="limit_slots_per_user"
                  dangerouslySetInnerHTML={{
                    __html: I18n.t('Limit students to attend %{input_value} slot(s). ', {
                      input_value:
                        '<input class="ic-Input EditPage__Options-Input EditPage__Options-LimitSlotsPerUser" />',
                    }),
                  }}
                />
              </div>
              {this.observerSignupAllowed() && (
                <Checkbox
                  label={I18n.t('Allow observers to sign-up')}
                  // @ts-expect-error TS2339 (typescriptify)
                  checked={this.state.formValues.allowObserverSignup}
                  name="allowObserverSignup"
                  onChange={this.handleCheckboxChange}
                />
              )}
            </FormFieldGroup>
          </div>
          <FormFieldGroup
            description={I18n.t('Appointments')}
            layout="inline"
            rowSpacing="small"
            vAlign="top"
          >
            <Button
              ref={c => {
                // @ts-expect-error TS2551 (typescriptify)
                this.messageStudentsButton = c
              }}
              onClick={this.messageStudents}
              // @ts-expect-error TS2339 (typescriptify)
              disabled={this.state.appointmentGroup.appointments_count === 0}
            >
              {I18n.t('Message Students')}
            </Button>
            {/* @ts-expect-error TS2339 (typescriptify) */}
            <AppointmentGroupList appointmentGroup={this.state.appointmentGroup} />
          </FormFieldGroup>
        </FormFieldGroup>
        <CanvasModal
          // @ts-expect-error TS2339 (typescriptify)
          open={this.state.showDeleteModal}
          onDismiss={this.closeDeleteModal}
          size="small"
          label={I18n.t('Delete for everyone?')}
          data-testid="delete-appointment-group-modal"
          footer={
            <>
              <Button onClick={this.closeDeleteModal} data-testid="cancel-delete-button">
                {I18n.t('Cancel')}
              </Button>
              <Button
                color="danger"
                margin="0 0 0 small"
                onClick={this.confirmDelete}
                data-testid="confirm-delete-button"
              >
                {I18n.t('Delete')}
              </Button>
            </>
          }
        >
          <View as="div" margin="0 small" data-testid="delete-modal-content">
            <Text>
              {I18n.t(
                'If you delete this appointment group, all course teachers will lose access, and all student signups will be permanently deleted.',
              )}
            </Text>
          </View>
        </CanvasModal>
      </div>
    )
  }
}

export default EditPage

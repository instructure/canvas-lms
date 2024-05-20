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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Button} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Checkbox} from '@instructure/ui-checkbox'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import '@canvas/rails-flash-notifications'
import '@canvas/jquery/jquery.instructure_forms'
import '@canvas/datetime/jquery'
import EventDataSource from '@canvas/calendar/jquery/EventDataSource'
import MessageParticipantsDialog from '@canvas/calendar/jquery/MessageParticipantsDialog'
import axios from '@canvas/axios'
import AppointmentGroupList from './AppointmentGroupList'
import ContextSelector from './ContextSelector'
import TimeBlockSelector from './TimeBlockSelector'

const I18n = useI18nScope('appointment_groups')

const parseFormValues = data => ({
  description: data.description,
  location: data.location_name,
  title: data.title,
  limitUsersPerSlot: data.participants_per_appointment,
  limitSlotsPerUser: data.max_appointments_per_participant,
  allowStudentsToView: data.participant_visibility === 'protected',
  allowObserverSignup: data.allow_observer_signup,
})

const parseTimeData = appointmentGroup => {
  if (!appointmentGroup.appointments) {
    return []
  }
  return appointmentGroup.appointments.map(appointment => ({
    timeData: {
      date: appointment.start_at,
      startTime: appointment.start_at,
      endTime: appointment.end_at,
    },
    slotEventId: appointment.id.toString(),
  }))
}

const nullTimeFilter = timeBlock =>
  timeBlock.timeData.date != null ||
  timeBlock.timeData.startTime != null ||
  timeBlock.timeData.endTime != null

class EditPage extends React.Component {
  static propTypes = {
    appointment_group_id: PropTypes.string,
  }

  constructor(props) {
    super(props)
    this.state = {
      appointmentGroup: {
        title: '',
        context_codes: [],
        sub_context_codes: [],
      },
      formValues: {},
      contexts: [],
      isDeleting: false,
      eventDataSource: null,
      selectedContexts: new Set(),
      selectedSubContexts: new Set(),
    }
  }

  setSelectedContexts = selectedContexts => {
    this.setState({selectedContexts})
  }

  setSelectedSubContexts = selectedSubContexts => {
    this.setState({selectedSubContexts})
  }

  componentDidMount() {
    axios
      .get(
        `/api/v1/appointment_groups/${this.props.appointment_group_id}?include[]=appointments&include[]=child_events`
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
            $('.EditPage__Options-LimitUsersPerSlot', this.optionFields).val(
              formValues.limitUsersPerSlot
            )
            $('.EditPage__Options-LimitSlotsPerUser', this.optionFields).val(
              formValues.limitSlotsPerUser
            )
          }
        )
      })

    axios.get('/api/v1/calendar_events/visible_contexts').then(response => {
      const contexts = response.data.contexts.filter(context =>
        context.asset_string.match(/^course_/)
      )
      this.setState({
        contexts,
        eventDataSource: new EventDataSource(contexts),
      })
    })
  }

  setTimeBlocks = (newTimeBlocks = []) => {
    const formValues = Object.assign(this.state.formValues, {timeblocks: newTimeBlocks})
    this.setState({formValues})
  }

  handleChange = e => {
    const formValues = Object.assign(this.state.formValues, {
      [e.target.name]: e.target.value,
    })

    this.setState({formValues})
  }

  handleCheckboxChange = e => {
    const formValues = Object.assign(this.state.formValues, {
      [e.target.name]: e.target.checked,
    })

    this.setState({formValues})
  }

  messageStudents = () => {
    const messageStudentsDialog = new MessageParticipantsDialog({
      group: this.state.appointmentGroup,
      dataSource: this.state.eventDataSource,
    })
    messageStudentsDialog.show()
  }

  groupSubContextsSelected = () =>
    [...this.state.selectedSubContexts].some(code => code.startsWith('group_'))

  observerSignupAllowed = () =>
    this.state.contexts?.length > 0 &&
    !this.groupSubContextsSelected() &&
    [...this.state.selectedContexts].every(
      context_code =>
        this.state.contexts.find(c => c.asset_string === context_code)
          ?.allow_observers_in_appointment_groups
    )

  deleteGroup = () => {
    if (!this.state.isDeleting) {
      this.setState({isDeleting: true}, () => {
        axios
          .delete(`/api/v1/appointment_groups/${this.props.appointment_group_id}`)
          .then(() => {
            window.location = '/calendar'
          })
          .catch(() => {
            $.flashError(I18n.t('An error occurred while deleting the appointment group'))
            this.setState({isDeleting: false})
          })
      })
    }
  }

  handleSave = () => {
    const formValues = {...this.state.formValues}
    if (formValues.limitUsersPerSlot) {
      const $element = $('.EditPage__Options-LimitUsersPerSlot', this.optionFields)
      const value = $element.val()
      if (!value) {
        $element.errorBox(I18n.t('You must provide a value or unselect the option.'))
        return
      } else if (value < 1) {
        $element.errorBox(I18n.t('You must allow at least one appointment per time slot.'))
        return
      }
      formValues.usersPerSlotLimit = value
    } else {
      formValues.usersPerSlotLimit = null
    }
    if (formValues.limitSlotsPerUser) {
      const $element = $('.EditPage__Options-LimitSlotsPerUser', this.optionFields)
      const value = $element.val()
      if (!value) {
        $element.errorBox(I18n.t('You must provide a value or unselect the option.'))
        return
      } else if (value < 1) {
        $element.errorBox(I18n.t('You must allow at least one appointment per participant.'))
        return
      }
      formValues.slotsPerUserLimit = value
    } else {
      formValues.slotsPerUserLimit = null
    }
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
          .map(tb => [
            $.unfudgeDateForProfileTimezone(tb.timeData.startTime),
            $.unfudgeDateForProfileTimezone(tb.timeData.endTime),
          ]),
        context_codes: [...this.state.selectedContexts],
        sub_context_codes: [...this.state.selectedSubContexts],
        allow_observer_signup: this.observerSignupAllowed() && formValues.allowObserverSignup,
      },
    }

    axios
      .put(url, requestObj)
      .then(() => {
        window.location.href = '/calendar?edit_appointment_group_success=1'
      })
      .catch(() => {
        $.flashError(I18n.t('An error occurred while saving the appointment group'))
      })
  }

  render() {
    return (
      <div className="EditPage">
        <Breadcrumb label={I18n.t('You are here:')}>
          <Breadcrumb.Link href="/calendar">{I18n.t('Calendar')}</Breadcrumb.Link>
          {this.state.appointmentGroup.title && (
            <Breadcrumb.Link>
              {I18n.t('Edit %{pageTitle}', {pageTitle: this.state.appointmentGroup.title})}
            </Breadcrumb.Link>
          )}
        </Breadcrumb>
        <ScreenReaderContent>
          <h1>
            {I18n.t('Edit %{pageTitle}', {
              pageTitle: this.state.appointmentGroup.title,
            })}
          </h1>
        </ScreenReaderContent>
        <div className="EditPage__Header">
          <Grid vAlign="middle">
            <Grid.Row hAlign="end">
              <Grid.Col width="auto">
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
              id="context"
              appointmentGroup={this.state.appointmentGroup}
              contexts={this.state.contexts}
              selectedContexts={this.state.selectedContexts}
              selectedSubContexts={this.state.selectedSubContexts}
              setSelectedContexts={this.setSelectedContexts}
              setSelectedSubContexts={this.setSelectedSubContexts}
            />
          </FormFieldGroup>
          <TextInput
            renderLabel={I18n.t('Title')}
            name="title"
            value={this.state.formValues.title}
            onChange={this.handleChange}
            layout="inline"
            vAlign="top"
          />
          <FormFieldGroup description={I18n.t('Time Block')} layout="inline" vAlign="top">
            <TimeBlockSelector
              timeData={parseTimeData(this.state.appointmentGroup)}
              onChange={this.setTimeBlocks}
            />
          </FormFieldGroup>
          <TextInput
            renderLabel={I18n.t('Location')}
            name="location"
            value={this.state.formValues.location}
            onChange={this.handleChange}
            layout="inline"
            vAlign="top"
          />
          <TextArea
            resize="vertical"
            layout="inline"
            label={I18n.t('Details')}
            name="description"
            value={this.state.formValues.description}
            onChange={this.handleChange}
          />
          <div
            ref={c => {
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
                  'Allow students to see who was signed up for time slots that are still available'
                )}
                checked={this.state.formValues.allowStudentsToView}
                name="allowStudentsToView"
                onChange={this.handleCheckboxChange}
              />
              <div className="ic-Form-control ic-Form-control--checkbox">
                <input
                  type="checkbox"
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
                this.messageStudentsButton = c
              }}
              onClick={this.messageStudents}
              disabled={this.state.appointmentGroup.appointments_count === 0}
            >
              {I18n.t('Message Students')}
            </Button>
            <AppointmentGroupList appointmentGroup={this.state.appointmentGroup} />
          </FormFieldGroup>
        </FormFieldGroup>
      </div>
    )
  }
}

export default EditPage

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
import I18n from 'i18n!appointment_groups'
import Breadcrumb, { BreadcrumbLink } from '@instructure/ui-breadcrumb/lib/components/Breadcrumb'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Grid, { GridCol, GridRow } from '@instructure/ui-layout/lib/components/Grid'
import FormFieldGroup from '@instructure/ui-forms/lib/components/FormFieldGroup'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import TextArea from '@instructure/ui-forms/lib/components/TextArea'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import 'compiled/jquery.rails_flash_notifications'
import 'jquery.instructure_forms'
import 'jquery.instructure_date_and_time'
import EventDataSource from 'compiled/calendar/EventDataSource'
import MessageParticipantsDialog from 'compiled/calendar/MessageParticipantsDialog'
import axios from 'axios'
import AppointmentGroupList from './AppointmentGroupList'
import ContextSelector from './ContextSelector'
import TimeBlockSelector from './TimeBlockSelector'

  const parseFormValues = data => ({
    description: data.description,
    location: data.location_name,
    title: data.title,
    limitUsersPerSlot: data.participants_per_appointment,
    limitSlotsPerUser: data.max_appointments_per_participant,
    allowStudentsToView: data.participant_visibility === 'protected'
  })

  const parseTimeData = (appointmentGroup) => {
    if (!appointmentGroup.appointments) {
      return [];
    }
    return appointmentGroup.appointments.map(appointment => ({
      timeData: {
        date: appointment.start_at,
        startTime: appointment.start_at,
        endTime: appointment.end_at
      },
      slotEventId: appointment.id.toString(),
    }));
  }

  const nullTimeFilter = timeBlock =>
     timeBlock.timeData.date != null ||
           timeBlock.timeData.startTime != null ||
           timeBlock.timeData.endTime != null


  class EditPage extends React.Component {
    static propTypes = {
      appointment_group_id: PropTypes.string
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
      }
    }

    componentDidMount() {
      axios.get(`/api/v1/appointment_groups/${this.props.appointment_group_id}?include[]=appointments&include[]=child_events`)
       .then((response) => {
         const formValues = parseFormValues(response.data)
         this.setState({
           formValues,
           appointmentGroup: response.data,
         }, () => {
           // Handle setting some pesky values
           $('.EditPage__Options-LimitUsersPerSlot', this.optionFields).val(formValues.limitUsersPerSlot);
           $('.EditPage__Options-LimitSlotsPerUser', this.optionFields).val(formValues.limitSlotsPerUser);
         })
       })

      axios.get('/api/v1/calendar_events/visible_contexts')
        .then((response) => {
          const contexts = response.data.contexts.filter(context => context.asset_string.match(/^course_/))
          this.setState({
            contexts,
            eventDataSource: new EventDataSource(contexts),
          })
        })
    }

    setTimeBlocks = (newTimeBlocks = []) => {
      const formValues = Object.assign(this.state.formValues, { timeblocks: newTimeBlocks });
      this.setState({ formValues });
    }

    handleChange = (e) => {
      const formValues = Object.assign(this.state.formValues, {
        [e.target.name]: e.target.value
      });

      this.setState({ formValues });
    }

    handleCheckboxChange = (e) => {
      const formValues = Object.assign(this.state.formValues, {
        [e.target.name]: e.target.checked
      });

      this.setState({ formValues });
    }

    messageStudents = () => {
      const messageStudentsDialog = new MessageParticipantsDialog({
        group: this.state.appointmentGroup,
        dataSource: this.state.eventDataSource,
      })
      messageStudentsDialog.show()
    }

    deleteGroup = () => {
      if (!this.state.isDeleting) {
        this.setState({ isDeleting: true }, () => {
          axios.delete(`/api/v1/appointment_groups/${this.props.appointment_group_id}`)
            .then(() => {
              window.location = '/calendar'
            })
            .catch(() => {
              $.flashError(I18n.t('An error ocurred while deleting the appointment group'))
              this.setState({ isDeleting: false })
            })
        })
      }
    }

    handleSave = () => {
      const formValues = Object.assign({}, this.state.formValues);
      if (formValues.limitUsersPerSlot) {
        const $element = $('.EditPage__Options-LimitUsersPerSlot', this.optionFields);
        const value = $element.val();
        if (!value) {
          $element.errorBox(I18n.t('You must provide a value or unselect the option.'));
          return;
        } else if (value < 1) {
          $element.errorBox(I18n.t('You must allow at least one appointment per time slot.'));
          return;
        }
        formValues.usersPerSlotLimit = value;
      }
      else {
        formValues.usersPerSlotLimit = null;
      }
      if (formValues.limitSlotsPerUser) {
        const $element = $('.EditPage__Options-LimitSlotsPerUser', this.optionFields);
        const value = $element.val();
        if (!value) {
          $element.errorBox(I18n.t('You must provide a value or unselect the option.'));
          return;
        } else if (value < 1) {
          $element.errorBox(I18n.t('You must allow at least one appointment per participant.'));
          return;
        }
        formValues.slotsPerUserLimit = value;
      }
      else {
        formValues.slotsPerUserLimit = null;
      }
      const url = `/api/v1/appointment_groups/${this.props.appointment_group_id}`;

      formValues.timeblocks = formValues.timeblocks || [];

      const requestObj = {
        appointment_group: {
          title: formValues.title,
          description: formValues.description,
          location_name: formValues.location,
          participants_per_appointment: formValues.usersPerSlotLimit,
          participant_visibility: (formValues.allowStudentsToView) ? 'protected' : 'private',
          max_appointments_per_participant: formValues.slotsPerUserLimit,
          new_appointments: formValues.timeblocks.filter(nullTimeFilter).map(tb => ([
            $.unfudgeDateForProfileTimezone(tb.timeData.startTime),
            $.unfudgeDateForProfileTimezone(tb.timeData.endTime)
          ])),
          context_codes: [...this.contextSelector.state.selectedContexts],
          sub_context_codes: [...this.contextSelector.state.selectedSubContexts]
        }
      };

      axios.put(url, requestObj)
        .then(() => {
          window.location.href = '/calendar?edit_appointment_group_success=1';
        })
        .catch(() => {
          $.flashError(I18n.t('An error ocurred while saving the appointment group'));
        });
    }

    render() {
      return (
        <div className="EditPage">
          <Breadcrumb label={I18n.t('You are here:')}>
            <BreadcrumbLink href="/calendar">{I18n.t('Calendar')}</BreadcrumbLink>
            <BreadcrumbLink>
              {I18n.t('Edit %{pageTitle}', {
                pageTitle: this.state.appointmentGroup.title
              })}
            </BreadcrumbLink>
          </Breadcrumb>
          <ScreenReaderContent>
            <h1>
              {I18n.t('Edit %{pageTitle}', {
                pageTitle: this.state.appointmentGroup.title
              })}
            </h1>
          </ScreenReaderContent>
          <div className="EditPage__Header">
            <Grid vAlign="middle">
              <GridRow hAlign="end">
                <GridCol width="auto">
                  <Button onClick={this.deleteGroup} disabled={this.state.isDeleting}>{I18n.t('Delete Group')}</Button>
                  &nbsp;
                  <Button href="/calendar">{I18n.t('Cancel')}</Button>
                  &nbsp;
                  <Button onClick={this.handleSave} variant="primary">{I18n.t('Save')}</Button>
                </GridCol>
              </GridRow>
            </Grid>
          </div>
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t('Edit Assignment Group')}</ScreenReaderContent>}
            >
            <FormFieldGroup
              description={I18n.t('Calendars')}
              layout="inline"
              vAlign="top"
            >
              <ContextSelector
                ref={(c) => { this.contextSelector = c; }}
                id="context"
                appointmentGroup={this.state.appointmentGroup}
                contexts={this.state.contexts}
              />
            </FormFieldGroup>
            <TextInput
              label={I18n.t('Title')}
              name="title"
              value={this.state.formValues.title}
              onChange={this.handleChange}
              layout="inline"
              vAlign="top"
              />
            <FormFieldGroup
              description={I18n.t('Time Block')}
              layout="inline"
              vAlign="top"
              >
              <TimeBlockSelector
                timeData={parseTimeData(this.state.appointmentGroup)}
                onChange={this.setTimeBlocks}
              />
            </FormFieldGroup>
            <TextInput
              label ={I18n.t('Location')}
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
            <div ref={(c) => { this.optionFields = c; }} className="EditPage__Options">
              <FormFieldGroup
                description={I18n.t('Options')}
                rowSpacing="small"
                layout="inline"
                vAlign="top"
              >
                <Checkbox
                  checked={this.state.appointmentGroup.participant_type === 'Group'}
                  id="group_signup_required"
                  aria-disabled="true"
                  label={I18n.t('Students must sign up in groups')}
                />
                <div className="ic-Form-control ic-Form-control--checkbox">
                  <input
                    type="checkbox"
                    checked={this.state.formValues.limitUsersPerSlot}
                    id="limit_users_per_slot"
                    name="limitUsersPerSlot"
                    onChange={this.handleCheckboxChange}
                  />
                  <label
                    className="ic-Label"
                    htmlFor="limit_users_per_slot"
                    dangerouslySetInnerHTML={{
                      __html: I18n.t('Limit each time slot to %{input_value} user(s). ', {
                        input_value: '<input class="ic-Input EditPage__Options-Input EditPage__Options-LimitUsersPerSlot" />'
                      })
                    }}
                  />
                </div>
                <Checkbox
                  label={I18n.t('Allow students to see who was signed up for time slots')}
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
                  <label
                    className="ic-Label"
                    htmlFor="limit_slots_per_user"
                    dangerouslySetInnerHTML={{
                      __html: I18n.t('Limit students to attend %{input_value} slot(s). ', {
                        input_value: '<input class="ic-Input EditPage__Options-Input EditPage__Options-LimitSlotsPerUser" />'
                      })
                    }}
                  />
                </div>
              </FormFieldGroup>
            </div>
            <FormFieldGroup
              description={I18n.t('Appointments')}
              layout="inline"
              rowSpacing="small"
              vAlign="top"
            >
            <Button ref={(c) => { this.messageStudentsButton = c }}
              onClick={this.messageStudents}
              disabled={this.state.appointmentGroup.appointments_count === 0}>
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

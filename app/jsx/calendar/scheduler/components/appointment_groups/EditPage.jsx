define([
  'jquery',
  'react',
  'i18n!appointment_groups',
  'instructure-ui/Breadcrumb',
  'instructure-ui/Button',
  'instructure-ui/Grid',
  'instructure-ui/ScreenReaderContent',
  'axios',
  './AppointmentGroupList',
  'compiled/calendar/EventDataSource',
  'compiled/calendar/MessageParticipantsDialog',
  './ContextSelector',
  './TimeBlockSelector',
  'compiled/jquery.rails_flash_notifications',
  'jquery.instructure_forms',
  'jquery.instructure_date_and_time'
], ($, React, I18n, { default: Breadcrumb, BreadcrumbLink }, { default: Button }, { default: Grid, GridCol, GridRow }, { default: ScreenReaderContent }, axios, AppointmentGroupList, EventDataSource, MessageParticipantsDialog, ContextSelector, TimeBlockSelector) => {
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
      appointment_group_id: React.PropTypes.string
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
            <Grid startAt="tablet" vAlign="middle">
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
          <form className="EditPage__Form ic-Form-group ic-Form-group--horizontal">
            <div className="ic-Form-control">
              <label className="ic-Label"htmlFor="context">{I18n.t('Calendars')}</label>
              <ContextSelector
                ref={(c) => { this.contextSelector = c; }}
                id="context"
                className="ic-Input"
                appointmentGroup={this.state.appointmentGroup}
                contexts={this.state.contexts}
              />
            </div>
            <div className="ic-Form-control">
              <label className="ic-Label" htmlFor="title">{I18n.t('Title')}</label>
              <input
                className="ic-Input"
                type="text"
                name="title"
                id="title"
                value={this.state.formValues.title}
                onChange={this.handleChange}
              />
            </div>
            <div className="ic-Form-control">
              <label className="ic-Label" htmlFor="timeblocks">{I18n.t('Time Block')}</label>
              <TimeBlockSelector
                timeData={parseTimeData(this.state.appointmentGroup)}
                onChange={this.setTimeBlocks}
              />
            </div>
            <div className="ic-Form-control">
              <label className="ic-Label" htmlFor="location">{I18n.t('Location')}</label>
              <input
                className="ic-Input"
                type="text"
                name="location"
                id="location"
                value={this.state.formValues.location}
                onChange={this.handleChange}
              />
            </div>
            <div className="ic-Form-control">
              <label className="ic-Label" htmlFor="description">{I18n.t('Details')}</label>
              <textarea
                className="ic-Input"
                type="text"
                name="description"
                id="description"
                value={this.state.formValues.description}
                onChange={this.handleChange}
              />
            </div>
            <div ref={(c) => { this.optionFields = c; }} className="ic-Form-control EditPage__Options">
              <span className="ic-Label">{I18n.t('Options')}</span>
              <div className="ic-Checkbox-group">
                <div className="ic-Form-control ic-Form-control--checkbox EditPage__Options-GroupCheckbox">
                  <input
                    type="checkbox"
                    checked={this.state.appointmentGroup.participant_type === 'Group'}
                    id="group_signup_required"
                    aria-disabled="true"
                  />
                  <label
                    className="ic-Label"
                    htmlFor="group_signup_required"
                  >
                    {I18n.t('Students must sign up in groups')}
                  </label>
                </div>
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
                <div className="ic-Form-control ic-Form-control--checkbox">
                  <input
                    type="checkbox"
                    checked={this.state.formValues.allowStudentsToView}
                    id="allow_students_to_view_signups"
                    name="allowStudentsToView"
                    onChange={this.handleCheckboxChange}
                  />
                  <label
                    className="ic-Label"
                    htmlFor="allow_students_to_view_signups"
                  >
                    {I18n.t('Allow students to see who was signed up for time slots')}
                  </label>
                </div>
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
              </div>
            </div>
            <div className="ic-Form-control">
              <span className="ic-Label" htmlFor="appointments">{I18n.t('Appointments')}</span>
              <Button ref={(c) => { this.messageStudentsButton = c }} onClick={this.messageStudents} disabled={this.state.appointmentGroup.appointments_count === 0}>{I18n.t('Message Students')}</Button>
              <AppointmentGroupList appointmentGroup={this.state.appointmentGroup} />
            </div>
          </form>
        </div>
      )
    }
  }

  return EditPage
})

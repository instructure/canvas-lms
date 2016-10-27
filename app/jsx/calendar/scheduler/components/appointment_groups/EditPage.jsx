define([
  'jquery',
  'react',
  'i18n!appointment_groups',
  'instructure-ui/Button',
  'instructure-ui/Grid',
  'instructure-ui/ScreenReaderContent',
  'axios',
  './AppointmentGroupList',
  'compiled/calendar/MessageParticipantsDialog',
  './ContextSelector',
  './TimeBlockSelector'
], ($, React, I18n, {default: Button}, {default: Grid, GridCol, GridRow}, {default: ScreenReaderContent}, axios, AppointmentGroupList, MessageParticipantsDialog, ContextSelector, TimeBlockSelector) => {

  const parseFormValues = (data) => ({
    description: data.description,
    location: data.location_name,
    title: data.title
  });

  const parseTimeData = (appointmentGroup) => {
    if (!appointmentGroup.appointments) {
      return [];
    }
    return appointmentGroup.appointments.map((appointment) => ({
      timeData: {
        date: appointment.start_at,
        startTime: appointment.start_at,
        endTime: appointment.end_at
      },
      slotEventId: appointment.id
    }));
  }

  class EditPage extends React.Component {

    static propTypes = {
      appointment_group_id: React.PropTypes.string
    };

    constructor (props) {
      super(props);
      this.messageStudents = this.messageStudents.bind(this)
      this.state = {
        appointmentGroup: {},
        formValues: {},
        isDeleting: false,
      }
    }

    componentDidMount () {
      axios.get(`/api/v1/appointment_groups/${this.props.appointment_group_id}?include[]=appointments&include[]=child_events`)
        .then((response) => {
          const formValues = parseFormValues(response.data);
          this.setState({
            formValues,
            appointmentGroup: response.data
          });
        });
    }

    setTitleValue = (e) => {
      const newVals = Object.assign(this.state.formValues, {title: e.target.value});
      this.setState({formValues: newVals});
    }

    setDescriptionValue = (e) => {
      const newVals = Object.assign(this.state.formValues, {description: e.target.value});
      this.setState({formValues: newVals});
    }

    setLocationValue = (e) => {
      const newVals = Object.assign(this.state.formValues, {location: e.target.value});
      this.setState({formValues: newVals});
    }

    messageStudents = (e) => {
      //TODO: We need to make the MessageParticipantsDialog take in multiple appointments
      // to be able to get the MessageParticipantsDialog to show all the users
      // to message, otherwise we need to pass in the calendar datasource, or
      // rewrite the modal completely
      ENV.CALENDAR = {}
      ENV.CALENDAR.MAX_GROUP_CONVERSATION_SIZE = 100
      const messageStudentsDialog = new MessageParticipantsDialog({timeslot: this.state.appointmentGroup.appointments[0]})
      messageStudentsDialog.show();
    }

    deleteGroup = () => {
      if (!this.state.isDeleting) {
        this.setState({ isDeleting: true }, () => {
          axios.delete(`/api/v1/appointment_groups/${this.props.appointment_group_id}`)
            .then(res => {
              window.location = '/calendar'
            })
            .catch(e => {
              $.flashError(I18n.t('An error ocurred while deleting the appointment group'))
              this.setState({ isDeleting: false })
            })
        })
      }
    }

    render () {
      return (
        <div className="EditPage">
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
                  <Button variant="primary">{I18n.t('Save')}</Button>
                </GridCol>
              </GridRow>
            </Grid>
          </div>
          <form className="EditPage__Form ic-Form-group ic-Form-group--horizontal">
            <div className="ic-Form-control">
              <label className="ic-Label"htmlFor="context">{I18n.t('Calendars')}</label>
              <ContextSelector id="context" className="ic-Input" appointmentGroup={this.state.appointmentGroup} />
            </div>
            <div className="ic-Form-control">
              <label className="ic-Label" htmlFor="title">{I18n.t('Title')}</label>
              <input
                className="ic-Input"
                type="text"
                name="title"
                id="title"
                value={this.state.formValues.title}
                onChange={this.setTitleValue}
              />
            </div>
            <div className="ic-Form-control">
              <label className="ic-Label" htmlFor="timeblocks">{I18n.t('Time Block')}</label>
              <TimeBlockSelector timeData={parseTimeData(this.state.appointmentGroup)} />
            </div>
            <div className="ic-Form-control">
              <label className="ic-Label" htmlFor="location">{I18n.t('Location')}</label>
              <input
                className="ic-Input"
                type="text"
                name="location"
                id="location"
                value={this.state.formValues.location}
                onChange={this.setLocationValue}
              />
            </div>
            <div className="ic-Form-control">
              <label className="ic-Label" htmlFor="description">{I18n.t('Description')}</label>
              <textarea
                className="ic-Input"
                type="text"
                name="description"
                id="description"
                value={this.state.formValues.description}
                onChange={this.setDescriptionValue}
              />
            </div>
            <div className="ic-Form-control">
              <label className="ic-Label" htmlFor="options">{I18n.t('Options')}</label>
            </div>
            <div className="ic-Form-control">
              <label className="ic-Label" htmlFor="appointments">{I18n.t('Appointments')}</label>
              <AppointmentGroupList appointmentGroup={this.state.appointmentGroup}/>
            </div>
          </form>
        </div>
      );
    }
  }

  return EditPage;
})

define([
  'react',
  'react-modal',
  'i18n!react_scheduler',
  'jsx/calendar/scheduler/actions',
], (React, Modal, I18n, Actions) => {
  class FindAppointment extends React.Component {

    static propTypes: {
      courses: React.PropTypes.array.isRequired,
      store: React.PropTypes.object.isRequired,
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
      this.props.store.dispatch(Actions.actions.setFindAppointmentMode(!this.props.store.getState().inFindAppointmentMode))
      this.props.store.dispatch(Actions.actions.setCourse(this.state.selectedCourse))
      this.setState ({
        isModalOpen: false,
        selectedCourse: {}
      })
    }
    selectCourse (e) {
      this.setState({
        selectedCourse: this.props.courses.find((c) => c.id === e.target.value)
      })
    }
    openModal () {
      this.setState({
        isModalOpen: true,
      })
    }
    endAppointmentMode () {
      this.props.store.dispatch(Actions.actions.setFindAppointmentMode(false))
      this.setState({
        isModalOpen: false,
      })
    }

    closeModal () {
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
              <button onClick={this.endAppointmentMode} className="Button">{I18n.t('Close')}</button>
              :
              <button onClick={this.openModal} className="Button">{I18n.t('Find Appointment')}</button>
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
                    if (c.asset_string.indexOf("user") === -1) {
                      return(<option key={c.id} value={c.id}>{c.name}</option>)
                    }
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
      )
    }
  }

  return FindAppointment
})

define([
  'react',
  'react-modal',
  'i18n!react_scheduler',
], (React, Modal, I18n) => {
  class FindAppointment extends React.Component {

    static propTypes: {
      courses: React.PropTypes.array.isRequired,
    }

    constructor (props) {
      super(props)
      this.state = { isModalOpen: false }
      this.openModal = this.openModal.bind(this)
      this.closeModal = this.closeModal.bind(this)
    }

    openModal () {
      this.setState({
        isModalOpen: true,
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
        <button onClick={this.openModal} className="Button">{I18n.t('Find Appointment')}</button>
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
                <select className="ic-Input">
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
                <button type="submit" className="btn btn-primary">Submit</button>
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

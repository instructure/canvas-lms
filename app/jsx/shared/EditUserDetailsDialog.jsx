define([
  'i18n!edit_timezone',
  'react',
  "jsx/shared/modal",
  "jsx/shared/modal-content",
  "jsx/shared/modal-buttons",
  "jsx/shared/TimeZoneSelect",
  "jsx/account_course_user_search/UsersStore",
  "jsx/account_course_user_search/IcInput"
], function (I18n, React, Modal, ModalContent, ModalButtons, TimeZoneSelect, UsersStore, IcInput) {
  let { object, bool, number, string, func, shape, arrayOf } = React.PropTypes;

  class EditUserDetailsDialog extends React.Component{
    constructor (props, context) {
      super(props, context);
      this.handleCancelButton = this.handleCancelButton.bind(this);
      this.handleSaveValue = this.handleSaveValue.bind(this);

      this.state = {};
    }

    // Get all input data and return key:value pairs where the key is
    // the name of the input and the value is the value of the input
    // Essentially this gets called anytime any value in the form changes
    // it will update the state.  Once the form is completed this value
    // is sent up via props.submitEditUserForm
    handleSaveValue (e) {
      this.setState({[e.target.name]: e.target.value});
    }
    handleCancelButton () {
      this.props.onRequestClose();
    }
    renderErrorMessage () {
      if (this.props.errors) {
        $.screenReaderFlashMessage(this.props.errors);
        return <div className="alert alert-error">{this.props.errors}</div>;
      }
    }
    render () {
      const {id, name, short_name, sortable_name, email, time_zone} = this.props.user;
      return (
        <Modal
          {...this.props}
          title={<strong>{I18n.t('Edit User Details')}</strong>}
          className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
        >
          <ModalContent>
            {this.renderErrorMessage()}
            <p>{I18n.t("You can update some of this user's information, but they can change it back if they choose.")}</p>
            <form ref="test" className="ic-Form-group">
              <IcInput
                label={I18n.t("Full name")}
                name='name'
                onChange={this.handleSaveValue}
                defaultValue={name} type="text"
                id="fullNameInput"
                placeholder={I18n.t("e.g., Jon Doe")}
              />
              <IcInput
                label={I18n.t("Display Name")}
                name="short_name"
                onChange={this.handleSaveValue}
                defaultValue={short_name}
                type="text" id="displayNameInput"
                placeholder={I18n.t("e.g., Jon Doe")}
              />
              <IcInput
                label={I18n.t("Sortable Name")}
                name="sortable_name"
                onChange={this.handleSaveValue}
                defaultValue={sortable_name}
                type="text"
                id="sortableNameInput"
                placeholder={I18n.t("e.g., Doe, Jon")}
              />
              <div className="ic-Form-control">
                <label htmlFor="timeZoneSelect" className="ic-Label">{I18n.t("Time Zone")}</label>
                <TimeZoneSelect name="time_zone" onChange={this.handleSaveValue} defaultValue={time_zone} priority_timezones={this.props.timezones.priority_zones} timezones={this.props.timezones.timezones} className="ic-Input" id="timeZoneSelect" aria-label={I18n.t("Choose a timezone")} />
              </div>
              <IcInput label={I18n.t("Default Email")} name="email" onChange={this.handleSaveValue} defaultValue={email} type="email" id="defaultEmailInput" placeholder="e.g., jondoe@example.com"></IcInput>
            </form>
          </ModalContent>
          <ModalButtons>
            <button className='btn btn-default' onClick={this.handleCancelButton} >
              {I18n.t('Cancel')}
            </button>
            <button className='btn btn-primary' type="submit" onClick={this.props.submitEditUserForm.bind(null, this.state, id)}>
              {I18n.t('Update Details')}
            </button>
          </ModalButtons>
        </Modal>
      );
    }
  }

  EditUserDetailsDialog.propTypes = {
    user: object.isRequired,
    timezones: object.isRequired,
    submitEditUserForm: func.isRequired,
    onRequestClose: func.isRequired,
    errors: object
  };

  return EditUserDetailsDialog;
});

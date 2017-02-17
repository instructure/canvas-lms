define([
  "jquery",
  "react",
  "underscore",
  "i18n!account_course_user_search",
  "user_utils",
  "jsx/shared/modal",
  "jsx/shared/modal-content",
  "jsx/shared/modal-buttons",
  "./UsersStore",
  "./IcInput",
  "./IcCheckbox",
  "compiled/jquery.rails_flash_notifications"
], function($, React, _, I18n, userUtils, Modal, ModalContent, ModalButtons, UsersStore, IcInput, IcCheckbox) {

  var { object } = React.PropTypes;

  const modalOverrides = {
    overlay : {
      backgroundColor: 'rgba(0,0,0,0.5)'
    },
    content : {
      position: 'static',
      top: '0',
      left: '0',
      right: 'auto',
      bottom: 'auto',
      borderRadius: '0',
      border: 'none',
      padding: '0'
    }
  };

  var NewUserModal = React.createClass({

    propTypes: {
      userList: object.isRequired
    },

    getInitialState() {
      return {
        isOpen: false,
        data: {send_confirmation: true},
        errors: {}
      }
    },

    openModal() {
      this.setState({isOpen: true});
    },

    closeModal() {
      this.setState({isOpen: false, data: {}, errors: {}});
    },

    onChange(field, value) {
      var { data } = this.state;
      var newData = {};
      newData[field] = value;
      if (field === 'name') {
        // shamelessly copypasted from user_sortable_name.js
        var sortable_name_parts = userUtils.nameParts(data.sortable_name);
        if ($.trim(data.sortable_name) == '' || userUtils.firstNameFirst(sortable_name_parts) == $.trim(data.name)) {
          var parts = userUtils.nameParts(value, sortable_name_parts[1]);
          newData.sortable_name = userUtils.lastNameFirst(parts);
        }

        if ($.trim(data.short_name) == '' || data.short_name == data.name) {
          newData.short_name = value;
        }
      }
      data = _.extend({}, data, newData);
      this.setState({ data, errors: {} });
    },

    onSubmit() {
      var { data } = this.state;

      // Basic client side validation
      var errors = {}
      if (!data.name) errors.name = I18n.t("Full name is required");
      if (!data.email) errors.email = I18n.t("Email is required");
      if (Object.keys(errors).length) {
        return this.props.handlers.handleAddNewUserFormErrors(errors);
      }

      var url = `/accounts/${window.ENV.ACCOUNT_ID}/users`
      var params = {
        user: _.pick(data, 'name', 'short_name', 'sortable_name'),
        pseudonym: {
          unique_id: data.email,
          send_confirmation: data.send_confirmation
        }
      };

      this.props.handlers.handleAddNewUser(params)
      this.setState({
        isOpen: false
      });
    },

    render() {
      var { data, isOpen } = this.state;
      let {errors} = this.props.userList;
      var onChange = (field) => {
        return (e) => this.onChange(field, e.target.value);
      };

      return (
        <Modal
          className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
          ref="canvasModal"
          isOpen={isOpen}
          style={modalOverrides}
          title={I18n.t("Add a New User")}
          contentLabel={this.props.contentLabel}
          onRequestClose={this.closeModal}
          onSubmit={this.onSubmit}
        >
          <ModalContent>
            <IcInput
              className="user_name"
              label={I18n.t("Full Name")}
              value={data.name}
              error={errors.name}
              onChange={onChange("name")}
              hint={I18n.t("This name will be used by teachers for grading.")}
            />

            <IcInput
              className="user_short_name"
              label={I18n.t("Display Name")}
              value={data.short_name}
              error={errors.short_name}
              onChange={onChange("short_name")}
              hint={I18n.t("People will see this name in discussions, messages and comments.")}
            />

            <IcInput
              className="user_sortable_name"
              label={I18n.t("Sortable Name")}
              value={data.sortable_name}
              error={errors.sortable_name}
              onChange={onChange("sortable_name")}
              hint={I18n.t("This name appears in sorted lists.")}
            />

            <IcInput
              className="user_email"
              label={I18n.t("Email")}
              value={data.email}
              error={errors.email}
              onChange={onChange("email")}
            />

            <IcCheckbox
              className="user_send_confirmation"
              checked={data.send_confirmation}
              onChange={(e) => this.onChange('send_confirmation', e.target.checked)}
              label={I18n.t("Email the user about this account creation")}
            />

          </ModalContent>

          <ModalButtons>
            <button
              type="button"
              className="btn"
              onClick={this.closeModal}
            >
              {I18n.t("Cancel")}
            </button>

            <button
              type="submit"
              className="btn btn-primary"
            >
              {I18n.t("Add User")}
            </button>
          </ModalButtons>
        </Modal>
      );
    }
  });

  return NewUserModal;
});

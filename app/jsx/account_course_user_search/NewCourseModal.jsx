define([
  "jquery",
  "react",
  "underscore",
  "i18n!account_course_user_search",
  "jsx/shared/modal",
  "jsx/shared/modal-content",
  "jsx/shared/modal-buttons",
  "./CoursesStore",
  "./TermsStore",
  "./AccountsTreeStore",
  "./IcInput",
  "./IcSelect",
  "compiled/jquery.rails_flash_notifications"
], function($, React, _, I18n, Modal, ModalContent, ModalButtons, CoursesStore, TermsStore, AccountsTreeStore, IcInput, IcSelect) {

  var { arrayOf } = React.PropTypes;

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

  var NewCourseModal = React.createClass({
    propTypes: {
      terms: arrayOf(TermsStore.PropType),
      accounts: arrayOf(AccountsTreeStore.PropType)
    },

    getInitialState() {
      return {
        isOpen: false,
        data: {},
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
      data = _.extend({}, data, newData);
      this.setState({ data, errors: {} });
    },

    onSubmit() {
      var { data } = this.state;
      var errors = {}
      if (!data.name)        errors.name        = I18n.t("Course name is required");
      if (!data.course_code) errors.course_code = I18n.t("Reference code is required");
      if (Object.keys(errors).length) {
        this.setState({ errors });
        return;
      }

      // TODO: error handling
      var promise = $.Deferred();
      CoursesStore.create({course: data}).then(() => {
        this.closeModal();
        $.flashMessage(I18n.t("%{course_name} successfully added!", {course_name: data.name}));
        promise.resolve();
      });

      return promise;
    },

    renderAccountOptions(accounts, result, depth) {
      accounts = accounts || this.props.accounts;
      result = result || [];
      depth = depth || 0;

      accounts.forEach((account) => {
        result.push(
          <option key={account.id} value={account.id}>
            {Array(2 * depth + 1).join("\u00a0") + account.name}
          </option>
        );
        this.renderAccountOptions(account.subAccounts, result, depth + 1);
      });
      return result;
    },

    renderTermOptions() {
      var { terms } = this.props;
      return (terms || []).map((term) => {
        return (
          <option key={term.id} value={term.id}>
            {term.name}
          </option>
        );
      });
    },

    render() {
      var { data, isOpen, errors } = this.state;
      var onChange = (field) => {
        return (e) => this.onChange(field, e.target.value);
      };

      return (
        <Modal
          className="ReactModal__Content--canvas ReactModal__Content--mini-modal"
          ref="canvasModal"
          style={modalOverrides}
          isOpen={isOpen}
          title={I18n.t("Add a New Course")}
          onRequestClose={this.closeModal}
          onSubmit={this.onSubmit}
        >
          <ModalContent>
            <IcInput
              label={I18n.t("Course Name")}
              value={data.name}
              error={errors.name}
              onChange={onChange("name")}
            />

            <IcInput
              label={I18n.t("Reference Code")}
              value={data.course_code}
              error={errors.course_code}
              onChange={onChange("course_code")}
            />

            <IcSelect
              label={I18n.t("Subaccount")}
              value={data.account_id}
              onChange={onChange("account_id")}
            >
              {this.renderAccountOptions()}
            </IcSelect>

            <IcSelect
              label={I18n.t("Enrollment Term")}
              value={data.enrollment_term_id}
              onChange={onChange("account_id")}
            >
              {this.renderTermOptions()}
            </IcSelect>
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
              {I18n.t("Add Course")}
            </button>
          </ModalButtons>
        </Modal>
      );
    }
  });

  return NewCourseModal;
});

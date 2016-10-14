define([
  'react',
  'react-dom',
  'underscore',
  'jquery',
  'instructure-ui/Button',
  'i18n!grading_periods',
  'jsx/grading/EnrollmentTermInput',
  'compiled/jquery.rails_flash_notifications'
], function(React, ReactDOM, _, $, { default: Button }, I18n, EnrollmentTermInput) {
  const { array, bool, func, shape, string } = React.PropTypes;

  const buildSet = function(attr = {}) {
    return {
      id:                attr.id,
      title:             attr.title || "",
      enrollmentTermIDs: attr.enrollmentTermIDs || []
    };
  };

  const validateSet = function(set) {
    if (!(set.title || "").trim()) {
      return [I18n.t('All grading period sets must have a title')];
    }
    return [];
  };

  let GradingPeriodSetForm = React.createClass({
    propTypes: {
      set: shape({
        id:                string,
        title:             string,
        enrollmentTermIDs: array
      }).isRequired,
      enrollmentTerms: array.isRequired,
      disabled:        bool,
      onSave:          func.isRequired,
      onCancel:        func.isRequired
    },

    getInitialState() {
      let setId = parseInt(this.props.set.id, 10);
      let associatedEnrollmentTerms = _.where(this.props.enrollmentTerms, { gradingPeriodGroupId: this.props.set.id });
      let set = _.extend({}, this.props.set, {
        enrollmentTermIDs: _.pluck(associatedEnrollmentTerms, "id")
      });

      return { set: buildSet(set) };
    },

    componentDidMount() {
      ReactDOM.findDOMNode(this.refs.title).focus();
    },

    changeTitle(e) {
      let set = _.clone(this.state.set);
      set.title = e.target.value;
      this.setState({ set: set });
    },

    changeEnrollmentTermIDs(termIDs) {
      let set = _.clone(this.state.set);
      set.enrollmentTermIDs = termIDs;
      this.setState({ set: set });
    },

    triggerSave: function(e) {
      e.preventDefault();
      if (this.props.onSave) {
        let validations = validateSet(this.state.set);
        if (_.isEmpty(validations)) {
          this.props.onSave(this.state.set);
        } else {
          _.each(validations, function(message) {
            $.flashError(message);
          });
        }
      }
    },

    triggerCancel: function(e) {
      e.preventDefault();
      if (this.props.onCancel) {
        this.setState({ set: buildSet() }, this.props.onCancel);
      }
    },

    renderSaveAndCancelButtons: function() {
      return (
        <div className="ic-Form-actions below-line">
          <Button disabled      = {this.props.disabled}
                  onClick       = {this.triggerCancel}
                  ref           = "cancelButton">
            {I18n.t("Cancel")}
          </Button>
          &nbsp;
          <Button variant       = "primary"
                  disabled      = {this.props.disabled}
                  aria-label    = {I18n.t("Save Grading Period Set")}
                  onClick       = {this.triggerSave}
                  ref           = "saveButton">
            {I18n.t("Save")}
          </Button>
        </div>
      );
    },

    render() {
      return (
        <div className="GradingPeriodSetForm pad-box">
          <form className="ic-Form-group ic-Form-group--horizontal">
            <div className="grid-row">
              <div className="col-xs-12 col-lg-6">
                <div className="ic-Form-control">
                  <label className="ic-Label" htmlFor="set-name">
                    {I18n.t("Set name")}
                  </label>
                  <input id="set-name"
                         ref="title"
                         className="ic-Input"
                         placeholder={I18n.t("Set name...")}
                         title={I18n.t('Grading Period Set Title')}
                         defaultValue={this.state.set.title}
                         onChange={this.changeTitle}
                         type="text"/>
                </div>

                <EnrollmentTermInput
                  enrollmentTerms              = {this.props.enrollmentTerms}
                  selectedIDs                  = {this.state.set.enrollmentTermIDs}
                  setSelectedEnrollmentTermIDs = {this.changeEnrollmentTermIDs} />
              </div>
            </div>

            <div className="grid-row">
              <div className="col-xs-12 col-lg-12">
                {this.renderSaveAndCancelButtons()}
              </div>
            </div>
          </form>
        </div>
      );
    }
  });

  return GradingPeriodSetForm;
});

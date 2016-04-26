define([
  'timezone',
  'react',
  'jquery',
  'i18n!external_tools',
  'underscore',
  'jsx/gradebook/grid/helpers/datesHelper',
  'jquery.instructure_date_and_time'
], function(tz, React, $, I18n, _, DatesHelper) {

  const types = React.PropTypes;
  let GradingPeriodTemplate = React.createClass({
    propTypes: {
      title: types.string.isRequired,
      startDate: types.instanceOf(Date).isRequired,
      endDate: types.instanceOf(Date).isRequired,
      id: types.string.isRequired,
      permissions: types.shape({
        update: types.bool.isRequired,
        delete: types.bool.isRequired,
      }).isRequired,
      requiredPropsIfEditable: function(props) {
        if (!props.permissions.update && !props.permissions.delete) return;

        const requiredProps = {
          disabled: 'boolean',
          onDeleteGradingPeriod: 'function',
          onDateChange: 'function',
          onTitleChange: 'function'
        };

        let invalidProps = [];
        _.each(requiredProps, (propType, propName) => {
          let invalidProp = _.isUndefined(props[propName]) || typeof props[propName] !== propType;
          if (invalidProp) invalidProps.push(propName);
        });

        if (invalidProps.length > 0) {
          let prefix = "GradingPeriodTemplate: required prop";
          if (invalidProps.length > 1) prefix += "s";
          const errorMessage = prefix + " " + invalidProps.join(", ") + " not provided or of wrong type.";
          return new Error(errorMessage);
        }
      }
    },

    componentDidMount: function() {
      if (this.isNewGradingPeriod()) {
        React.findDOMNode(this.refs.title).focus();
      }
      let dateField = $(React.findDOMNode(this)).find('.date_field');
      dateField.datetime_field();
      dateField.on('change', this.onDateChange);
    },

    onDateChange: function(event) {
      this.props.onDateChange(event.target.name, event.target.id);
    },

    isNewGradingPeriod: function() {
      return this.props.id.indexOf('new') > -1;
    },

    onDeleteGradingPeriod: function() {
      this.props.onDeleteGradingPeriod(this.props.id);
    },

    renderDeleteButton: function() {
      if (!this.props.permissions.delete) return null;
      let cssClasses = "Button Button--icon-action icon-delete-grading-period";
      if (this.props.disabled) cssClasses += " disabled";
      return (
        <div className="col-xs-12 col-sm-6 col-lg-3 manage-buttons-container">
          <div className="content-box">
            <div className="buttons-grid-row grid-row">
              <div className="col-xs">
                <button ref="deleteButton" role="button" className={cssClasses} onClick={this.onDeleteGradingPeriod}>
                  <i className="icon-x icon-delete-grading-period"/>
                  <span className="screenreader-only">{I18n.t("Delete grading period")}</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      );
    },

    renderTitle: function() {
      if (this.props.permissions.update) {
        return (
          <input id={this.addIdToText("period_title_")}
                 type="text"
                 onChange={this.props.onTitleChange}
                 value={this.props.title}
                 disabled={this.props.disabled}
                 ref="title"/>
        );
      } else {
        return (
          <div id={this.addIdToText("period_title_")} ref="title">
            {this.props.title}
          </div>
        );
      }
    },

    renderStartDate: function() {
      if (this.props.permissions.update) {
        return (
          <input id={this.addIdToText("period_start_date_")}
                 type="text"
                 ref="startDate"
                 name="startDate"
                 className="input-grading-period-date date_field"
                 defaultValue={DatesHelper.formatDateForDisplay(this.props.startDate)}
                 disabled={this.props.disabled}/>
        );
      } else {
        return (
          <div id={this.addIdToText("period_start_date_")} ref="startDate">
            {DatesHelper.formatDateForDisplay(this.props.startDate)}
          </div>
        );
      }
    },

    renderEndDate: function() {
      if (this.props.permissions.update) {
        return(
          <input id={this.addIdToText("period_end_date_")} type="text"
                 className="input-grading-period-date date_field"
                 ref="endDate"
                 name="endDate"
                 defaultValue={DatesHelper.formatDateForDisplay(this.props.endDate)}
                 disabled={this.props.disabled}/>
        );
      } else {
        return (
          <div id={this.addIdToText("period_end_date_")} ref="endDate">
            {DatesHelper.formatDateForDisplay(this.props.endDate)}
          </div>
        );
      }
    },

    addIdToText: function(text) {
      return text + this.props.id;
    },

    render: function () {
      return (
        <div id={this.addIdToText("grading-period-")} className="grading-period pad-box-mini border border-trbl border-round">
          <div className="grid-row pad-box-micro">
            <div className="col-xs-12 col-sm-6 col-lg-3">
              <label htmlFor={this.addIdToText("period_title_")}>
                {I18n.t("Grading Period Name")}
              </label>
              {this.renderTitle()}
            </div>
            <div className="col-xs-12 col-sm-6 col-lg-3">
              <label htmlFor={this.addIdToText("period_start_date_")}>
                {I18n.t("Start Date")}
              </label>
              {this.renderStartDate()}
            </div>
            <div className="col-xs-12 col-sm-6 col-lg-3">
              <label htmlFor={this.addIdToText("period_end_date_")}>
               {I18n.t("End Date")}
              </label>
              {this.renderEndDate()}
            </div>
            {this.renderDeleteButton()}
          </div>
        </div>
      );
    }
  });

  return GradingPeriodTemplate;
});

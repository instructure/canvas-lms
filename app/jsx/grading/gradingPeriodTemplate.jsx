define([
  'timezone',
  'react',
  'react-dom',
  'jquery',
  'i18n!external_tools',
  'underscore',
  'jsx/shared/helpers/dateHelper',
  'jquery.instructure_date_and_time'
], function(tz, React, ReactDOM, $, I18n, _, DateHelper) {
  const Types = React.PropTypes;

  const postfixId = (text, { props }) => {
    return text + props.id;
  };

  const isEditable = ({ props }) => {
    return props.permissions.update && !props.readOnly;
  };

  const tabbableDate = (ref, date) => {
    let formattedDate = DateHelper.formatDatetimeForDisplay(date);
    return <span ref={ref} className="GradingPeriod__Action" tabIndex="0">{ formattedDate }</span>;
  };

  const renderActions = ({ props, onDeleteGradingPeriod }) => {
    if (props.permissions.delete && !props.readOnly) {
      let cssClasses = "Button Button--icon-action icon-delete-grading-period";
      if (props.disabled) cssClasses += " disabled";
      return (
        <div className="GradingPeriod__Actions content-box">
          <button ref="deleteButton"
                  role="button"
                  className={cssClasses}
                  aria-disabled={props.disabled}
                  onClick={onDeleteGradingPeriod}>
            <i className="icon-x icon-delete-grading-period"/>
            <span className="screenreader-only">{I18n.t("Delete grading period")}</span>
          </button>
        </div>
      );
    }
  };

  let GradingPeriodTemplate = React.createClass({
    propTypes: {
      title: Types.string.isRequired,
      startDate: Types.instanceOf(Date).isRequired,
      endDate: Types.instanceOf(Date).isRequired,
      closeDate: Types.instanceOf(Date).isRequired,
      id: Types.string.isRequired,
      permissions: Types.shape({
        update: Types.bool.isRequired,
        delete: Types.bool.isRequired,
      }).isRequired,
      readOnly: Types.bool.isRequired,
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
        this.refs.title.focus();
      }
      let dateField = $(ReactDOM.findDOMNode(this)).find('.date_field');
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
      if (!this.props.disabled) {
        this.props.onDeleteGradingPeriod(this.props.id);
      }
    },

    renderTitle: function() {
      if (isEditable(this)) {
        return (
          <input id={postfixId("period_title_", this)}
                 type="text"
                 className="GradingPeriod__Detail ic-Input"
                 onChange={this.props.onTitleChange}
                 value={this.props.title}
                 disabled={this.props.disabled}
                 ref="title"/>
        );
      } else {
        return (
          <div>
            <span className="screenreader-only">{I18n.t("Grading Period Name")}</span>
            <span ref="title" tabIndex="0">{this.props.title}</span>
          </div>
        );
      }
    },

    renderStartDate: function() {
      if (isEditable(this)) {
        return (
          <input id={postfixId("period_start_date_", this)}
                 type="text"
                 ref="startDate"
                 name="startDate"
                 className="GradingPeriod__Detail ic-Input input-grading-period-date date_field"
                 defaultValue={DateHelper.formatDatetimeForDisplay(this.props.startDate)}
                 disabled={this.props.disabled}/>
        );
      } else {
        return (
          <div>
            <span className="screenreader-only">{I18n.t("Start Date")}</span>
            { tabbableDate("startDate", this.props.startDate) }
          </div>
        );
      }
    },

    renderEndDate: function() {
      if (isEditable(this)) {
        return (
          <input id={postfixId("period_end_date_", this)} type="text"
                 className="GradingPeriod__Detail ic-Input input-grading-period-date date_field"
                 ref="endDate"
                 name="endDate"
                 defaultValue={DateHelper.formatDatetimeForDisplay(this.props.endDate)}
                 disabled={this.props.disabled}/>
        );
      } else {
        return (
          <div>
            <span className="screenreader-only">{I18n.t("End Date")}</span>
            { tabbableDate("endDate", this.props.endDate) }
          </div>
        );
      }
    },

    renderCloseDate: function() {
      let closeDate = isEditable(this) ? this.props.endDate : this.props.closeDate;
      return (
        <div>
          <span className="screenreader-only">{I18n.t("Close Date")}</span>
          { tabbableDate("closeDate", closeDate || this.props.endDate) }
        </div>
      );
    },

    render: function () {
      return (
        <div id={postfixId("grading-period-", this)} className="grading-period pad-box-mini border border-trbl border-round">
          <div className="GradingPeriod__Details pad-box-micro">
            <div className="grid-row">
              <div className="col-xs-12 col-sm-6 col-lg-3">
                <label className="ic-Label" htmlFor={postfixId("period_title_", this)}>
                  {I18n.t("Grading Period Name")}
                </label>
                {this.renderTitle()}
              </div>
              <div className="col-xs-12 col-sm-6 col-lg-3">
                <label className="ic-Label" htmlFor={postfixId("period_start_date_", this)}>
                  {I18n.t("Start Date")}
                </label>
                {this.renderStartDate()}
              </div>
              <div className="col-xs-12 col-sm-6 col-lg-3">
                <label className="ic-Label" htmlFor={postfixId("period_end_date_", this)}>
                  {I18n.t("End Date")}
                </label>
                {this.renderEndDate()}
              </div>
              <div className="col-xs-12 col-sm-6 col-lg-3">
                <label className="ic-Label" id={postfixId("period_close_date_", this)}>
                  {I18n.t("Close Date")}
                </label>
                {this.renderCloseDate()}
              </div>
            </div>
          </div>

          {renderActions(this)}
        </div>
      );
    }
  });

  return GradingPeriodTemplate;
});

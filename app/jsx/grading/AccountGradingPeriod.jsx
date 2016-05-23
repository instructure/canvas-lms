define([
  'react',
  'i18n!grading_periods',
  'jsx/gradebook/grid/helpers/datesHelper'
], function(React, I18n, DatesHelper) {
  const types = React.PropTypes;

  let AccountGradingPeriod = React.createClass({
    propTypes: {
      period: types.shape({
        id:        types.string.isRequired,
        title:     types.string.isRequired,
        startDate: types.instanceOf(Date).isRequired,
        endDate:   types.instanceOf(Date).isRequired
      }).isRequired
    },

    render() {
      return (
        <div className="GradingPeriodList__period">
          <div className="GradingPeriodList__period__attributes grid-row">
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-4">
              <span className="screenreader-only">{I18n.t("Grading period title")}</span>
              <span tabIndex="0">{this.props.period.title}</span>
            </div>
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-4">
              <span tabIndex="0" ref="startDate">{I18n.t("Start Date:")} {DatesHelper.formatDateForDisplay(this.props.period.startDate)}</span>
            </div>
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-4">
              <span tabIndex="0" ref="endDate">{I18n.t("End Date:")} {DatesHelper.formatDateForDisplay(this.props.period.endDate)}</span>
            </div>
          </div>
          <div className="GradingPeriodList__period__actions">
            <button type="button" className="Button Button--icon-action">
              <span className="screenreader-only">{I18n.t("Edit grading period")}</span>
              <i className="icon-edit" role="presentation"/>
            </button>
            <button type="button" className="Button Button--icon-action">
              <span className="screenreader-only">{I18n.t("Delete grading period")}</span>
              <i className="icon-trash" role="presentation"/>
            </button>
          </div>
        </div>
      );
    }
  });

  return AccountGradingPeriod;
});

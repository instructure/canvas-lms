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
      }).isRequired,
      onEdit: types.func.isRequired,
      actionsDisabled: types.bool,
      readOnly: types.bool.isRequired,
      permissions: types.shape({
        read:   types.bool.isRequired,
        create: types.bool.isRequired,
        update: types.bool.isRequired,
        delete: types.bool.isRequired
      }).isRequired
    },

    renderEditButton() {
      if (this.props.permissions.update && !this.props.readOnly) {
        return (
          <button className="Button Button--icon-action"
                  ref="editButton"
                  type="button"
                  disabled={this.props.actionsDisabled}
                  onClick={this.onEdit}>
            <span className="screenreader-only">{I18n.t("Edit grading period")}</span>
            <i className="icon-edit" role="presentation"/>
          </button>
        );
      }
    },

    renderDeleteButton() {
      return (
        <button className="Button Button--icon-action"
                ref="deleteButton"
                type="button"
                disabled={this.props.actionsDisabled}
                onClick={this.onDelete}>
          <span className="screenreader-only">{I18n.t("Delete grading period")}</span>
          <i className="icon-trash" role="presentation"/>
        </button>
      );
    },

    render() {
      return (
        <div className="GradingPeriodList__period">
          <div className="GradingPeriodList__period__attributes grid-row">
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-4">
              <span className="screenreader-only">{I18n.t("Grading period title")}</span>
              <span tabIndex="0" ref="title">{this.props.period.title}</span>
            </div>
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-4">
              <span tabIndex="0" ref="startDate">{I18n.t("Start Date:")} {DatesHelper.formatDatetimeForDisplay(this.props.period.startDate)}</span>
            </div>
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-4">
              <span tabIndex="0" ref="endDate">{I18n.t("End Date:")} {DatesHelper.formatDatetimeForDisplay(this.props.period.endDate)}</span>
            </div>
          </div>
          <div className="GradingPeriodList__period__actions">
            {this.renderEditButton()}
            {this.renderDeleteButton()}
          </div>
        </div>
      );
    },

    onEdit(e) {
      e.stopPropagation();
      this.props.onEdit(this.props.period);
    },

    onDelete(e) {
      e.stopPropagation();
    }
  });

  return AccountGradingPeriod;
});

define([
  'react',
  'jquery',
  'axios',
  'i18n!grading_periods',
  'jsx/shared/helpers/dateHelper',
  'jquery.instructure_misc_helpers'
], function(React, $, axios, I18n, DateHelper) {
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
      }).isRequired,
      onDelete: types.func.isRequired,
      deleteGradingPeriodURL: types.string.isRequired
    },

    promptDeleteGradingPeriod(event) {
      event.stopPropagation();
      const confirmMessage = I18n.t("Are you sure you want to delete this grading period?");
      if (!window.confirm(confirmMessage)) return null;
      const url = $.replaceTags(this.props.deleteGradingPeriodURL, 'id', this.props.period.id);

      axios.delete(url)
           .then(() => {
             $.flashMessage(I18n.t('The grading period was deleted'));
             this.props.onDelete(this.props.period.id);
           })
           .catch(() => {
             $.flashError(I18n.t("An error occured while deleting the grading period"));
           });
    },

    onEdit(e) {
      e.stopPropagation();
      this.props.onEdit(this.props.period);
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
      if (this.props.permissions.delete && !this.props.readOnly) {
        return (
          <button ref="deleteButton"
                  type="button"
                  className="Button Button--icon-action"
                  disabled={this.props.actionsDisabled}
                  onClick={this.promptDeleteGradingPeriod}>
            <span className="screenreader-only">{I18n.t("Delete grading period")}</span>
            <i className="icon-trash" role="presentation"/>
          </button>
        );
      }

    },

    render() {
      return (
        <div className="GradingPeriodList__period">
          <div className="GradingPeriodList__period__attributes grid-row">
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-4">
              <span tabIndex="0" ref="title">{this.props.period.title}</span>
            </div>
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-4">
              <span tabIndex="0" ref="startDate">{I18n.t("Start Date:")} {DateHelper.formatDatetimeForDisplay(this.props.period.startDate)}</span>
            </div>
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-4">
              <span tabIndex="0" ref="endDate">{I18n.t("End Date:")} {DateHelper.formatDatetimeForDisplay(this.props.period.endDate)}</span>
            </div>
          </div>
          <div className="GradingPeriodList__period__actions">
            {this.renderEditButton()}
            {this.renderDeleteButton()}
          </div>
        </div>
      );
    },

  });

  return AccountGradingPeriod;
});

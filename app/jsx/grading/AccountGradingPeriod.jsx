define([
  'react',
  'jquery',
  'axios',
  'i18n!grading_periods',
  'jsx/shared/helpers/dateHelper',
  'jquery.instructure_misc_helpers'
], function(React, $, axios, I18n, DateHelper) {
  const Types = React.PropTypes;

  let AccountGradingPeriod = React.createClass({
    propTypes: {
      period: Types.shape({
        id:        Types.string.isRequired,
        title:     Types.string.isRequired,
        startDate: Types.instanceOf(Date).isRequired,
        endDate:   Types.instanceOf(Date).isRequired,
        closeDate: Types.instanceOf(Date).isRequired
      }).isRequired,
      onEdit: Types.func.isRequired,
      actionsDisabled: Types.bool,
      readOnly: Types.bool.isRequired,
      permissions: Types.shape({
        read:   Types.bool.isRequired,
        create: Types.bool.isRequired,
        update: Types.bool.isRequired,
        delete: Types.bool.isRequired
      }).isRequired,
      onDelete: Types.func.isRequired,
      deleteGradingPeriodURL: Types.string.isRequired
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
            <span className="screenreader-only">
              {I18n.t("Edit %{title}", { title: this.props.period.title })}
            </span>
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
            <span className="screenreader-only">
              {I18n.t("Delete %{title}", { title: this.props.period.title })}
            </span>
            <i className="icon-trash" role="presentation"/>
          </button>
        );
      }

    },

    render() {
      return (
        <div className="GradingPeriodList__period">
          <div className="GradingPeriodList__period__attributes grid-row">
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-3">
              <span tabIndex="0" ref="title">{this.props.period.title}</span>
            </div>
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-3">
              <span tabIndex="0" ref="startDate">{I18n.t("Start Date:")} {DateHelper.formatDatetimeForDisplay(this.props.period.startDate)}</span>
            </div>
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-3">
              <span tabIndex="0" ref="endDate">{I18n.t("End Date:")} {DateHelper.formatDatetimeForDisplay(this.props.period.endDate)}</span>
            </div>
            <div className="GradingPeriodList__period__attribute col-xs-12 col-md-8 col-lg-3">
              <span tabIndex="0" ref="closeDate">{I18n.t("Close Date:")} {DateHelper.formatDatetimeForDisplay(this.props.period.closeDate)}</span>
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

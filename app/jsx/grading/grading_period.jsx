/** @jsx React.DOM */

define([
  'old_unsupported_dont_use_react',
  'jquery',
  'i18n!external_tools',
  'jquery.instructure_date_and_time'
],
function(React, $, I18n) {

  var GradingPeriod = React.createClass({

    getInitialState: function() {
      return {
        title: this.props.title,
        startDate: this.props.startDate,
        endDate: this.props.endDate,
        weight: this.props.weight
      };
    },

    componentWillReceiveProps: function(nextProps) {
      this.setState({
        title: nextProps.title,
        startDate: nextProps.startDate,
        endDate: nextProps.endDate,
        weight: nextProps.weight
      });
    },

    triggerDeleteGradingPeriod: function(event) {
      return this.props.onDeleteGradingPeriod(event, this.props.key);
    },

    prettyDate: function(uglyDate) {
      return $.datetimeString(uglyDate, { format: 'medium' });
    },

    render: function () {
      return (
        <div className="grading-period pad-box-mini border border-trbl border-round">
          <div className="grid-row pad-box-micro">
            <div className="col-xs-12 col-sm-6 col-lg-3">
              <label htmlFor={"period_title_" + this.props.key}>
                {I18n.t("Grading Period Name")}
              </label>
              <input id={"period_title_" + this.props.key} type="text"
                     value={this.state.title}/>
            </div>
            <div className="col-xs-12 col-sm-6 col-lg-3">
              <label htmlFor={"period_start_date_" + this.props.key}>
                {I18n.t("Start Date")}
              </label>
              <div className="input-append">
                <input id={"period_start_date_" + this.props.key} type="text"
                       className="input-grading-period-date date_field datetime_field_enabled hasDatepicker"
                       value={this.prettyDate(this.state.startDate)}/>
                <button type="button" className="ui-datepicker-trigger btn"
                        ariaHidden="true" tabIndex="-1">
                  <i className="icon-calendar-month"/>
                </button>
              </div>
            </div>
            <div className="col-xs-12 col-sm-6 col-lg-3">
               <label htmlFor={"period_end_date_" + this.props.key}>
                 {I18n.t("End Date")}
               </label>
               <div className="input-append">
                 <input id={"period_end_date_" + this.props.key} type="text"
                        className="input-grading-period-date date_field datetime_field_enabled hasDatepicker"
                        value={this.prettyDate(this.state.endDate)}/>
                 <button type="button" className="ui-datepicker-trigger btn"
                         ariaHidden="true" tabIndex="-1">
                   <i className="icon-calendar-month"/>
                 </button>
              </div>
            </div>
            <div className="col-xs-12 col-sm-6 col-lg-3 manage-buttons-container">
              <div className="content-box">
                <div className="buttons-grid-row grid-row">
                  <div className="col-xs">
                    <button className="update-button Button Button--primary">
                      {I18n.t("Update")}
                    </button>
                  </div>
                  <div className="col-xs">
                    <div className="icon-delete-container" role="button" tabIndex="0">
                      <i title={I18n.t("Delete grading period")} className="icon-delete-grading-period hover icon-x" onClick={this.triggerDeleteGradingPeriod}>
                        <span className="screenreader-only">{I18n.t("Delete grading period")}</span>
                      </i>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      );
    }
  });

  return GradingPeriod;

});

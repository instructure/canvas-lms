/** @jsx React.DOM */

define([
  'old_unsupported_dont_use_react',
  'jsx/grading/grading_standard',
  'jsx/grading/grading_period',
  'jquery',
  'i18n!external_tools',
  'underscore',
  'jquery.instructure_misc_plugins'
],
function(React, GradingStandard, GradingPeriod, $, I18n, _) {

  var TabContainer = React.createClass({

    getInitialState: function() {
      return {standards: null, periods: null};
    },

    componentWillMount: function() {
      $.getJSON(ENV.GRADING_STANDARDS_URL)
      .done(this.gotStandards)

      if(ENV.MULTIPLE_GRADING_PERIODS){
        $.getJSON(ENV.GRADING_PERIODS_URL)
        .done(this.gotPeriods)
      }
    },

    gotStandards: function(standards) {
      this.setState({standards: standards});
    },

    gotPeriods: function(periods) {
      this.setState({periods: periods.grading_periods});
    },

    componentDidMount: function() {
      $(this.getDOMNode()).children(".ui-tabs-minimal").tabs();
    },

    addGradingStandard: function() {
      var newStandards = _.map(this.state.standards, function(standard){
        standard.editing = false;
        standard.justAdded = false;
        return standard;
      });
      var self = this;
      $.ajax({
        type: "POST",
        url: ENV.GRADING_STANDARDS_URL,
        data: { grading_standard: { title: I18n.t("New Title") } },
        dataType: "json"
      })
        .success(function(newStandard) {
          newStandard.editing = true;
          newStandard.justAdded = true;
          newStandards.unshift(newStandard);
          $(this).slideDown();
          self.setState({standards: newStandards});
        })
        .error(function() {
          $.flashError(I18n.t("There was a problem adding the grading scheme"));
        });
    },

    deleteGradingStandard: function(event, key) {
      var self = this;
      var $standard = $(event.target).parents(".grading_standard");
      $standard.confirmDelete({
        url: ENV.GRADING_STANDARDS_URL + "/" + key,
        message: I18n.t("Are you sure you want to delete this grading scheme?"),
        success: function() {
          $(this).slideUp(function() {
            $(this).remove();
          });
          var newStandards = _.reject(self.state.standards, function(standard){ return standard.grading_standard.id === key });
          self.setState({standards: newStandards});
        },
        error: function() {
          $.flashError(I18n.t("There was a problem deleting the grading scheme"));
        }
      });
    },

    deleteGradingStandardNoWarning: function(key) {
      var self = this;
      $.ajax({
        type: "DELETE",
        url: ENV.GRADING_STANDARDS_URL + "/" + key,
        dataType: "json"
      })
        .success(function(){
          var newStandards = _.reject(self.state.standards, function(standard){ return standard.grading_standard.id === key });
          self.setState({standards: newStandards});
        })
        .error(function(){
          $.flashError(I18n.t("There was a problem deleting the grading scheme"));
        });
    },

    hasAdminOrTeacherRole: function() {
      return _.intersection(ENV.current_user_roles, ["teacher", "admin"]).length > 0;
    },

    renderAddGradingStandardButton: function() {
      if(this.hasAdminOrTeacherRole()){
        return(
          <div className="rs-margin-all pull-right">
            <a href="#" onClick={this.addGradingStandard} className="btn pull-right add_standard_link">
              <i className="icon-add"/>
              {I18n.t(" Add grading scheme")}
            </a>
          </div>
        );
      }
      return null;
    },

    renderGradingStandards: function() {
      if(!this.state.standards){
        return null;
      } else if(this.state.standards.length === 0){
        return <h3>{I18n.t("No grading schemes to display")}</h3>;
      }
      var self = this;
      return this.state.standards.map(function(s){
        return (<GradingStandard key={s.grading_standard.id} standard={s.grading_standard}
                                 editing={!!s.editing} permissions={s.grading_standard.permissions}
                                 justAdded={!!s.justAdded} onDeleteGradingStandard={self.deleteGradingStandard}
                                 onDeleteGradingStandardNoWarning={self.deleteGradingStandardNoWarning}/>);
      });
    },

    renderGradingPeriods: function() {
      if(!this.state.periods){
        return null;
      } else if(this.state.periods.length === 0){
        return <h3>{I18n.t("No grading periods to display")}</h3>;
      }
      return this.state.periods.map(function(p){
        return (<GradingPeriod key={p.id} title={p.title} startDate={new Date(p.start_date)}
                               endDate={new Date(p.end_date)} weight={p.weight}/>);
      });
    },

    render: function () {
      if(ENV.MULTIPLE_GRADING_PERIODS){
        return (
          <div>
            <div className="ui-tabs-minimal">
              <ul>
                <li><a href="#grading-periods-tab" className="grading_periods_tab"> {I18n.t('Grading Periods')}</a></li>
                <li><a href="#grading-standards-tab" className="grading_standards_tab"> {I18n.t('Grading Schemes')}</a></li>
              </ul>
              <div id="grading-periods-tab">
                <div id="grading_periods" className="content-box">
                  {this.renderGradingPeriods()}
                </div>
              </div>
              <div id="grading-standards-tab">
                {this.renderAddGradingStandardButton()}
                <div id="standards" className="content-box react_grading_standards">
                  {this.renderGradingStandards()}
                </div>
              </div>
            </div>
          </div>
        );
      } else{
        return (
          <div>
            <h1 tabIndex="0">{I18n.t("Grading Schemes")}</h1>
            {this.renderAddGradingStandardButton()}
            <div id="standards" className="content-box react_grading_standards">
              {this.renderGradingStandards()}
            </div>
          </div>
        );
      };
    }
  });

  React.renderComponent(<TabContainer/>, document.getElementById("react_grading_tabs"));

});

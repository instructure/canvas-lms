/** @jsx React.DOM */

define([
  'react',
  'jsx/grading/gradingStandard',
  'jquery',
  'i18n!external_tools',
  'underscore',
  'jquery.instructure_misc_plugins'
],
function(React, GradingStandard, $, I18n, _) {

  var GradingStandardCollection = React.createClass({

    getInitialState: function() {
      return {standards: null};
    },

    componentWillMount: function() {
      $.getJSON(ENV.GRADING_STANDARDS_URL)
      .done(this.gotStandards)
    },

    gotStandards: function(standards) {
      this.setState({standards: standards});
    },

    addGradingStandard: function() {
      var newStandards = _.map(this.state.standards, function(standard){
        standard.editing = false;
        standard.justAdded = false;
        return standard;
      });

      var newStandard = {
        editing: true,
        justAdded: true,
        grading_standard: {
          permissions: { manage: true },
          title: "",
          data: ENV.DEFAULT_DATA,
          id: -1
        }
      };

      newStandards.unshift(newStandard);
      this.setState({standards: newStandards});
    },

    getStandardById: function(id) {
      return _.find(this.state.standards, function(standard){ return standard.grading_standard.id === id });
    },

    standardNotCreated: function(gradingStandard){
      return gradingStandard.id === -1;
    },

    setEditingStatus: function(id, setEditingStatusTo){
      var existingStandard = this.getStandardById(id)
      var indexToEdit = this.state.standards.indexOf(existingStandard);
      if(setEditingStatusTo === false && this.standardNotCreated(existingStandard.grading_standard)){
        var newStandards = this.state.standards;
        newStandards.splice(indexToEdit, 1);
        this.setState({standards: newStandards});
      }else{
        this.state.standards[indexToEdit].editing = setEditingStatusTo;
        this.setState({standards: this.state.standards})
      }
    },

    standardBeingEdited: function() {
      return !!_.find(this.state.standards, function(standard){return standard.editing});
    },

    saveGradingStandard: function(standard) {
      var indexToUpdate = this.state.standards.indexOf(this.getStandardById(standard.id));
      if(standard.title === "" && this.standardNotCreated(standard)) standard.title = "New Grading Scheme";
      var self = this;
      $.ajax({
        type: this.standardNotCreated(standard) ? "POST" : "PUT",
        url: this.standardNotCreated(standard) ? ENV.GRADING_STANDARDS_URL : ENV.GRADING_STANDARDS_URL + "/" + standard.id,
        data: this.dataFormattedForUpdate(standard),
        dataType: "json"
      })
        .success(function(updatedStandard){
          self.state.standards[indexToUpdate] = updatedStandard;
          self.setState({standards: self.state.standards});
        })
        .error(function(){
          self.state.standards[indexToUpdate].grading_standard.saving = false;
          self.setState({standards: self.state.standards});
          $.flashError(I18n.t("There was a problem saving the grading scheme"));
        });
    },

    dataFormattedForUpdate: function(standard) {
      var formattedData = { grading_standard: { title: standard.title, standard_data: {} } };
      for(i = 0; i < standard.data.length; i++){
        formattedData["grading_standard"]["standard_data"]["scheme_" + i] = {
          name: standard.data[i][0],
          value: Math.round(standard.data[i][1] * 10000)/100
        };
      };
      return formattedData;
    },

    deleteGradingStandard: function(event, uniqueId) {
      var self = this,
        $standard = $(event.target).parents(".grading_standard");
      $standard.confirmDelete({
        url: ENV.GRADING_STANDARDS_URL + "/" + uniqueId,
        message: I18n.t("Are you sure you want to delete this grading scheme?"),
        success: function() {
          $(this).slideUp(function() {
            $(this).remove();
          });
          var newStandards = _.reject(self.state.standards, function(standard){ return standard.grading_standard.id === uniqueId });
          self.setState({standards: newStandards});
        },
        error: function() {
          $.flashError(I18n.t("There was a problem deleting the grading scheme"));
        }
      });
    },

    hasAdminOrTeacherRole: function() {
      return _.intersection(ENV.current_user_roles, ["teacher", "admin"]).length > 0;
    },

    getAddButtonCssClasses: function() {
      var classes = "btn pull-right add_standard_link"
      if(!this.hasAdminOrTeacherRole() || this.standardBeingEdited()) classes += " disabled"
      return classes;
    },

    renderGradingStandards: function() {
      if(!this.state.standards){
        return null;
      } else if(this.state.standards.length === 0){
        return <h3>{I18n.t("No grading schemes to display")}</h3>;
      }
      var self = this;
      return this.state.standards.map(function(s){
        return (<GradingStandard key={s.grading_standard.id} uniqueId={s.grading_standard.id}
                                 standard={s.grading_standard} editing={!!s.editing}
                                 permissions={s.grading_standard.permissions}
                                 justAdded={s.justAdded} onSetEditingStatus={self.setEditingStatus}
                                 othersEditing={!s.editing && self.standardBeingEdited()}
                                 onDeleteGradingStandard={self.deleteGradingStandard}
                                 onSaveGradingStandard={self.saveGradingStandard}/>);
      });
    },

    render: function () {
      return(
        <div>
          <div className="rs-margin-all pull-right">
            <a href="#" onClick={this.addGradingStandard} className={this.getAddButtonCssClasses()}>
              <i className="icon-add"/>
              {I18n.t(" Add grading scheme")}
            </a>
          </div>
          <div id="standards" className="content-box react_grading_standards">
            {this.renderGradingStandards()}
          </div>
        </div>
      );
    }
  });

  return GradingStandardCollection;

});

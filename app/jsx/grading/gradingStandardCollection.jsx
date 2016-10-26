define([
  'react',
  'jsx/grading/gradingStandard',
  'jquery',
  'i18n!external_tools',
  'underscore',
  'jquery.instructure_misc_plugins'
],
function(React, GradingStandard, $, I18n, _) {
  var update = React.addons.update;
  var GradingStandardCollection = React.createClass({

    getInitialState: function() {
      return {standards: null};
    },

    componentWillMount: function() {
      $.getJSON(ENV.GRADING_STANDARDS_URL + ".json")
      .done(this.gotStandards)
    },

    gotStandards: function(standards) {
      var formattedStandards = $.extend(true, [], standards);
      formattedStandards = _.map(formattedStandards, function(standard) {
        standard.grading_standard.data = this.formatStandardData(standard.grading_standard.data);
        return standard;
      }, this);
      this.setState({standards: formattedStandards});
    },

    formatStandardData: function(standardData) {
      return _.map(standardData, function(dataRow){
        return [dataRow[0], this.roundToTwoDecimalPlaces(dataRow[1] * 100)];
      }, this);
    },

    addGradingStandard: function() {
      var newStandard = {
        editing: true,
        justAdded: true,
        grading_standard: {
          permissions: { manage: true },
          title: "",
          data: this.formatStandardData(ENV.DEFAULT_GRADING_STANDARD_DATA),
          id: -1
        }
      };
      var newStandards = update(this.state.standards, {$unshift: [newStandard]});
      this.setState({standards: newStandards});
    },

    getStandardById: function(id) {
      return _.find(this.state.standards, function(standard){ return standard.grading_standard.id === id });
    },

    standardNotCreated: function(gradingStandard){
      return gradingStandard.id === -1;
    },

    setEditingStatus: function(id, setEditingStatusTo){
      var newStandards = $.extend(true, [], this.state.standards);
      var existingStandard = this.getStandardById(id);
      var indexToEdit = this.state.standards.indexOf(existingStandard);
      if(setEditingStatusTo === false && this.standardNotCreated(existingStandard.grading_standard)){
        newStandards.splice(indexToEdit, 1);
        this.setState({standards: newStandards});
      }else{
        newStandards[indexToEdit].editing = setEditingStatusTo;
        this.setState({standards: newStandards});
      }
    },

    anyStandardBeingEdited: function() {
      return !!_.find(this.state.standards, function(standard){return standard.editing});
    },

    saveGradingStandard: function(standard) {
      var newStandards = $.extend(true, [], this.state.standards);
      var indexToUpdate = this.state.standards.indexOf(this.getStandardById(standard.id));
      var type, url, data;
      standard.title = standard.title.trim();
      if(this.standardNotCreated(standard)){
        if(standard.title === "") standard.title = "New Grading Scheme";
        type = "POST";
        url = ENV.GRADING_STANDARDS_URL;
        data = this.dataFormattedForCreate(standard);
      }else{
        type = "PUT";
        url = ENV.GRADING_STANDARDS_URL + "/" + standard.id;
        data = this.dataFormattedForUpdate(standard);
      }
      $.ajax({
        type: type,
        url: url,
        dataType: "json",
        contentType: 'application/json',
        data: JSON.stringify(data),
        context: this
      })
        .success(function(updatedStandard){
          updatedStandard.grading_standard.data = this.formatStandardData(updatedStandard.grading_standard.data);
          newStandards[indexToUpdate] = updatedStandard;
          this.setState({standards: newStandards}, function() {
            $.flashMessage(I18n.t("Grading scheme saved"));
          });
        })
        .error(function(){
          newStandards[indexToUpdate].grading_standard.saving = false;
          this.setState({standards: newStandards}, function() {
            $.flashError(I18n.t("There was a problem saving the grading scheme"));
          });
        });
    },

    dataFormattedForCreate: function(standard) {
      var formattedData = { grading_standard: standard };
      _.each(standard.data, function(dataRow, i){
        var name = dataRow[0];
        var value = dataRow[1];
        formattedData["grading_standard"]["data"][i] = [
          name.trim(),
          this.roundToTwoDecimalPlaces(value) / 100
        ];
      }, this);
      return formattedData;
    },

    dataFormattedForUpdate: function(standard) {
      var formattedData = { grading_standard: { title: standard.title, standard_data: {} } };
      _.each(standard.data, function(dataRow, i){
        var name = dataRow[0];
        var value = dataRow[1];
        formattedData["grading_standard"]["standard_data"]["scheme_" + i] = {
          name: name.trim(),
          value: this.roundToTwoDecimalPlaces(value)
        };
      }, this);
      return formattedData;
    },

    roundToTwoDecimalPlaces: function(number) {
      return Math.round(number * 100)/100;
    },

    deleteGradingStandard: function(event, uniqueId) {
      var self = this,
        $standard = $(event.target).parents(".grading_standard");
      $standard.confirmDelete({
        url: ENV.GRADING_STANDARDS_URL + "/" + uniqueId,
        message: I18n.t("Are you sure you want to delete this grading scheme?"),
        success: function() {
          var indexToRemove = self.state.standards.indexOf(self.getStandardById(uniqueId));
          var newStandards = update(self.state.standards, {$splice: [[indexToRemove, 1]]});
          self.setState({standards: newStandards}, function(){
            $.flashMessage(I18n.t("Grading scheme deleted"))
          });
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
      var classes = "Button pull-right add_standard_button"
      if(!this.hasAdminOrTeacherRole() || this.anyStandardBeingEdited()) classes += " disabled"
      return classes;
    },

    renderGradingStandards: function() {
      if(!this.state.standards){
        return null;
      } else if(this.state.standards.length === 0){
        return <h3 ref="noSchemesMessage">{I18n.t("No grading schemes to display")}</h3>;
      }
      return this.state.standards.map(function(s){
        return (<GradingStandard ref={"gradingStandard" + s.grading_standard.id} key={s.grading_standard.id}
                                 uniqueId={s.grading_standard.id} standard={s.grading_standard}
                                 editing={!!s.editing} permissions={s.grading_standard.permissions}
                                 justAdded={!!s.justAdded} onSetEditingStatus={this.setEditingStatus}
                                 round={this.roundToTwoDecimalPlaces} onDeleteGradingStandard={this.deleteGradingStandard}
                                 othersEditing={!s.editing && this.anyStandardBeingEdited()}
                                 onSaveGradingStandard={this.saveGradingStandard}/>);
      }, this);
    },

    render: function () {
      return(
        <div>
          <div className="pull-right">
            <button ref="addButton" onClick={this.addGradingStandard} className={this.getAddButtonCssClasses()}>
              <i className="icon-add"/>
              {I18n.t(" Add grading scheme")}
            </button>
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

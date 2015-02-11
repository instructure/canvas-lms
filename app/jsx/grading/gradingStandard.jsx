/** @jsx React.DOM */

define([
  'react',
  'jsx/grading/dataRow',
  'jquery',
  'i18n!external_tools',
  'underscore'
],
function(React, DataRow, $, I18n, _) {
  var update = React.addons.update;
  var GradingStandard = React.createClass({

    getInitialState: function() {
      return {
        editingStandard: $.extend(true, {}, this.props.standard),
        saving: false,
        showAlert: false
      };
    },

    componentWillReceiveProps: function(nextProps) {
      this.setState({
        editingStandard: $.extend(true, {}, this.props.standard),
        saving: nextProps.saving,
        showAlert: false
      });
    },

    componentDidMount: function() {
      if(this.props.justAdded) this.refs.title.getDOMNode().focus();
    },

    componentDidUpdate: function(prevProps, prevState) {
      if(this.props.editing !== prevProps.editing){
       this.refs.title.getDOMNode().focus();
       this.setState({editingStandard: $.extend(true, {}, this.props.standard)})
      }
    },

    triggerEditGradingStandard: function(event) {
      event.preventDefault();
      this.props.onSetEditingStatus(this.props.uniqueId, true);
    },

    triggerStopEditingGradingStandard: function() {
      this.props.onSetEditingStatus(this.props.uniqueId, false);
    },

    triggerDeleteGradingStandard: function(event) {
      return this.props.onDeleteGradingStandard(event, this.props.uniqueId);
    },

    triggerSaveGradingStandard: function() {
      if(this.standardIsValid()){
        this.setState({saving: true}, function() {
          this.props.onSaveGradingStandard(this.state.editingStandard);
        });
      }else{
        this.setState({showAlert: true}, function() {
          this.refs.invalidStandardAlert.getDOMNode().focus();
        });
      }
    },

    assessedAssignment: function() {
      return !!(this.props.standard && this.props.standard["assessed_assignment?"]);
    },

    deleteDataRow: function(index) {
      if(this.moreThanOneDataRowRemains()){
        var newEditingStandard = update(this.state.editingStandard, {data: {$splice:  [[index, 1]]}});
        this.setState({editingStandard: newEditingStandard});
      }
    },

    moreThanOneDataRowRemains: function() {
      return this.state.editingStandard.data.length > 1;
    },

    insertGradingStandardRow: function(index) {
      var newEditingStandard = update(this.state.editingStandard, {data: {$splice:  [[index + 1, 0, ["", ""]]]}});
      this.setState({editingStandard: newEditingStandard});
    },

    changeTitle: function(event) {
      var newEditingStandard = $.extend(true, {}, this.state.editingStandard);
      newEditingStandard.title = (event.target.value);
      this.setState({editingStandard: newEditingStandard});
    },

    changeRowMinScore: function(index, inputVal) {
      var newEditingStandard = $.extend(true, {}, this.state.editingStandard);
      var lastChar = inputVal.substr(inputVal.length - 1);
      newEditingStandard.data[index][1] = inputVal;
      this.setState({editingStandard: newEditingStandard});
    },

    changeRowName: function(index, newRowName) {
      var newEditingStandard = $.extend(true, {}, this.state.editingStandard);
      newEditingStandard.data[index][0] = newRowName;
      this.setState({editingStandard: newEditingStandard});
    },

    hideAlert: function() {
      this.setState({showAlert: false}, function(){
        this.refs.title.getDOMNode().focus();
      });
    },

    standardIsValid: function() {
      return this.rowDataIsValid() && this.rowNamesAreValid();
    },

    rowDataIsValid: function() {
      if(this.state.editingStandard.data.length <= 1) return true;
      var rowValues = _.map(this.state.editingStandard.data, function(dataRow){ return String(dataRow[1]).trim() });
      var sanitizedRowValues = _.chain(rowValues).compact().uniq().value();
      var inputsAreUniqueAndNonEmpty = (sanitizedRowValues.length === rowValues.length);
      var valuesDoNotOverlap = !_.any(this.state.editingStandard.data, function(element, index, list){
        if(index < 1) return false;
        var thisMinScore = this.props.round(element[1]);
        var aboveMinScore = this.props.round(list[index-1][1]);
        return (thisMinScore >= aboveMinScore);
      }, this);

      return inputsAreUniqueAndNonEmpty && valuesDoNotOverlap;
    },

    rowNamesAreValid: function() {
      var rowNames = _.map(this.state.editingStandard.data, function(dataRow){ return dataRow[0].trim() });
      var sanitizedRowNames = _.chain(rowNames).compact().uniq().value();
      return sanitizedRowNames.length === rowNames.length;
    },

    renderCannotManageMessage: function() {
      if(this.props.permissions.manage && this.props.othersEditing) return null;
      if(this.props.standard.context_name){
        return (
          <div ref="cannotManageMessage">
            {I18n.t("(%{context}: %{contextName})", { context: this.props.standard.context_type.toLowerCase(), contextName: this.props.standard.context_name })}
          </div>
        );
      }
      return (
        <div ref="cannotManageMessage">
          {I18n.t("(%{context} level)", { context: this.props.standard.context_type.toLowerCase() })}
        </div>
      );
    },

    renderIdNames: function() {
      if(this.assessedAssignment()) return "grading_standard_blank";
      return "grading_standard_" + (this.props.standard ? this.props.standard.id : "blank");
    },

    renderTitle: function() {
      if(this.props.editing){
        return (
          <div className="pull-left" tabIndex="0">
            <input type="text" onChange={this.changeTitle} className="grading_standard_title"
                   name="grading_standard[title]" className="scheme_name" title={I18n.t("Grading standard title")}
                   value={this.state.editingStandard.title} ref="title"/>
          </div>
        );
      }
      return (
        <div className="pull-left" tabIndex="0">
          <div className="title" ref="title">
            <span className="screenreader-only">{I18n.t("Grading standard title")}</span>
            {this.props.standard.title}
          </div>
        </div>
      );
    },

    renderDataRows: function() {
      var data = this.props.editing ? this.state.editingStandard.data : this.props.standard.data;
      return data.map(function(item, idx, array){
        return (
          <DataRow key={idx} uniqueId={idx} row={item} siblingRow={array[idx - 1]} editing={this.props.editing}
                   onDeleteRow={this.deleteDataRow} onInsertRow={this.insertGradingStandardRow}
                   onlyDataRowRemaining={!this.moreThanOneDataRowRemains()} round={this.props.round}
                   onRowMinScoreChange={this.changeRowMinScore} onRowNameChange={this.changeRowName}/>
        );
      }, this);
    },

    renderSaveButton: function() {
      if(this.state.saving){
        return (
          <button type="button" ref="saveButton" className="btn btn-primary save_button" disabled="true">
            {I18n.t("Saving...")}
          </button>
        );
      }
      return (
        <button type="button" ref="saveButton" onClick={this.triggerSaveGradingStandard} className="btn btn-primary save_button">
          {I18n.t("Save")}
        </button>
      );
    },

    renderSaveAndCancelButtons: function() {
      if(this.props.editing){
        return (
          <div className="form-actions">
            <button type="button" ref="cancelButton" onClick={this.triggerStopEditingGradingStandard} className="btn cancel_button">
              {I18n.t("Cancel")}
            </button>
              {this.renderSaveButton()}
          </div>
        );
      }
      return null;
    },

    renderEditAndDeleteIcons: function() {
      if(!this.props.editing){
        return(
          <div>
            <a href="#" onClick={this.triggerEditGradingStandard} title={I18n.t("Edit Grading Scheme")}
               ref="editLink" tabIndex="1"
               className={"edit_grading_standard_link no-hover " + (this.assessedAssignment() ? "read_only" : "")}>
               <span className="screenreader-only">{I18n.t("Edit Grading Scheme")}</span>
              <i className="icon-edit standalone-icon"/>
            </a>
            <a href="#" title={I18n.t("Delete Grading Scheme")} onClick={this.triggerDeleteGradingStandard}
               ref="deleteLink" className="delete_grading_standard_link no-hover" tabIndex="1">
               <span className="screenreader-only">{I18n.t("Delete Grading Scheme")}</span>
              <i className="icon-trash standalone-icon"/>
            </a>
          </div>
        );
      }
      return null;
    },

    renderIconsAndTitle: function() {
      if(this.props.permissions.manage && !this.props.othersEditing){
        return (
          <div>
            {this.renderTitle()}
            <div className="links">
              {this.renderEditAndDeleteIcons()}
            </div>
          </div>
        );
      }
      return (
        <div>
          {this.renderTitle()}
          <div className="disabled-links" ref="disabledLinks">
            <i className="icon-edit standalone-icon"/>
            <i className="icon-trash standalone-icon"/>
          </div>
          <div className="pull-left cannot-manage-notification">
            {this.renderCannotManageMessage()}
          </div>
        </div>
      );
    },

    renderInvalidStandardMessage: function() {
      var message = "Invalid grading scheme";
      if(!this.rowDataIsValid()) message = "Cannot have overlapping or empty ranges. Fix the ranges and try clicking 'Save' again.";
      if(!this.rowNamesAreValid()) message = "Cannot have duplicate or empty row names. Fix the names and try clicking 'Save' again.";
      return (
        <div id={"invalid_standard_message_" + this.props.uniqueId} className="alert-message" tabIndex="-1" ref="invalidStandardAlert">
          {I18n.t("%{message}", { message: message })}
        </div>
      );
    },

    renderStandardAlert: function() {
      if(!this.state.showAlert) return null;
      if(this.standardIsValid()){
        return (
          <div id="valid_standard" className="alert alert-success">
            <button aria-label="Close" className="dismiss_alert close" onClick={this.hideAlert}>×</button>
            <div className="alert-message">
              {I18n.t("Looks great!")}
            </div>
          </div>
        );
      }
      return (
        <div id="invalid_standard" className="alert alert-error">
          <button aria-label="Close" className="dismiss_alert close" onClick={this.hideAlert}>×</button>
          {this.renderInvalidStandardMessage()}
        </div>
      );
    },

    render: function () {
      return (
        <div>
          <div className="grading_standard react_grading_standard pad-box-mini border border-trbl border-round"
               id={this.renderIdNames()}>
            {this.renderStandardAlert()}
            <div>
              <table>
                <caption className="screenreader-only">
                  {I18n.t("A table containing the name of the grading scheme and icons for editing or deleting the scheme.")}
                </caption>
                <thead>
                  <tr>
                    <th scope="col" className="insert_row_container" tabIndex="-1"/>
                    <th scope="col" colSpan="5" className="standard_title">
                      {this.renderIconsAndTitle()}
                    </th>
                  </tr>
                  <tr>
                    <th scope="col" className="insert_row_container"/>
                    <th scope="col" className="name_header">{I18n.t("Name:")}</th>
                    <th scope="col" className="range_container" colSpan="2">
                      <div className="range_label">{I18n.t("Range:")}</div>
                      <div className="clear"></div>
                    </th>
                  </tr>
                </thead>
              </table>
              <table className="grading_standard_data">
                <caption className="screenreader-only">
                  {I18n.t("A table that contains the grading scheme data. Each row contains a name, a maximum percentage, and a minimum percentage. In addition, each row contains an icon to add a new row below, and an icon to delete the current row.")}
                </caption>
                <thead ariaHidden="true"><tr><td></td><td></td><td></td><td></td><td></td></tr></thead>
                <tbody>
                  {this.renderDataRows()}
                </tbody>
              </table>
              {this.renderSaveAndCancelButtons()}
            </div>
          </div>
        </div>
      );
    }
  });

  return GradingStandard;

});

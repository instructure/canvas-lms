/** @jsx React.DOM */

define([
  'old_unsupported_dont_use_react',
  'jsx/grading/data_row',
  'jquery',
  'i18n!external_tools'
],
function(React, DataRow, $, I18n) {

  var GradingStandard = React.createClass({

    getInitialState: function() {
      return {
        standard: this.props.standard,
        permissions: this.props.permissions,
        editingStandard: $.extend(true, {}, this.props.standard),
        editing: this.props.editing,
        saving: false,
        justAdded: this.props.justAdded
      };
    },

    componentWillReceiveProps: function(nextProps) {
      this.setState({
        standard: nextProps.standard,
        permissions: nextProps.permissions,
        editingStandard: $.extend(true, {}, this.props.standard),
        editing: nextProps.editing,
        saving: nextProps.saving,
        justAdded: nextProps.justAdded
      });
    },

    componentDidUpdate: function(prevProps, prevState) {
      if(this.state.editing !== prevState.editing) this.refs.gradingStandardTitle.getDOMNode().focus();
    },

    startEditing: function(event) {
      event.preventDefault();
      this.setState({editing: true});
    },

    stopEditing: function() {
      if(this.state.justAdded){
        return this.props.onDeleteGradingStandardNoWarning(this.props.key);
      }else{
        this.setState({standard: this.state.standard, editing: false,
                       editingStandard: $.extend(true, {}, this.state.standard)});
      }
    },

    triggerDeleteGradingStandard: function(event) {
      return this.props.onDeleteGradingStandard(event, this.props.key);
    },

    dataFormattedForPost: function() {
      var formattedData = { grading_standard: { title: this.state.editingStandard.title, standard_data: {} } };
      for(i = 0; i < this.state.editingStandard.data.length; i++){
        formattedData["grading_standard"]["standard_data"]["scheme_" + i] = {
          name: this.state.editingStandard.data[i][0],
          value: Math.round(this.state.editingStandard.data[i][1] * 10000)/100
        };
      };
      return formattedData;
    },

    saveGradingStandard: function() {
      var self = this;
      var formattedData = this.dataFormattedForPost();
      this.setState({saving: true});
      $.ajax({
        type: "PUT",
        url: ENV.GRADING_STANDARDS_URL + "/" + this.state.editingStandard.id,
        data: formattedData,
        dataType: "json"
      })
        .success(function(response){
          self.setState({standard: response.grading_standard, editing: false,
                         editingStandard: $.extend(true, {}, response.grading_standard),
                         saving: false, justAdded: false});
        })
        .error(function(){
          self.setState({saving: false});
          $.flashError(I18n.t("There was a problem saving the grading scheme"));
        });
    },

    assessedAssignment: function() {
      return this.state.standard && this.state.standard["assessed_assignment?"];
    },

    deleteDataRow: function(index) {
      this.state.editingStandard.data.splice(index, 1);
      this.setState({editingStandard: this.state.editingStandard});
    },

    insertGradingStandardRow: function(index) {
      var newEditingStandard = $.extend(true, {}, this.state.editingStandard);
      newEditingStandard.data.splice(index + 1, 0, [""," "]);
      this.setState({editingStandard: newEditingStandard});
    },

    titleChange: function(event) {
      this.state.editingStandard.title = event.target.value;
      this.setState({editingStandard: this.state.editingStandard});
    },

    changeRowMinScore: function(index, newMinVal) {
      this.state.editingStandard.data[index][1] = newMinVal;
      this.setState({editingStandard: this.state.editingStandard});
    },

    changeRowName: function(index, newRowName) {
      this.state.editingStandard.data[index][0] = newRowName;
      this.setState({editingStandard: this.state.editingStandard});
    },

    renderCannotManageMessage: function() {
      if(this.state.standard.context_name){
        return (
          <div>
            {I18n.t("(%{context}: %{contextName})", { context: this.state.standard.context_type.toLowerCase(), contextName: this.state.standard.context_name })}
          </div>
        );
      }
      return (
        <div>
          {I18n.t("(%{context} level)", { context: this.state.standard.context_type.toLowerCase() })}
        </div>
      );
    },

    renderIdNames: function() {
      if(this.assessedAssignment()) return "grading_standard_blank";
      return "grading_standard_" + (this.state.standard ? this.state.standard.id : "blank");
    },

    renderTitle: function() {
      if(this.state.editing){
        return (
          <div className="pull-left" tabIndex="0">
            <input type="text" onChange={this.titleChange} className="grading_standard_title"
                   name="grading_standard[title]" className="scheme_name" title={I18n.t("Grading standard title")}
                   value={this.state.editingStandard.title} ref="gradingStandardTitle"/>
          </div>
        );
      }
      return (
        <div className="pull-left" tabIndex="0" ref="gradingStandardTitle">
          <div className="title">
            <span className="screenreader-only">{I18n.t("Grading standard title")}</span>
            {this.state.standard.title}
          </div>
        </div>
      );
    },

    renderDataRows: function() {
      var data = this.state.editing ? this.state.editingStandard.data : this.state.standard.data;
      return data.map(function(item, idx, array){
        return (
          <DataRow key={idx} row={item} siblingRow={array[idx - 1]} editing={this.state.editing}
                   onDeleteRow={this.deleteDataRow} onInsertRow={this.insertGradingStandardRow}
                   onRowMinScoreChange={this.changeRowMinScore} onRowNameChange={this.changeRowName}/>
        );
      }, this);
    },

    renderSaveButton: function() {
      if(this.state.saving){
        return (
          <button type="button" className="btn btn-primary save_button" disabled="true">
            {I18n.t("Saving...")}
          </button>
        );
      }
      return (
        <button type="button" onClick={this.saveGradingStandard} className="btn btn-primary save_button">
          {I18n.t("Save")}
        </button>
      );
    },

    renderSaveAndCancelButtons: function() {
      if(this.state.editing){
        return (
          <div className="form-actions">
            <button type="button" onClick={this.stopEditing} className="btn cancel_button">
              {I18n.t("Cancel")}
            </button>
              {this.renderSaveButton()}
          </div>
        );
      }
      return null;
    },

    renderEditIcon: function() {
      if(!this.state.editing){
        return(
          <a href="#" onClick={this.startEditing} title={I18n.t("Edit Grading Scheme")}
             className={"edit_grading_standard_link no-hover " + (this.assessedAssignment() ? "read_only" : "")}
             tabIndex="1">
             <span className="screenreader-only">{I18n.t("Edit Grading Scheme")}</span>
            <i className="icon-edit standalone-icon"/>
          </a>
        );
      }
      return null;
    },

    renderIconsAndTitle: function() {
      if(this.state.permissions.manage){
        return (
          <div>
            {this.renderTitle()}
            <div className="links">
              {this.renderEditIcon()}
              <a href="#" title={I18n.t("Delete Grading Scheme")} onClick={this.triggerDeleteGradingStandard}
                 className="delete_grading_standard_link no-hover" tabIndex="1">
                 <span className="screenreader-only">{I18n.t("Delete Grading Scheme")}</span>
                <i className="icon-trash standalone-icon"/>
              </a>
            </div>
          </div>
        );
      }
      return (
        <div>
          {this.renderTitle()}
          <div className="disabled-links">
            <i className="icon-edit standalone-icon"/>
            <i className="icon-trash standalone-icon"/>
          </div>
          <div className="pull-left cannot-manage-notification">
            {this.renderCannotManageMessage()}
          </div>
        </div>
      );
    },

    render: function () {
      return (
        <div>
          <div className="grading_standard react_grading_standard pad-box-mini border border-trbl border-round"
               id={this.renderIdNames()}>
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

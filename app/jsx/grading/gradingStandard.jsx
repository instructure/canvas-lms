/** @jsx React.DOM */

define([
  'react',
  'jsx/grading/dataRow',
  'jquery',
  'i18n!external_tools'
],
function(React, DataRow, $, I18n) {

  var GradingStandard = React.createClass({

    getInitialState: function() {
      return {
        standard: this.props.standard,
        editingStandard: $.extend(true, {}, this.props.standard),
        saving: false
      };
    },

    componentWillReceiveProps: function(nextProps) {
      this.setState({
        standard: nextProps.standard,
        editingStandard: $.extend(true, {}, this.props.standard),
        saving: nextProps.saving
      });
    },

    componentDidMount: function() {
      if(this.props.justAdded) this.refs.title.getDOMNode().focus();
    },

    componentDidUpdate: function(prevProps, prevState) {
      if(this.props.editing !== prevProps.editing){
       this.refs.title.getDOMNode().focus();
       this.setState({editingStandard: $.extend(true, {}, this.state.standard)})
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
      this.setState({saving: true},
        this.props.onSaveGradingStandard(this.state.editingStandard)
      );
    },

    assessedAssignment: function() {
      return !!(this.state.standard && this.state.standard["assessed_assignment?"]);
    },

    deleteDataRow: function(index) {
      if(this.moreThanOneDataRowRemains()){
        this.state.editingStandard.data.splice(index, 1);
        this.setState({editingStandard: this.state.editingStandard});
      }
    },

    moreThanOneDataRowRemains: function() {
      return this.state.editingStandard.data.length > 1;
    },

    insertGradingStandardRow: function(index) {
      this.state.editingStandard.data.splice(index + 1, 0, [""," "]);
      this.setState({editingStandard: this.state.editingStandard});
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
      if(this.props.permissions.manage && this.props.othersEditing) return null;
      if(this.state.standard.context_name){
        return (
          <div ref="cannotManageMessage">
            {I18n.t("(%{context}: %{contextName})", { context: this.state.standard.context_type.toLowerCase(), contextName: this.state.standard.context_name })}
          </div>
        );
      }
      return (
        <div ref="cannotManageMessage">
          {I18n.t("(%{context} level)", { context: this.state.standard.context_type.toLowerCase() })}
        </div>
      );
    },

    renderIdNames: function() {
      if(this.assessedAssignment()) return "grading_standard_blank";
      return "grading_standard_" + (this.state.standard ? this.state.standard.id : "blank");
    },

    renderTitle: function() {
      if(this.props.editing){
        return (
          <div className="pull-left" tabIndex="0">
            <input type="text" onChange={this.titleChange} className="grading_standard_title"
                   name="grading_standard[title]" className="scheme_name" title={I18n.t("Grading standard title")}
                   value={this.state.editingStandard.title} ref="title"/>
          </div>
        );
      }
      return (
        <div className="pull-left" tabIndex="0">
          <div className="title" ref="title">
            <span className="screenreader-only">{I18n.t("Grading standard title")}</span>
            {this.state.standard.title}
          </div>
        </div>
      );
    },

    renderDataRows: function() {
      var data = this.props.editing ? this.state.editingStandard.data : this.state.standard.data;
      return data.map(function(item, idx, array){
        return (
          <DataRow key={idx} uniqueId={idx} row={item} siblingRow={array[idx - 1]} editing={this.props.editing}
                   onDeleteRow={this.deleteDataRow} onInsertRow={this.insertGradingStandardRow}
                   onlyDataRowRemaining={!this.moreThanOneDataRowRemains()}
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

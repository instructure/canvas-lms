/** @jsx React.DOM */

define([
  'old_unsupported_dont_use_react',
  'i18n!external_tools'
],
function(React, I18n) {

  var DataRow = React.createClass({

    getInitialState: function() {
      return {
        row: this.getRowData(this.props),
        siblingRow: this.getSiblingRowData(this.props),
        editing: this.props.editing,
        displayZeroAsBlank: false,
        stillEntering: false,
        showInsertRowLink: false,
        showBottomBorder: false
      };
    },

    getRowData: function(props){
      var rowData = {name: props.row[0], minScore: props.row[1], maxScore: null};
      rowData.maxScore = props.key === 0 ? 1.0 : props.siblingRow[1];
      return rowData;
    },

    getSiblingRowData: function(props){
      return !props.siblingRow ? null : { name: props.siblingRow[0], minScore: props.siblingRow[1] };
    },

    componentWillReceiveProps: function(nextProps) {
      this.setState({
        row: this.getRowData(nextProps),
        siblingRow: this.getSiblingRowData(nextProps),
        editing: nextProps.editing,
        displayZeroAsBlank: false,
        stillEntering: false,
        showInsertRowLink: false,
        showBottomBorder: false
      });
    },

    decimalToPercent: function(decimal){
      return Math.round(decimal * 10000)/100;
    },

    triggerRowNameChange: function(event){
      this.props.onRowNameChange(this.props.key, event.target.value);
    },

    triggerRowMinScoreChange: function(event){
      var inputVal = event.target.value;
      var lastChar = inputVal.substr(inputVal.length - 1);
      if(inputVal >= 0 && inputVal <= 100){
        var newRow = this.state.row;
        newRow.minScore = inputVal / 100;
        if(inputVal === "" || lastChar === "."){
          this.setState({row: newRow,
                         displayZeroAsBlank: inputVal === "",
                         stillEntering: lastChar === "."});
        } else{
          this.props.onRowMinScoreChange(this.props.key, this.state.row.minScore);
        };
      }
    },

    triggerDeleteRow: function(event){
      event.preventDefault();
      return this.props.onDeleteRow(this.props.key);
    },

    showInsertRowLink: function(){
      this.setState({showInsertRowLink: true});
    },

    hideInsertRowLink: function(){
      this.setState({showInsertRowLink: false});
    },

    triggerInsertRow: function(event){
      event.preventDefault();
      return this.props.onInsertRow(this.props.key);
    },

    renderInsertRowLink: function(){
      if(this.state.showInsertRowLink){
        return (
          <a href="#" className="insert_grading_standard_link" onMouseEnter={this.showBottomBorder}
             onFocus={this.showBottomBorder} onBlur={this.hideBottomBorder}
             onMouseLeave={this.hideBottomBorder} onClick={this.triggerInsertRow}>
            <i className="icon-add standalone-icon">
              <span className="screenreader-only">{I18n.t("Insert row below")}</span>
            </i>
          </a>);
      }
      return null;
    },

    showBottomBorder: function(){
      this.setState({showBottomBorder: true});
    },

    hideBottomBorder: function(){
      this.setState({showBottomBorder: false});
    },

    renderMaxScore: function(){
      var maxScore = this.decimalToPercent(this.state.row.maxScore);
      return maxScore === 100 ? maxScore : "< " + maxScore;
    },

    renderMinScore: function(){
      if(this.state.editing && this.state.row.minScore === 0 && this.state.displayZeroAsBlank) return "";
      if(this.state.stillEntering) return this.decimalToPercent(this.state.row.minScore) + ".";
      return this.decimalToPercent(this.state.row.minScore);
    },

    renderViewMode: function() {
      return (
        <tr className="grading_standard_row react_grading_standard_row">
          <td className="insert_row_icon_container"/>
          <td className="row_name_container">
            <div className="name">
              {this.state.row.name}
            </div>
          </td>
          <td className="row_cell max_score_cell" ariaLabel={I18n.t('Upper limit of range')} >
            <div>
              <span className="max_score" title="Upper limit of range">
                {this.renderMaxScore() + "%"}
              </span>
            </div>
          </td>
          <td className="row_cell">
            <div>
              <span className="range_to">{I18n.t("to %{minScore}%", {minScore: this.renderMinScore()})}</span>
              <span className="min_score">
              </span>
            </div>
          </td>
          <td className="row_cell last_row_cell"/>
        </tr>
      );
    },

    renderEditMode: function() {
      return (
        <tr className={this.state.showBottomBorder ?
                       "grading_standard_row react_grading_standard_row border_below" :
                       "grading_standard_row react_grading_standard_row"}
            onMouseEnter={this.showInsertRowLink} onMouseLeave={this.hideInsertRowLink}
            onFocus={this.showInsertRowLink}>
          <td className="insert_row_icon_container" tabIndex="0">
            {this.renderInsertRowLink()}
          </td>
          <td className="row_name_container">
            <div>
              <input type="text" onChange={this.triggerRowNameChange} className="standard_name"
                     title={I18n.t('Range name')} ariaLabel={I18n.t('Range name')}
                     name={"grading_standard[standard_data][scheme_" + this.props.key + "[name]"}
                     value={this.state.row.name}>
              </input>
            </div>
          </td>
          <td className="row_cell max_score_cell edit_max_score">
            <span className="edit_max_score">
              {this.renderMaxScore() + "%"}
              <span className="screenreader-only">{I18n.t("Upper limit of range")}</span>
            </span>
          </td>
          <td className="row_cell">
            <div>
              <span className="range_to" ariaHidden="true">{I18n.t("to ")}</span>
              <input type="text" onChange={this.triggerRowMinScoreChange} className="standard_value"
                     title={I18n.t('Lower limit of range')} ariaLabel={I18n.t('Lower limit of range')}
                     name={"grading_standard[standard_data][scheme_" + this.props.key + "][value]"}
                     value={this.renderMinScore()}/>
              <span ariaHidden="true"> % </span>
            </div>
          </td>
          <td className="row_cell last_row_cell">
            <a href="#" onClick={this.triggerDeleteRow} className="delete_row_link no-hover"
               title={I18n.t('Remove row')}>
              <i className="icon-end standalone-icon">
                <span className="screenreader-only">{I18n.t("Remove Row")}</span>
              </i>
            </a>
          </td>
        </tr>
      );
    },

    render: function () {
      return this.state.editing ? this.renderEditMode() : this.renderViewMode();
    }
  });

  return DataRow;

});

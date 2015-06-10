/** @jsx React.DOM */

define([
  'react',
  'i18n!external_tools'
],
function(React, I18n) {

  var DataRow = React.createClass({

    getInitialState: function() {
      return {
        showInsertRowLink: false,
        showBottomBorder: false
      };
    },

    getRowData: function(){
      var rowData = {name: this.props.row[0], minScore: this.props.row[1], maxScore: null};
      rowData.maxScore = this.props.uniqueId === 0 ? 100 : this.props.siblingRow[1];
      return rowData;
    },

    componentWillReceiveProps: function(nextProps) {
      this.setState({
        showInsertRowLink: false,
        showBottomBorder: false
      });
    },

    triggerRowNameChange: function(event){
      this.props.onRowNameChange(this.props.uniqueId, event.target.value);
    },

    triggerRowMinScoreChange: function(event){
      var inputVal = event.target.value;
      if(inputVal >= 0 && inputVal <= 100){
        this.props.onRowMinScoreChange(this.props.uniqueId, inputVal);
      }
    },

    triggerDeleteRow: function(event){
      event.preventDefault();
      return this.props.onDeleteRow(this.props.uniqueId);
    },

    showInsertRowLink: function(){
      this.setState({showInsertRowLink: true});
    },

    hideInsertRowLink: function(){
      this.setState({showInsertRowLink: false});
    },

    triggerInsertRow: function(event){
      event.preventDefault();
      return this.props.onInsertRow(this.props.uniqueId);
    },

    renderInsertRowLink: function(){
      if(this.state.showInsertRowLink){
        return (
          <a href="#" ref="insertRowLink" className="insert_grading_standard_link"
             onMouseEnter={this.showBottomBorder} onFocus={this.showBottomBorder}
             onBlur={this.hideBottomBorder} onMouseLeave={this.hideBottomBorder}
             onClick={this.triggerInsertRow}>
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
      var maxScore = this.props.round(this.getRowData().maxScore);
      return maxScore === 100 ? String(maxScore) : "< " + maxScore;
    },

    renderMinScore: function(){
      var score = String(this.getRowData().minScore);
      if(!this.props.editing) return String(this.props.round(score));
      return score;
    },

    renderDeleteLink: function(){
      if(this.props.onlyDataRowRemaining) return null;
      return(
        <a href="#" ref="deleteLink" onClick={this.triggerDeleteRow}
           className="delete_row_link no-hover" title={I18n.t('Remove row')}>
          <i className="icon-end standalone-icon">
            <span className="screenreader-only">{I18n.t("Remove Row")}</span>
          </i>
        </a>
      );
    },

    renderViewMode: function() {
      return (
        <tr className="grading_standard_row react_grading_standard_row" ref="viewContainer">
          <td className="insert_row_icon_container"/>
          <td className="row_name_container">
            <div className="name" ref="name">
              {this.getRowData().name}
            </div>
          </td>
          <td className="row_cell max_score_cell" ariaLabel={I18n.t('Upper limit of range')} >
            <div>
              <span className="max_score" ref="maxScore" title="Upper limit of range">
                {this.renderMaxScore() + "%"}
              </span>
            </div>
          </td>
          <td className="row_cell">
            <div>
              <span className="range_to" ref="minScore">{I18n.t("to %{minScore}%", {minScore: this.renderMinScore()})}</span>
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
            ref="editContainer"
            onMouseEnter={this.showInsertRowLink} onMouseLeave={this.hideInsertRowLink}
            onFocus={this.showInsertRowLink}>
          <td className="insert_row_icon_container" tabIndex="0">
            {this.renderInsertRowLink()}
          </td>
          <td className="row_name_container">
            <div>
              <input type="text" ref="nameInput" onChange={this.triggerRowNameChange}
                     className="standard_name" title={I18n.t('Range name')} ariaLabel={I18n.t('Range name')}
                     name={"grading_standard[standard_data][scheme_" + this.props.uniqueId + "[name]"}
                     value={this.getRowData().name}/>
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
              <input type="text" ref="minScoreInput" onChange={this.triggerRowMinScoreChange}
                     className="standard_value" title={I18n.t('Lower limit of range')}
                     ariaLabel={I18n.t('Lower limit of range')}
                     name={"grading_standard[standard_data][scheme_" + this.props.uniqueId + "][value]"}
                     value={this.renderMinScore()}/>
              <span ariaHidden="true"> % </span>
            </div>
          </td>
          <td className="row_cell last_row_cell">
            {this.renderDeleteLink()}
          </td>
        </tr>
      );
    },

    render: function () {
      return this.props.editing ? this.renderEditMode() : this.renderViewMode();
    }
  });

  return DataRow;

});

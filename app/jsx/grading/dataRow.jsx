define([
  'react',
  'i18n!external_tools'
],
function(React, I18n) {

  var DataRow = React.createClass({

    getInitialState: function() {
      return { showBottomBorder: false };
    },

    getRowData: function(){
      var rowData = {name: this.props.row[0], minScore: this.props.row[1], maxScore: null};
      rowData.maxScore = this.props.uniqueId === 0 ? 100 : this.props.siblingRow[1];
      return rowData;
    },

    componentWillReceiveProps: function(nextProps) {
      this.setState({ showBottomBorder: false });
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

    triggerInsertRow: function(event){
      event.preventDefault();
      return this.props.onInsertRow(this.props.uniqueId);
    },

    renderInsertRowButton: function(){
      return (
        <button className="Button Button--icon-action insert_row_button"
                onMouseEnter={this.showBottomBorder} onFocus={this.showBottomBorder}
                onBlur={this.hideBottomBorder} onMouseLeave={this.hideBottomBorder}
                onClick={this.triggerInsertRow} type="button">
          <span className="screenreader-only">{I18n.t("Insert row below")}</span>
          <i className="icon-add"/>
        </button>);
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

    renderDeleteRowButton: function(){
      if(this.props.onlyDataRowRemaining) return null;
      return(
        <button ref="deleteButton" className="Button Button--icon-action delete_row_button"
                onClick={this.triggerDeleteRow} type="button">
          <span className="screenreader-only">{I18n.t("Remove row")}</span>
          <i className="icon-end"/>
        </button>
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
            ref="editContainer">
          <td className="insert_row_icon_container">
            {this.renderInsertRowButton()}
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
            {this.renderDeleteRowButton()}
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

/** @jsx React.DOM */

define([
  'react',
  'i18n!assignments'
], (React, I18n) => {

  var DueDateAddRowButton = React.createClass({

    propTypes: {
      display: React.PropTypes.bool.isRequired
    },

    render(){
      if(!this.props.display){ return null }

      return(
        <button id        = "add_due_date"
                ref       = "addButton"
                className = "Button Button--add-row"
                onClick   = {this.props.handleAdd}
                type      = "button" >
          <i className="icon-plus" aria-label={I18n.t("Add new set of due dates")} />
          {I18n.t("Add")}
        </button>
      )
    }
  })

  return DueDateAddRowButton
});
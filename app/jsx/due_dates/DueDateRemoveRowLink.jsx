/** @jsx React.DOM */

define([
  'react',
  'i18n!assignments'
], (React, I18n) => {

  var DueDateRemoveRowLink = React.createClass({

    propTypes: {
      handleClick: React.PropTypes.func.isRequired
    },

    render(){
      return(
        <div className = "DueDateRow__RemoveRow">
          <button className  = 'Button Button--link'
                  onClick    = {this.props.handleClick}
                  ref        = "removeRowIcon"
                  href       = "#"
                  title      = {I18n.t('Remove These Dates')}
                  aria-label = {I18n.t('Remove These Dates')}
                  type       = "button">
            <i className="icon-x" role="presentation" />
          </button>
        </div>
      )
    }
  })

  return DueDateRemoveRowLink;
});
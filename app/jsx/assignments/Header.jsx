/** @jsx React.DOM */

define([
  'react',
  'i18n!moderated_grading'
], function (React, I18n) {

  var Header = React.createClass({
    displayName: 'Header',

    propTypes: {
      actions: React.PropTypes.object.isRequired
    },

    handlePublishClick () {
      // Make a better looking confirm one day
      var confirmMessage = I18n.t('Are you sure you want to do this? It cannot be undone and will override existing grades in the gradebook.')
      if (window.confirm(confirmMessage)) {
        this.props.actions.publishGrades();
      }
    },

    render () {
      return (
        <div className='ModeratedGrading__Header content-box'>
          <div className='grid-row'>
            <div className='ModeratedGrading__Header-Instructions col-xs-11'>
              {I18n.t('Select assignments for review')}
            </div>
            <div className='ModeratedGrading__Header-Buttons col-xs-1'>
              <button
                type='button'
                className='ModeratedGrading__Header-PublishBtn Button Button--primary'
                onClick={this.handlePublishClick}
              >
                {I18n.t('Publish')}
              </button>
            </div>
          </div>
        </div>
      );
    }

  });

  return Header;


});
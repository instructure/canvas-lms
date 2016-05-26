define([
  'react',
  'i18n!moderated_grading'
], function (React, I18n) {

  var Header = React.createClass({
    displayName: 'Header',

    propTypes: {
      onPublishClick: React.PropTypes.func.isRequired,
      onReviewClick: React.PropTypes.func.isRequired,
      published: React.PropTypes.bool.isRequired,
      selectedStudentCount: React.PropTypes.number.isRequired,
      inflightAction: React.PropTypes.shape({
        review: React.PropTypes.bool.isRequired,
        publish: React.PropTypes.bool.isRequired
      }).isRequired
    },

    noStudentSelected () {
      return this.props.selectedStudentCount === 0;
    },
    handlePublishClick () {
      // TODO: Make a better looking confirm one day
      var confirmMessage = I18n.t('Are you sure you want to do this? It cannot be undone and will override existing grades in the gradebook.')
      if (window.confirm(confirmMessage)) {
        this.props.onPublishClick();
      }
    },
    renderPublishedMessage () {
      if (this.props.published) {
        return (

          <div className="ic-notification">
            <div className="ic-notification__icon" aria-hidden='true' role="presentation">
              <i className="icon-info"></i>
            </div>
            <div className="ic-notification__content">
              <div className="ic-notification__message">
                <div className="ic-notification__title">
                  {I18n.t('Attention!')}
                </div>
                <span className="notification_message">
                  {I18n.t('This page cannot be modified because grades have already been posted.')}
                </span>
              </div>
            </div>
          </div>
        );
      }
    },
    render () {
      return (
        <div>
          {this.renderPublishedMessage()}
          <div className='ModeratedGrading__Header ic-Action-header'>
            <div className='ic-Action-header__Primary'>
              <div className='ic-Action-header__Heading ModeratedGrading__Header-Instructions'>
                {I18n.t('Select students for review')}
              </div>
            </div>
            <div className='ic-Action-header__Secondary ModeratedGrading__Header-Buttons '>
              <button
                ref='addReviewerBtn'
                type='button'
                className='ModeratedGrading__Header-AddReviewerBtn Button'
                onClick={this.props.onReviewClick}
                disabled={
                  this.props.published ||
                  this.noStudentSelected() ||
                  this.props.inflightAction.review
                }
              >
                <span className='screenreader-only'>{I18n.t('Add a reviewer for the selected students')}</span>
                <span aria-hidden='true'>
                  <i className='icon-plus' />
                  {I18n.t(' Reviewer')}
                </span>
              </button>
              <button
                ref='publishBtn'
                type='button'
                className='ModeratedGrading__Header-PublishBtn Button Button--primary'
                onClick={this.handlePublishClick}
                disabled={this.props.published || this.props.inflightAction.publish}
              >
                {I18n.t('Post')}
              </button>
            </div>
          </div>
      </div>
      );
    }

  });

  return Header;

});

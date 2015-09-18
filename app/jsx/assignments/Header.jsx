/** @jsx React.DOM */

define([
  'react',
  'i18n!moderated_grading'
], function (React, I18n) {

  var Header = React.createClass({
    displayName: 'Header',

    propTypes: {
      actions: React.PropTypes.object.isRequired,
      store: React.PropTypes.object.isRequired
    },

    getInitialState () {
      return this.props.store.getState().assignment;
    },

    componentDidMount () {
      this.props.store.subscribe(this.handleChange);
    },

    handleChange () {
      this.setState(this.props.store.getState().assignment);
    },

    handlePublishClick () {
      // TODO: Make a better looking confirm one day
      var confirmMessage = I18n.t('Are you sure you want to do this? It cannot be undone and will override existing grades in the gradebook.')
      if (window.confirm(confirmMessage)) {
        this.props.store.dispatch(this.props.actions.publishGrades());
      }
    },

    handleReviewerClick () {
      this.props.store.dispatch(this.props.actions.addStudentToModerationSet());
    },

    render () {
      return (
        <div className='ModeratedGrading__Header ic-Action-header'>
          <div className='ic-Action-header__Primary'>
            <div className='ic-Action-header__Heading ModeratedGrading__Header-Instructions'>
              {I18n.t('Select assignments for review')}
            </div>
          </div>
          <div className='ic-Action-header__Secondary ModeratedGrading__Header-Buttons '>
            <button
              type='button'
              className='ModeratedGrading__Header-AddReviewerBtn Button'
              onClick={this.handleReviewerClick}
            >
              <i className='icon-plus' />
              {I18n.t(' Reviewer')}
            </button>
            <button
              type='button'
              className='ModeratedGrading__Header-PublishBtn Button Button--primary'
              onClick={this.handlePublishClick}
              disabled={this.state.published}
            >
              {I18n.t('Publish')}
            </button>
          </div>
        </div>
      );
    }

  });

  return Header;


});

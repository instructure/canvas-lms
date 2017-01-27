import React from 'react'
import I18n from 'i18n!help_dialog'
import CreateTicketForm from './CreateTicketForm'
import TeacherFeedbackForm from './TeacherFeedbackForm'
import HelpLinks from './HelpLinks'

  const HelpDialog = React.createClass({
    propTypes: {
      links: React.PropTypes.array,
      hasLoaded: React.PropTypes.bool,
      onFormSubmit: React.PropTypes.func
    },
    getDefaultProps() {
      return {
        hasLoaded: false,
        links: [],
        onFormSubmit: function () {}
      };
    },
    getInitialState () {
      return {
        view: 'links'
      }
    },
    handleLinkClick (url) {
      this.setState({view: url});
    },
    handleCancelClick () {
      this.setState({view: 'links'});
    },
    render() {
      switch (this.state.view) {
        case '#create_ticket':
          return (
            <CreateTicketForm
              onCancel={this.handleCancelClick}
              onSubmit={this.props.onFormSubmit}
            />
          );
        case '#teacher_feedback':
          return (
            <TeacherFeedbackForm
              onCancel={this.handleCancelClick}
              onSubmit={this.props.onFormSubmit}
            />
          );
        default:
          return (
            <HelpLinks 
              links={this.props.links} 
              hasLoaded={this.props.hasLoaded} 
              onClick={this.handleLinkClick} />
          );
      }
    }
  });

export default HelpDialog

/** @jsx React.DOM */

define([
  'jquery',
  'react',
  'i18n!moderated_grading',
  'compiled/jquery.rails_flash_notifications'
], function ($, React, I18n) {

  var FlashMessageHolder = React.createClass({
    displayName: 'FlashMessageHolder',

    getInitialState () {
      return this.props.store.getState().flashMessage;
    },

    componentDidMount () {
      this.props.store.subscribe(this.handleChange);
    },

    handleChange () {
      this.setState(this.props.store.getState().flashMessage);
    },

    shouldComponentUpdate (nextProps, nextState) {
      return nextState.time > this.state.time;
    },

    componentWillUpdate (nextProps, nextState) {
      if (nextState.error) {
        $.flashError(nextState.message);
      } else {
        $.flashMessage(nextState.message);
      }
    },

    render () {
      return null;
    }
  });

  return FlashMessageHolder;
});

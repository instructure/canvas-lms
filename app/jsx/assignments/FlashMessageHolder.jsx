/** @jsx React.DOM */

define([
  'jquery',
  'react',
  'i18n!moderated_grading',
  'compiled/jquery.rails_flash_notifications'
], function ($, React, I18n) {

  var FlashMessageHolder = React.createClass({
    displayName: 'FlashMessageHolder',

    propTypes: {
      time: React.PropTypes.number.isRequired,
      message: React.PropTypes.string.isRequired,
      error: React.PropTypes.bool,
      onError: React.PropTypes.func,
      onSuccess: React.PropTypes.func
    },

    shouldComponentUpdate (nextProps, nextState) {
      return nextProps.time > this.props.time;
    },

    componentWillUpdate (nextProps, nextState) {
      if (nextProps.error) {
        (nextProps.onError) ?
        nextProps.onError(nextProps.message) :
        $.flashError(nextProps.message);
      } else {
        (nextProps.onSuccess) ?
        nextProps.onSuccess(nextProps.message) :
        $.flashMessage(nextProps.message);
      }
    },

    render () {
      return null;
    }
  });

  return FlashMessageHolder;
});

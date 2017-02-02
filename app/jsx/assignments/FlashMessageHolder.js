import $ from 'jquery'
import React from 'react'
import I18n from 'i18n!moderated_grading'
import 'compiled/jquery.rails_flash_notifications'

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

export default FlashMessageHolder

/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'jquery',
  'react'
], function (I18n, $, React) {

  return React.createClass({
    displayName: 'Lti2Iframe',

    propTypes: {
      registrationUrl: React.PropTypes.string.isRequired,
      handleInstall: React.PropTypes.func.isRequired
    },

    componentDidMount() {
      window.addEventListener('message', function(e) {
        var message = e.data;
        if (typeof message !== 'object') {
          message = JSON.parse(e.data);
        }
        if (message.subject === 'lti.lti2Registration') {
          this.props.handleInstall(message);
        }
      }.bind(this), false);
    },

    getLaunchUrl() {
      return ENV.LTI_LAUNCH_URL + '?display=borderless&tool_consumer_url=' + this.props.registrationUrl;
    },

    render() {
      return (
        <div className="ReactModal__InnerSection ReactModal__Body" style={{padding: '0px !important'}}>
          <iframe src={this.getLaunchUrl()} style={{width: '100%', padding: 0, margin: 0, height: 500, border: 0}}/>
        </div>
      )
    }
  });

});
/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'jquery',
  'react',
  'react-router'
], function (I18n, $, React, {Navigation}) {

  return React.createClass({
    displayName: 'AppTile',

    mixins: [Navigation],

    getInitialState() {
      return {
        isHidingDetails: true
      };
    },

    showDetails() {
      if (this.state.isHidingDetails) {
        $(this.refs.details.getDOMNode()).fadeTo(200, 0.85);
        this.setState({isHidingDetails: false});
      }
    },

    hideDetails() {
      $(this.refs.details.getDOMNode()).fadeOut(200, function () {
        if (this.isMounted()) {
          this.setState({isHidingDetails: true});
        }
      }.bind(this));
    },

    handleKeyDown(e) {
      if (e.which == 13) {
        this.handleClick(e);
      }
    },

    handleClick(e) {
      e.preventDefault();
      this.transitionTo('appDetails', {shortName: this.props.app.get('short_name')});
    },

    installedRibbon() {
      if (this.props.app.attributes.is_installed) {
        return <div className="installed-ribbon">{I18n.t('Installed')}</div>;
      }
    },

    render() {
      var appId = 'app_' + this.props.app.get('id');

      return (
        <a role="button" tabIndex="0" aria-label={I18n.t("View %{name} app", { name: this.props.app.attributes.name})} className="app"
            onMouseEnter={this.showDetails} onMouseLeave={this.hideDetails} onClick={this.handleClick} onKeyDown={this.handleKeyDown}>
          <div id={appId}>
            {this.installedRibbon()}

            <img className="banner_image" alt={this.props.app.attributes.name} src={this.props.app.attributes.banner_image_url} />
            <div ref="details" className="details">
              <div className="content">
                <span className="name">{this.props.app.attributes.name}</span>
                <div className="desc">{this.props.app.attributes.short_description}</div>
              </div>
            </div>
          </div>
        </a>
      );
    }
  });

});
/** @jsx React.DOM */

define([
  'react',
  'jquery'
], (React, $) => {

  var DOCUMENT_NODE = 9;
  var ELEMENT_NODE = 1;

  var SVGWrapper = React.createClass({
    propTypes: {
      url: React.PropTypes.string.isRequired
    },

    componentWillReceiveProps: function (newProps) {
      if (newProps.url !== this.props.url) {
        this.fetchSVG();
      }
    },

    componentDidMount: function () {
      this.fetchSVG();
    },

    fetchSVG: function () {
      $.ajax(this.props.url, {
        success: function (data) {
          this.svg = data;

          if (data.nodeType === DOCUMENT_NODE) {
            this.svg = data.firstChild;
          }

          if (this.svg.nodeType !== ELEMENT_NODE && this.svg.nodeName !== 'SVG') {
            throw new Error('SVGWrapper: SVG Element must be returned by request to ' + this.props.url);
          }

          this.svg.setAttribute('focusable', false);
          this.getDOMNode().appendChild(this.svg);
        }.bind(this)
      });
    },

    render: function () {
      return <span/>;
    }
  });

  return SVGWrapper;

});

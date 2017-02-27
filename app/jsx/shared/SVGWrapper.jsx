define([
  'react',
  'jquery'
], (React, $) => {
  const DOCUMENT_NODE = 9;
  const ELEMENT_NODE = 1;

  class SVGWrapper extends React.Component {
    static propTypes = {
      url: React.PropTypes.string.isRequired,
      fillColor: React.PropTypes.string
    }

    componentDidMount () {
      this.fetchSVG();
    }

    componentWillReceiveProps (newProps) {
      if (newProps.url !== this.props.url) {
        this.fetchSVG();
      }
    }

    fetchSVG () {
      $.ajax(this.props.url, {
        success: function (data) {
          this.svg = data;

          if (data.nodeType === DOCUMENT_NODE) {
            this.svg = data.firstChild;
          }

          if (this.svg.nodeType !== ELEMENT_NODE && this.svg.nodeName !== 'SVG') {
            throw new Error(`SVGWrapper: SVG Element must be returned by request to ${this.props.url}`);
          }

          if (this.props.fillColor) {
            this.svg.setAttribute('style', `fill:${this.props.fillColor}`);
          }

          this.svg.setAttribute('focusable', false);
          this.rootSpan.appendChild(this.svg);
        }.bind(this)
      });
    }

    render () {
      return <span ref={(c) => { this.rootSpan = c; }} />;
    }
  }

  return SVGWrapper;
});

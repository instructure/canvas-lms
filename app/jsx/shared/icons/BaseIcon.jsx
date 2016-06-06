 define([
  'react',
  'react-dom',
  'underscore'
], function(React, ReactDOM, _) {
  var BaseIcon = React.createClass({
    propTypes: {
      name: React.PropTypes.string.isRequired,
      content: React.PropTypes.string.isRequired,
      viewBox: React.PropTypes.string.isRequired,
      title: React.PropTypes.string,
      desc: React.PropTypes.string,
      width: React.PropTypes.string,
      height: React.PropTypes.string
    },

    componentWillMount () {
      this.titleId = _.uniqueId('iconTitle_');
      this.descId = _.uniqueId('iconDesc_');
    },

    componentDidMount () {
      ReactDOM.findDOMNode(this).setAttribute('focusable', 'false')
    },

    getDefaultProps () {
      return {
        width: '1em',
        height: '1em'
      }
    },

    getRole () {
      if (this.props.title) {
        return 'img'
      } else {
        return 'presentation'
      }
    },

    renderTitle () {
      const { title } = this.props
      return (title) ? (
        <title id={this.titleId}>{title}</title>
      ) : null
    },

    renderDesc () {
      const { desc } = this.props
      return (desc) ? (
        <desc id={this.descId}>{desc}</desc>
      ) : null
    },

    getLabelledBy () {
      const ids = []

      if (this.props.title) {
        ids.push(this.titleId)
      }

      if (this.props.desc) {
        ids.push(this.descId)
      }

      return (ids.length > 0) ? ids.join(' ') : null
    },

    render () {
      const {
        title,
        width,
        height,
        viewBox,
        className
      } = this.props
      const style = {
        fill: 'currentColor'
      }
      return (
        <svg
          style={style}
          width={width}
          height={height}
          viewBox={viewBox}
          aria-hidden={title ? null : 'true'}
          aria-labelledby={this.getLabelledBy()}
          role={this.getRole()}>
          {this.renderTitle()}
          {this.renderDesc()}
          <g role="presentation" dangerouslySetInnerHTML={{__html: this.props.content}} />
        </svg>
      )
    }
  });

  return BaseIcon;
});

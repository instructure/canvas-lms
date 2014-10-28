/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var classSet = require('../util/class_set');
  var $ = require('canvas_packages/jquery');

  // TODO: use $.fn.is(':in_viewport') when it becomes available
  var isInViewport = function(el) {
    var $el = $(el)
    var $window = $(window);

    var vpTop    = $window.scrollTop();
    var vpBottom = vpTop + $window.height();
    var elTop    = $el.offset().top;
    var elBottom = elTop + $el.height();

    return vpTop < elTop && vpBottom > elBottom;
  };

  /**
   * @class Components.Alert
   *
   * A Bootstrap alert-like component.
   */
  var Alert = React.createClass({
    propTypes: {
      /**
       * @cfg {Boolean} [autoFocus=false]
       *
       * If true, the alert will auto-focus itself IF it is visible within
       * the viewport (e.g, the user can currently see it.).
       *
       * This is useful to force ScreenReaders to read the notification.
       */
      autoFocus: React.PropTypes.bool
    },

    getDefaultProps: function() {
      return {
        type: 'danger',
        autoFocus: false
      };
    },

    componentDidMount: function() {
      if (this.props.autoFocus) {
        var myself = this.getDOMNode();

        if (isInViewport(myself)) {
          setTimeout(function() {
            myself.focus();
          }, 1);
        }
      }
    },

    render: function() {
      var className = {};

      className['alert'] = true;
      className['alert-' + this.props.type] = true;

      return(
        <div
          tabIndex="-1"
          aria-role="alert"
          aria-live="assertive"
          aria-relevant="all"
          onClick={this.props.onClick}
          className={classSet(className)}
          children={this.props.children} />
      );
    }
  });

  return Alert;
});
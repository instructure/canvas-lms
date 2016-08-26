define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var d3 = require('d3');
  var $ = require('canvas_packages/jquery');
  var jQuery_qTip = require('qtip');

  var makeInspectable = function(selector, view) {
    selector
      .on('mouseover', view.inspect)
      .on('mouseout', view.stopInspecting);
  };

  var DEFAULT_TOOLTIP_OPTIONS = {
    position: {
      my: 'center bottom',
      at: 'center top'
    }
  };

  var ChartMixin = {
    makeInspectable: makeInspectable,

    defaults: {
    },

    mixin: {
      propTypes: {
        /**
         * @property {Function} onInspect
         * A function that will be called with a given datapoint's ID and should
         * yield content to show inside the tooltip.
         *
         * The mixin becomes a no-op if this function does not return a valid
         * HTMLElement node.
         */
        onInspect: React.PropTypes.func
      },

      getDefaultProps: function() {
        return {
          onInspect: null
        };
      },

      buildInspector: function() {
        var node = this.refs.inspector.getDOMNode();

        this.inspectorNode = node;
        this.inspector = $(node).qtip({
          prerender: false,
          overwrite: false,
          style: {
            def: true
          },
          show: {
            effect: false,
            event: false
          },
          hide: {
            effect: false,
            event: false
          },
          content: {
            text: ''
          },
          position: {
            my: 'bottom center',
            at: 'top center',
            viewport: true,
            adjust: {
              method: 'flip'
            }
          }
        }).qtip('api');

        return this.inspector;
      },

      inspect: function(datapoint) {
        var inspector, contentNode;
        var itemId = datapoint.id;
        var tooltipOptions = this.tooltipOptions || DEFAULT_TOOLTIP_OPTIONS;
        var targetNode = d3.event.target;

        if (this.props.onInspect) {
          contentNode = this.props.onInspect(itemId, datapoint);
        }

        if (!contentNode) {
          return;
        }

        inspector = this.inspector || this.buildInspector();
        inspector.set('content.text', $(contentNode).clone());
        inspector.set('position.target', targetNode);
        inspector.show();
      },

      stopInspecting: function() {
        this.inspector.hide();
      }
    }
  };

  return ChartMixin;
});
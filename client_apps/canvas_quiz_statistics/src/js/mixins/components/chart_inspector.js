define(function(require) {
  var React = require('react');
  var d3 = require('d3');
  var $ = require('canvas_packages/jquery');
  var Tooltip = require('canvas_packages/tooltip');

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
        this.inspector = $(node).tooltip({
          tooltipClass: 'center bottom vertical',
          show: false,
          hide: false,
          items: $(node)
        }).data('tooltip');

        return this.inspector;
      },

      inspect: function(datapoint) {
        var inspector, contentNode;
        var itemId = datapoint.id;
        var tooltipOptions = this.tooltipOptions || DEFAULT_TOOLTIP_OPTIONS;

        if (this.props.onInspect) {
          contentNode = this.props.onInspect(itemId);
        }

        if (!contentNode) {
          return;
        }

        inspector = this.inspector || this.buildInspector();
        inspector.option({
          content: function() {
            return $(contentNode).clone();
          },
          position: {
            my: tooltipOptions.position.my,
            at: tooltipOptions.position.at,
            of: d3.event.target,
            collision: 'fit fit'
          }
        });

        inspector.element.mouseover();
      },

      stopInspecting: function() {
        this.inspector.element.mouseout();
      }
    }
  };

  return ChartMixin;
});
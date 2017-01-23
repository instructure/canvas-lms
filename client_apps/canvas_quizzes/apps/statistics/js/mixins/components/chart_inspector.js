define((require) => {
  const React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  const d3 = require('d3');
  const $ = require('canvas_packages/jquery');
  const jQuery_qTip = require('qtip');

  const makeInspectable = function (selector, view) {
    selector
      .on('mouseover', view.inspect)
      .on('mouseout', view.stopInspecting);
  };

  const DEFAULT_TOOLTIP_OPTIONS = {
    position: {
      my: 'center bottom',
      at: 'center top'
    }
  };

  const ChartMixin = {
    makeInspectable,

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

      getDefaultProps () {
        return {
          onInspect: null
        };
      },

      buildInspector () {
        const node = this.refs.inspector.getDOMNode();

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

      inspect (datapoint) {
        let inspector,
          contentNode;
        const itemId = datapoint.id;
        const tooltipOptions = this.tooltipOptions || DEFAULT_TOOLTIP_OPTIONS;
        const targetNode = d3.event.target;

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

      stopInspecting () {
        this.inspector.hide();
      }
    }
  };

  return ChartMixin;
});

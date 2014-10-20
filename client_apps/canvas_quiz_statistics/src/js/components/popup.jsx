/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var $ = require('canvas_packages/jquery');
  var _ = require('lodash');
  var jQuery_qTip = require('qtip');
  var ScreenReaderContent = require('jsx!./screen_reader_content');

  var omit = _.omit;
  var merge = _.extend;
  var POPUP_PROPS = Object.freeze([
    'content',
    'popupOptions',
    'anchorSelector',
    'children',
    'ref',
    'autoFocus',
    'reactivePositioning',
    'onShow',
    'onHide'
  ]);

  /**
   * @class Components.Popup
   *
   * Wrap a React view inside a qTip popup. The pop-up is bound to an "anchor"
   * element, like a button or an anchor, that controls when and how to show and
   * close the pop-up.
   *
   * You can pass props to the content *inside* the popup regularly as if you
   * were mounting the component directly, except for some reserved props
   * that are needed for the popup to function correctly. See the configuration
   * docs for those props.
   *
   * === Example usage
   *
   *     // Direct instantiation:
   *     React.renderComponent(Popup({
   *       content: React.DOM.div({}, "I'm a popup content!")
   *     }), document.body);
   *
   *     // Inside a view's render method:
   *     <Popup content={MyPopupContent} />
   *
   *     // Pass a property to the content:
   *     <Popup content={MyPopupContent} name="Ahmad" />
   *
   *     // Customize qTip options:
   *     var options = {
   *       position: {
   *         // ...
   *       }
   *     };
   *     <Popup popupOptions={options} ... />
   *
   * === Accessibility
   *
   * The popup is an accessible component by default. Content shown inside the
   * popup will be presented to Screen Reader ATs. Also, it is keyboard-friendly
   * and is reachable using TAB.
   *
   * The popup's API exposes a few controls that allow you to further optimize
   * the screen-reading experience if your content is dynamic. See the focusing
   * methods for more info.
   *
   * === Additional resources
   *
   *   - See http://qtip2.com/options for customizing the popup
   *   - See http://qtip2.com/api for the lower API, if you need to interact
   *     with this, use the Popup.__getApi() method to get the instance
   */
  var Popup = React.createClass({
    mixins: [],

    propTypes: {
      /**
       * @cfg {React.Class} content (required)
       *
       * The Popup's content you want to render.
       */
      content: React.PropTypes.func.isRequired,

      /**
       * @cfg {React.Component} [children=<button>Show Popup</button>]
       *
       * Element to use as the popup's "toggle" button, which when clicked will
       * show the qTip.
       */
      children: React.PropTypes.renderable,

      /**
       * @cfg {Object} [popupOptions={}]
       *
       * qTip options.
       */
      popupOptions: React.PropTypes.object,

      /**
       * @cfg {String} [anchorSelector=".popup-anchor"]
       *
       * CSS selector to locate a child element to use as the popup's "anchor",
       * e.g, the positioning will be relative to that element instead of the
       * entirety of the popup's children.
       *
       * When unset, or the element could not be found, it defaults to using
       * the popup's children as anchor.
       */
      anchorSelector: React.PropTypes.string,

      /**
       * @cfg {Boolean} [reactivePositioning=false]
       *
       * When true, the pop-up will reposition itself after every update to its
       * content. Enable this if the content is dynamic.
       */
      reactivePositioning: React.PropTypes.bool,

      /**
       * Callback triggered when the pop-up has been opened. Use this hook to
       * install any keybindings, or focus some node.
       *
       * @param {HTMLElement} contentNode
       *        The element that contains the rendered content component.
       *
       * @param {QTip} qtip
       *        The qTip API instance for this popup.
       */
      onShow: React.PropTypes.func,

      /**
       * Callback triggered when the pop-up has been closed.
       */
      onHide: React.PropTypes.func,
    },

    getInitialState: function() {
      return {
        /**
         * @property {HTMLElement} container
         *
         * An auto-generated element that will contain the popup's content. The
         * container is classed with "popup-content" to achieve the necessary
         * Popup styling.
         *
         * This is the DOM node at which the content component will be mounted
         * at.
         */
        container: null,

        /**
         * @property {React.Component} content
         *
         * The rendered popup content component.
         */
        content: null
      };
    },

    getDefaultProps: function() {
      return {
        children: <button>Show Popup</button>,
        popupOptions: {},
        anchorSelector: '.popup-anchor',
        reactivePositioning: false,
        screenReaderSupport: true
      };
    },

    componentDidMount: function() {
      var $this = $(this.getDOMNode());
      var $container = $('<div class="popup-content" />');
      var options;

      if (!this.props.content) {
        throw new Error("You must provide a 'content' component for a popup!");
      }

      options = this.qTipOptions($this, $container);
      this.qTip = $this.qtip(options).qtip('api');
      this.__disableInherentAccessibilityLayer(this.qTip);

      this.setState({
        container: $container[0],
        content: React.renderComponent(
          this.props.content(this.getContentProps(this.props)),
          $container[0]
        )
      });
    },

    componentWillUnmount: function() {
      React.unmountComponentAtNode(this.state.container);

      if (this.qTip) {
        this.qTip.destroy(true);
      }
    },

    /**
     * @private
     *
     * Update the content with the new properties.
     */
    componentDidUpdate: function() {
      var content = this.state.content;

      if (content) {
        content.setProps(this.getContentProps(this.props), this.contentDidUpdate);
      }
    },

    contentDidUpdate: function() {
      this.reposition();

      if (this.focusScreenReaderContentOnUpdate) {
        this.focusScreenReaderContentOnUpdate = false;
        this.focusScreenReaderContent();
      }
    },

    render: function() {
      return (
        <div tabIndex="-1" className="inline">
          {this.props.children}
          {this.props.screenReaderSupport &&
            <ScreenReaderContent
              ref="srContent"
              tabIndex="0"
              aria-live="assertive"
              aria-atomic="true"
              aria-relevant="additions"
              role="note"
              children={this.props.content(this.getContentProps(this.props))} />
          }
        </div>
      );
    },

    /**
     * @internal
     *
     * qTip by default defines a few aria-* attributes on its popup element
     * which makes some SRs read the content twice since we're doing things
     * manually. Calling this method on a qtip api instance will disable
     * remove these attributes and "make things work".
     */
    __disableInherentAccessibilityLayer: function(qtip) {
      qtip.tooltip
        .removeAttr('role')
        .removeAttr('aria-live')
        .removeAttr('aria-atomic')
        .removeAttr('aria-describedby');
    },

    getContentProps: function(props) {
      return omit(props, POPUP_PROPS);
    },

    getAnchor: function() {
      var $this = $(this.getDOMNode());
      var $anchor = $this.find(this.props.anchorSelector);

      if (!$anchor.length) {
        console.warn(
          'Popup anchor was not found, defaulting to $(this).',
          'Selector: %s', this.props.anchorSelector
        );
        $anchor = $this;
      }

      return $anchor;
    },

    /**
     * Common qTip popup options.
     *
     * @param {jQuery[]} $buttons
     * Button(s) (or any element really) that will show and hide the popup.
     *
     * @param {jQuery} $content
     * The content (or content element) of the popup.
     */
    qTipOptions: function($buttons, $content) {
      var options = merge({}, {
        overwrite: false,
        prerender: true,
        show: {
          event: 'click focusin',
          delay: 0,
          target: $buttons,
          effect: false,
          solo: false
        },

        hide: {
          event: 'click focusout',
          effect: false,
          fixed: true,
          target: $buttons
        },

        style: {
          classes: 'qtip-default',
          def: false,
          tip: {
            width: 10,
            height: 5
          }
        },

        position: {
          my: 'right center',
          at: 'left center',
          target: false,
          adjust: {
            x: 0,
            y: 0
          }
        },

        content: {
          text: $content
        },

        events: {
          show: this.__onShow,
          hide: this.__onHide
        }
      }, this.props.popupOptions);

      // Default targets are the popup anchor
      if (!options.show.target) {
        options.show.target = $buttons;
      }

      if (!options.hide.target) {
        options.hide.target = $buttons;
      }

      return options;
    },

    isOpen: function() {
      return !!this.qTip.shown;
    },

    // You don't have to call this manually if you set the #reactivePositioning
    // flag on.
    reposition: function() {
      var qTip = this.qTip;

      if (qTip && !!this.props.reactivePositioning) {
        qTip.reposition();
      }
    },

    /**
     * Focus the node that contains the content to be presented to Screen
     * Readers. You should call this everytime you modify the content and want
     * the SR to read the updated version.
     */
    focusScreenReaderContent: function(queue) {
      if (queue === true) {
        this.focusScreenReaderContentOnUpdate = true;
        return;
      }

      this.getDOMNode().focus();
      this.refs.srContent.getDOMNode().focus();
    },

    screenReaderContentHasFocus: function() {
      return document.activeElement === this.refs.srContent.getDOMNode();
    },

    /** Set the focus on the anchor element that controls the pop-up. */
    focusAnchor: function() {
      this.getDOMNode().focus();
      this.getAnchor()[0].focus();
    },

    /**
     * Close the tooltip and restore focus to the anchor.
     */
    close: function() {
      if (this.qTip.shown) {
        this.qTip.hide();
        this.getAnchor().focus();
      }
    },

    __onShow: function(event, api) {
      api.shown = true;

      if (this.props.onShow) {
        this.props.onShow(this.state.container, api);
      }
    },

    __onHide: function(event, api) {
      api.shown = false;

      if (this.props.onHide) {
        this.props.onHide();
      }
    },

    __getApi: function() {
      return this.qTip;
    }
  });

  return Popup;
});
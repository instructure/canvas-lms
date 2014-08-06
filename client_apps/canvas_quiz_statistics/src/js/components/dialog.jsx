/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var jQueryUIDialog = require('canvas_packages/jqueryui/dialog');
  var $ = require('canvas_packages/jquery');
  var _ = require('lodash');
  var omit = _.omit;

  /**
   * @class Components.Dialog
   *
   * Wrap a component inside a jQueryUI Dialog and keep it updated like you
   * would any other component. The wrapped component is refered to as the
   * "content", while the wrapper component which you interact with is refered
   * to as the "Dialog".
   *
   * All the props you pass to this component are passed through as-is to the
   * dialog content, except for a number of props that control the dialog's
   * toggle button. See #propTypes for more info.
   *
   * TODO: a11y
   *
   * === Usage example
   *
   * Let's say you have a view called Help that has some helpful information
   * and you would like to display this view inside a dialog. You also want
   * to bind a button to show this dialog, with a label that says "Help".
   *
   *     define(function(require) {
   *       var Dialog = require('jsx!components/dialog');
   *       var HelpView = require('jsx!./help');
   *
   *       var View = React.createClass({
   *         render: function() {
   *           return (
   *             <div>
   *               <Dialog
   *                 content={HelpView}
   *                 tagName="button"
   *                 className="btn btn-success">
   *                 Help
   *               </Dialog>
   *             </div>
   *           );
   *         }
   *       });
   *
   *       return View;
   *     });
   */
  var Dialog = React.createClass({
    propTypes: {
      /**
       * @property {React.Component} content
       *
       * A type of component that should be rendered *inside* the $.dialog().
       *
       * The Dialog component will take care of mounting an instance of this
       * type inside the $.dialog() and keeping it updated with the props you
       * pass through.
       */
      content: React.PropTypes.func,

      /**
       * @property {React.Component} children
       *
       * Whatever you pass as children to this component will act as a toggle
       * button for the dialog. Clicking it will show or hide the dialog based
       * on its state.
       *
       * You can choose to pass nothing for this, then you will have to manually
       * control the toggling of the dialog by assigning a ref and using the
       * exposed API. Example:
       *
       *     render: function() {
       *       return (
       *         <div onClick={this.toggleDialog}>
       *           <Dialog content={MyContent} ref="dialog" />
       *         </div>
       *       )
       *     },
       *
       *     toggleDialog: function() {
       *       if (this.refs.dialog.isOpen()) {
       *         this.refs.dialog.close();
       *       } else {
       *         this.refs.dialog.open();
       *       }
       *     }
       */
      children: React.PropTypes.renderable,

      /**
       * @property {String} [tagName="div"]
       * You can customize the tag that is used as the dialog toggle element.
       */
      tagName: React.PropTypes.string,

      /**
       * @property {String} [className=""]
       * CSS classes to add to the dialog toggle element.
       */
      className: React.PropTypes.string
    },

    getInitialState: function() {
      return {
        content: null,
        container: null,
        $container: null
      };
    },

    getDefaultProps: function() {
      return {
        children: [],
        autoOpen: false,
        tagName: 'div'
      };
    },

    componentDidUpdate: function(/*prevProps, prevState*/) {
      var props = this.props;

      // Create the dialog if it hasn't been created yet:
      if (!this.state.content && props.content) {
        this.__renderDialog(props.content, props);
      }

      // Update the component within the dialog:
      if (this.state.content) {
        this.state.content.setProps(this.__getContentProps(props));
      }
    },

    componentWillUnmount: function() {
      this.__removeDialog();
    },

    render: function() {
      var tag = React.DOM[this.props.tagName];

      return (
        <tag
          onClick={this.toggle}
          className={this.props.className}
          children={this.props.children} />
      );
    },

    /** Open the dialog */
    open: function() {
      this.__send('open');
    },

    /** Close the dialog */
    close: function() {
      this.__send('close');
    },

    /** Is the dialog open? */
    isOpen: function() {
      return this.__send('isOpen');
    },

    toggle: function() {
      if (this.isOpen()) {
        this.close();
      } else {
        this.open();
      }
    },

    /**
     * @internal
     */
    __renderDialog: function(content, props) {
      var container = document.createElement('div');
      var renderedContent = React.renderComponent(content(), container);

      $(container).dialog({
        autoOpen: props.autoOpen
      });

      this.setState({
        content: renderedContent,
        container: container,
        $container: $(container)
      });
    },

    __removeDialog: function() {
      if (this.state.$container) {
        // No need to remove the container as it was not really attached to
        // the DOM, simply unmounting the component will suffice.
        React.unmountComponentAtNode(this.state.container);

        this.state.$container.dialog('destroy');
      }
    },

    /**
     * @internal Send an API command to the jQueryUI Dialog instance.
     *
     * @param  {String} command
     *         jQueryUI Dialog API message.
     *
     * @return {Mixed}
     *         Whatever the dialog API returns, if a dialog actually exists.
     */
    __send: function(command) {
      if (this.state.$container) {
        return this.state.$container.dialog(command);
      }
    },

    __getContentProps: function(props) {
      return omit(props, [ 'className', 'tagName', 'content', 'children' ]);
    }
  });

  return Dialog;
});
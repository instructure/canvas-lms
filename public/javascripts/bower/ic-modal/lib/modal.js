// http://www.w3.org/TR/wai-aria-practices/#dialog_modal

import Ember from 'ember';

var alias = Ember.computed.alias;

/**
 * If you do something to move focus outside of the browser (like
 * command+l to go to the address bar) and then tab back into the
 * window, capture it and focus the first tabbable element in an active
 * modal.
 */

var lastOpenedModal = null;

Ember.$(document).on('focusin', handleTabIntoBrowser);

function handleTabIntoBrowser(event) {
  if (!lastOpenedModal) return;
  lastOpenedModal.focus();
}

/**
 * Accessible modal dialog component.
 *
 * @class Modal
 * @event willOpen
 * @event didOpen
 * @event willClose
 */

export default Ember.Component.extend({

  tagName: 'ic-modal',

  attributeBindings: [
    'after-open',
    'aria-hidden',
    'aria-labelledby',
    'is-open',
    'role',
    'tabindex'
  ],

  /**
   * Allows for css transitions, the class is added after the dialog is
   * set to display: block. For example, to create a fade in effect:
   *
   * ```css
   * ic-dialog[is-open] {
   *   opacity: 0;
   *   transition: opacity 150ms ease;
   * }
   *
   * ic-dialog[after-open] {
   *   opacity: 1;
   * }
   * ```
   *
   * @property after-open
   * @private
   */

  'after-open': null,

  /**
   * It is counter-intuitive to have a tabindex of 0 since we don't want
   * the modal to actually be tabbable. However, were it not tabbable
   * and you click inside of it, the document gets focus and ruins all of
   * our tab navigation scoping. Now that it will keep focus, tabbing
   * after a click will work as expected. It's not actually tabbable,
   * however, since the modal is display:none when closed, and we hijack
   * tabs on the last and first tabbable elements when open.
   *
   * @property tabindex
   * @private
   */

  tabindex: 0,

  /**
   * Tells the screenreader not to read this when closed.
   *
   * @property aria-hidden
   * @private
   */

  'aria-hidden': function() {
    // coerce to string cause that's how the screenreaders like it
    return !this.get('isOpen')+'';
  }.property('isOpen'),

  /**
   * When the dialog opens the screenreader will get the label from the
   * title component
   *
   * @property aria-labelledby
   * @private
   */

  'aria-labelledby': alias('titleComponent.elementId'),

  /**
   * Used as a bound attribute so you can style modals with
   * `ic-modal[is-open] {}`.
   *
   * @property is-open
   * @private
   */

  'is-open': function() {
    return this.get('isOpen') ? 'true' : null;
  }.property('isOpen'),

  /**
   * Tells the screenreader to treat this element as a dialog.
   *
   * @property role
   * @private
   */

  role: 'dialog',

  /**
   * @property isOpen
   * @private
   */

  isOpen: false,

  /**
   * Opens the modal. Takes one option `{focus: false}`, which defaults
   * to false. If false it won't try to focus the dialog after it opens,
   * this is used when the modal is opened by a mouse click.
   *
   * @method open
   * @public
   */

  open: function(options) {
    options = options || {};
    this.trigger('willOpen');
    this.sendAction('on-open', this);
    this.set('isOpen', true);
    lastOpenedModal = this;
    Ember.run.schedule('afterRender', this, function() {
      this.maybeMakeDefaultChildren();
      this.set('after-open', 'true');
      this.trigger('didOpen');
      if (options.focus !== false) {
        // after render because we want the the default close button to get focus
        Ember.run.schedule('afterRender', this, 'focus');
      } else {
        // when options.focus is false it means we used the mouse, and designers hate
        // focus styles showing up, so lets not do that. Instead, focus the whole thing
        // so that tab will work next time.
        this.$().focus();
      }
    });
  },

  /**
   * Closes the dialog and also focuses the trigger that opened it in
   * the first place so the user's tab position is preserved with fierce
   * integrity.
   *
   * @method close
   * @public
   */

  close: function() {
    this.trigger('willClose');
    this.sendAction('on-close', this);
    this.set('isOpen', false);
    this.set('after-open', null);
    lastOpenedModal = null;
    var toggler = this.get('toggler');
    toggler && toggler.focus();
  },

  /**
   * We need to focus an element so that keyboard and screenreader users end up
   * in the right place after the dialog is opened (or when the users tabs back
   * into the browser window from the browser chrome).
   *
   * @method focus
   * @private
   */

  focus: function() {
    if (this.get('element').contains(document.activeElement)) {
      // just let it be if we already contain the activeElement
      return;
    }
    var target = this.$('[autofocus]');
    if (!target.length) target = this.$(':tabbable');
    // maybe they destroyed the close button? this shoudn't happen but could
    if (!target.length) target = this.$();
    target[0].focus();
  },

  /**
   * Shows or hides the modal, depending on current state.
   *
   * @method toggleVisibility
   * @param toggler ToggleComponent
   * @param options Object
   * @public
   */

  toggleVisibility: function(toggler, options) {
    if (this.get('isOpen')) {
      this.close();
      this.set('toggler', null);
    } else {
      this.open(options);
      if (toggler) {
        this.set('toggler', toggler);
      }
    }
  },

  /**
   * @method handleKeyDown
   * @private
   */

  handleKeyDown: function(event) {
    if (event.keyCode == 9 /*tab*/) this.keepTabNavInside(event);
    if (event.keyCode == 27 /*esc*/) this.close();
  }.on('keyDown'),

  /**
   * When the dialog is open, we want to keep all tab navigation scoped
   * to the dialog since the point of a modal is to temporarily branch
   * the current user workflow. Tabbing on the last or first tabbable
   * elements will loop back around the other.
   *
   * @method keepTabNavInside
   * @private
   */

  keepTabNavInside: function(event) {
    if (event.keyCode !== 9) return;
    var tabbable = this.$(':tabbable');
    var finalTabbable = tabbable[event.shiftKey ? 'first' : 'last']()[0];
    var leavingFinalTabbable = (
      finalTabbable === document.activeElement ||
      // handle immediate shift+tab after opening with mouse
      this.get('element') === document.activeElement
    );
    if (!leavingFinalTabbable) return;
    event.preventDefault();
    tabbable[event.shiftKey ? 'last' : 'first']()[0].focus();
  },

  /**
   * Clicking outside the dialog should close it. We don't need to
   * handle other forms of losing focus (like keyboard nav) because we
   * already handle all of the keyboard navigation when its open.
   *
   * @method closeOnClick
   * @private
   */

  closeOnClick: function(event) {
    if (event.target !== this.get('element')) return;
    this.close();
  }.on('click'),

  /**
   * Often you need a mechanism besides an ic-modal-toggle to close an
   * open dialog; when you have a dialog with a form, you want to close
   * the dialog when the form has been submitted. You can bind to this
   * attribute and set it to true, causing the dialog to close.
   *
   * ```html
   * {{#ic-modal close-when=formIsSubmitted}}
   *   <form {{action "submitForm" on="submit"}}>
   *     <button type="submit">submit</button>
   *   </form>
   * {{/ic-modal}}
   * ```
   *
   * ```js
   * App.ApplicationController = Ember.Controller.extend({
   *   actions: {
   *     submitForm: function() {
   *       // do some work
   *       this.set('formIsSubmitted', true); // dialog closes
   *     }
   *   }
   * });
   * ```
   *
   * @property close-when
   * @public
   */

  'close-when': false,

  /**
   * Facilitates 'close-when' behavior.
   *
   * @method closeWhen
   * @private
   */

  closeWhen: function() {
    if (!this.get('close-when')) return;
    this.close();
    this.set('close-when', false);
  }.observes('close-when'),

  /**
   * Often you need a mechanism besides an ic-modal-toggle to open a dialog,
   * like to start a new feature tour. You can bind to this attribute and set
   * it to true, causing the dialog to open.
   *
   * ```html
   * {{#ic-modal open-when=starTour}}
   *   Ohai
   * {{/ic-modal}}
   * ```
   *
   * ```js
   * App.ApplicationController = Ember.Controller.extend({
   *   checkTour: function() {
   *     if (ENV.NEEDS_TOUR) this.set('startTour', true);
   *   }.on('init')
   * });
   * ```
   *
   * @property close-when
   * @public
   */

  'open-when': false,

  /**
   * Facilitates 'open-when' behavior.
   *
   * @method openWhen
   * @private
   */

  openWhen: function() {
    if (!this.get('open-when')) return;
    this.open();
    this.set('open-when', false);
  }.observes('open-when'),

  /**
   * All Dialogs need a title for the screenreader (and the UI, usually
   * anyway) and a close button. If a modal does not have an
   * `ic-modal-title` or an `ic-modal-toggle` then this will create some
   * defaults.
   *
   * @method maybeMakeDefaultChildren
   * @private
   */

  maybeMakeDefaultChildren: function() {
    if (!this.get('titleComponent')) this.set('makeTitle', true);
    if (!this.get('triggerComponent')) this.set('makeTrigger', true);
  },

  /**
   * @method registerTitle
   * @private
   */

  registerTitle: function(component) {
    this.set('titleComponent', component);
  },

  /**
   * @method registerTrigger
   * @private
   */

  registerTrigger: function(component) {
    this.set('triggerComponent', component);
  }

});


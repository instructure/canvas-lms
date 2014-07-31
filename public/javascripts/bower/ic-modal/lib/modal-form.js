import ModalComponent from './modal';


/**
 * Modal dialog designed specifically for submitting forms.
 *
 * @event on-submit - sent when the form has been submit
 *   @param modal ModalFormComponent - the modal form being submitted
 *   @param event Event - the DOM event. If you set `event.returnValue` to a
 *     promise then the modal's `awaiting-return-value` will be true, and the
 *     modal will not close until the promise resolves.
 * @event on-cancel - sent when the modal was closed but the form was not submitted.
 * @class ModalFormComponent
 * @extends ModalComponent
 */

export default ModalComponent.extend({

  /**
   * Can't use a custom element because we need all the goodness that browser
   * pack into forms.
   *
   * @property tagName
   * @private
   */

  tagName: 'form',

  /**
   * Because we can't use a custom tagName, we add a className for styling.
   *
   * @property classNames
   * @public
   */

  classNames: ['ic-modal-form'],

  attributeBindings: ['awaiting-return-value'],

  /**
   * Will be true when a dialog's returnValue is a promise. You can style your
   * modal with `[awaiting-return-value] {}`, or branch in your template like so:
   *
   * ```html
   * {{#ic-modal-form awaiting-return-value=saving}}
   *   {{#ic-modal-content}}
   *     {{#if saving}}
   *       Saving...
 *       {{else}}
 *         <button type="submit">Save</button>
 *       {{/if}}
   *   {{/ic-modal-content}}
   * {{/ic-modal-form}}
   * ```
   *
   * @property awaiting-return-value
   * @private
   */

  'awaiting-return-value': null,

  /**
   * Provides a way to send the 'on-cancel' action, see `close`.
   *
   * @property didSubmit Boolean
   * @private
   */

  didSubmit: false,

  /**
   * Closes the dialog after submit. If the `event.returnValue` is a promise,
   * it will wait for the promise to resolve.
   *
   * @method handleSubmit
   * @private
   */

  handleSubmit: function(event) {
    event.preventDefault();
    this.set('didSubmit', true);
    // loses focus on submit, this might be better solved in ModalComponent but
    // I don't understand the issue well enough
    Ember.run.later(this.$(), 'focus', 0);
    this.sendAction('on-submit', this, event);
    if (event.returnValue && 'function' == typeof event.returnValue.then) {
      this.set('awaiting-return-value', 'true');
      event.returnValue.then(function() {
        this.set('awaiting-return-value', null);
        this.close();
      }.bind(this), function() {
        this.set('awaiting-return-value', null);
      }.bind(this));
    } else {
      this.close();
    }
  }.on('submit'),

  close: function() {
    if (this.get('awaiting-return-value')) {
      return this.sendAction('on-invalid-close', this);
    }
    if (!this.get('didSubmit')) {
      this.sendAction('on-cancel', this);
    }
    this.set('didSubmit', false);
    return this._super.apply(this, arguments);
  }

});


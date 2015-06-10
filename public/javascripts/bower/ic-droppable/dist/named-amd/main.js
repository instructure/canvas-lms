define("ic-droppable",
  ["ember","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    var Ember = __dependency1__["default"] || __dependency1__;

    /**
     * Wraps the native drop events to make your components droppable.
     *
     * @mixin Droppable
     */

    var Droppable = Ember.Mixin.create({

      classNameBindings: [
        'accepts-drag',
        'self-drop'
      ],

      /**
       * Read-only className property that is set to true when the component is
       * receiving a valid drag event. You can style your element with
       * `.accepts-drag`.
       *
       * @property accepts-drag
       * @private
       */

      'accepts-drag': false,

      /**
       * Will be true when the component is dragged over itself. Can use
       * `.self-drop` in your css to style (or more common, unstyle) the component.
       *
       * @property self-drop
       * @private
       */

      'self-drop': false,

     /**
       * Validates drag events. Override this to restrict which data types your
       * component accepts.
       *
       * Example:
       *
       * ```js
       * validateDragEvent: function(event) {
       *   return event.dataTransfer.types.contains('text/x-foo');
       * }
       * ```
       *
       * @method validateDragEvent
       * @public
       */

      validateDragEvent: function(event) {
        return true;
      },

      /**
       * Called when a valid drag event is dropped on the component. Override to
       * actually make something happen.
       *
       * ```js
       * acceptDrop: function(event) {
       *   var data = event.dataTransfer.getData('text/plain');
       *   doSomethingWith(data);
       * }
       * ```
       *
       * @method acceptDrop
       * @public
       */

      acceptDrop: Ember.K,

      /**
       * @method _handleDragOver
       * @private
       */

      _handleDragOver: function(event) {
        if (this._droppableIsDraggable(event)) {
          this.set('self-drop', true);
        }
        if (this.get('accepts-drag')) {
          return this._allowDrop(event);
        }
        if (this.validateDragEvent(event)) {
          this.set('accepts-drag', true);
          this._allowDrop(event);
        } else {
          this._resetDroppability();
        }
      }.on('dragOver'),

      /**
       * @method _handleDrop
       * @private
       */

      _handleDrop: function(event) {
        // have to validate on drop because you may have nested sortables the
        // parent allows the drop but the child receives it, revalidating allows
        // the event to bubble up to the parent to handle it
        if (!this.validateDragEvent(event)) {
          return;
        }
        this.acceptDrop(event);
        this._resetDroppability();
        // TODO: might not need this? I can't remember why its here
        event.stopPropagation();
        return false;
      }.on('drop'),

      /**
       * Tells the browser we have an acceptable drag event.
       *
       * @method _allowDrop
       * @private
       */

      _allowDrop: function(event) {
        event.stopPropagation();
        event.preventDefault();
        return false;
      },

      /**
       * We want to be able to know if the current drop target is the original
       * element being dragged or a child of it.
       *
       * @method _droppableIsDraggable
       * @private
       */

      _droppableIsDraggable: function(event) {
        return Droppable._currentDrag && (
          Droppable._currentDrag === event.target ||
          Droppable._currentDrag.contains(event.target)
        );
      },

      /**
       * @method _resetDroppability
       * @private
       */

      _resetDroppability: function() {
        this.set('accepts-drag', false);
        this.set('self-drop', false);
      }.on('dragLeave')

    });

    // Need to track this so we can determine `self-drop`.
    // It's on `Droppable` so we can test :\
    Droppable._currentDrag = null;
    window.addEventListener('dragstart', function(event) {
      Droppable._currentDrag = event.target;
    }, true);

    __exports__["default"] = Droppable;
  });
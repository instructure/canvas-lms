define("ic-sortable",
  ["ember","ic-droppable","exports"],
  function(__dependency1__, __dependency2__, __exports__) {
    "use strict";
    var Ember = __dependency1__["default"] || __dependency1__;
    var Droppable = __dependency2__["default"] || __dependency2__;

    var currentDropTarget;
    var currentSortableDrag;
    var startedNewDrag = false;

    /**
     * Component/View Mixin to make a view sortable.
     *
     * Actions:
     * 
     * - on-dragstart: sent when the drag starts
     * - on-dragend: sent when the drag ends. This is not guaranteed to run
     *   (see docs for `resetOnDragEnd`). Whatever you do here you should
     *   also do in `acceeptDrop`.
     *
     * @mixin Sortable
     * @public
     */

    var Sortable = Ember.Mixin.create(Droppable, {

      attributeBindings: ['draggable'],

      draggable: 'true',

      classNameBindings: [
        'isDragging',
        'isDropping',
        'dropBelow',
        'dropAbove',
        'firstDropTarget'
      ],

      /**
       * Will be true when this element is being dragged, you can style it
       * with `.is-dragging`, but note that this is the element that remains
       * in the DOM, not the ghost being dragged. The ghost gets its styles
       * from the element's styles before the drag. For more control over
       * the ghost, use `event.dataTransfer.setDragImage()` in
       * `setEventData`.
       *
       * @property isDragging
       * @type Boolean
       * @private
       */
      
      isDragging: false,

      /**
       * Will be true when a valid drag event is over the bottom half of the
       * element. You can style with `.drop-below`. For a common sortable
       * interface, style with `padding-bottom`.
       *
       * @property dropBelow
       * @type Boolean
       * @private
       */

      dropBelow: false,

      /**
       * Will be true when a valid drag event is over the top half of the
       * element. You can style with `.drop-above`. For a common sortable
       * interface, style with `padding-top`.
       *
       * @property dropAbove
       * @type Boolean
       * @private
       */

      dropAbove: false,

      /**
       * Will be true when this element is first of any sortables to be
       * dragged over. You can style with `first-drop-target`.
       *
       * @property firstDropTarget
       * @type Boolean
       * @private
       */

      firstDropTarget: false,

      /**
       * Override this method to set the event data of the drag, change the
       * dragImage, etc.
       *
       * ```js
       * setEventData: function(event) {
       *   event.dataTransfer.setDragImage(someImageElement, 0, 0);
       *   event.dataTransfer.setData('text/x-foo', 'some data');
       * }
       * ```
       *
       * @public
       */

      setEventData: function(event) {
        event.dataTransfer.setData('text/html', this.$().html());
      },

      /**
       * @private
       */

      setDropBelow: function() {
        this.set('dropBelow', true);
        this.set('dropAbove', false);
        this.updateDropTarget();
      },

      /**
       * @private
       */

      setDropAbove: function() {
        this.set('dropAbove', true);
        this.set('dropBelow', false);
        this.updateDropTarget();
      },

      /**
       * Sets the new global currentDropTarget and resets the drop
       * properties of the previous drop target.  We do the reset work here
       * instead of on dragLeave of the old target so that the old and new
       * drop targets have their properties updated on the same tick.  This
       * allows smoother animations (no delay between the previous target
       * and this new one).
       *
       * @method updateDropTarget
       * @private
       */

      updateDropTarget: function() {
        // ensure we aren't dragging something from the desktop/other window
        if (currentDropTarget && currentDropTarget !== this) {
          currentDropTarget.resetDropProps();
        }
        currentDropTarget = this;
      },

      /**
       * UI may want to respond differently for the first drop target than
       * the rest. For example, if the dragged element gets display none,
       * then the element below it will jump up, receive a drop-above above
       * property, and then a CSS transition may happen that looks weird.
       * Having `.first-target` allows the CSS to remove the animation for
       * this case.
       *
       * @method setFirstTarget
       * @private
       */

      setFirstTarget: function() {
        if (!startedNewDrag) return;
        this.set('firstDropTarget', true);
        // in many cases, the dragged element gets set to display none, moving the
        // next sibling down, so lets pre-empt some bad styles and set dropAbove
        // immediately (maybe make this configurable? add a hook for such
        // behavior instead?)
        this.set('dropAbove', true);
        startedNewDrag = false;
        // run later so the css will take effect and allow transitions
        Ember.run.later(this, function() {
          this.set('dropAbove', false);
          this.set('firstDropTarget', false);
        }, 10); // anything < 10 prevents css transitions from happening ¯\(°_o)/¯
      },

      /**
       * Determines the drop properties from the cursor position of the
       * drag.
       *
       * @method setDropPropertiesFromEvent
       * @private
       */

      setDropPropertiesFromEvent: function(event) {
        this.setFirstTarget();
        if (!this.get('accepts-drag')) return;
        var pos = relativeClientPosition(this.$()[0], event.originalEvent);
        if (this.get('dropBelow')) {
          // making assumptions that the css will make room enough for
          // one item with these maths
          if (pos.py < 0.33) {
            this.setDropAbove();
          }
        } else if (this.get('dropAbove')) {
          if (pos.py > 0.66) {
            this.setDropBelow();
          }
        } else {
          if (pos.py < 0.5) {
            this.setDropAbove();
          } else {
            this.setDropBelow();
          }
        }
      },

      /**
       * @method setDropPropertiesFromOnDragOver
       * @private
       */

      setDropPropertiesFromOnDragOver: function(event) {
        this.setDropPropertiesFromEvent(event);
      }.on('dragOver'),

      /**
       * Only need this on dragOver, but also doing it on dragEnter gives
       * snappier responses.
       *
       * @method setDropPropertiesFromOnDragEnter
       * @private
       */

      setDropPropertiesFromOnDragEnter: function(event) {
        this.setDropPropertiesFromEvent(event);
      }.on('dragEnter'),

      /**
       * Removes all the properties used to style the element.
       *
       * @private
       */

      resetDropProps: function() {
        this.set('dropAbove', false);
        this.set('dropBelow', false);
        this.set('firstDropTarget', false);
      },

      /**
       * @method handleDrop
       * @private
       */

      handleDrop: function() {
        this.set('droppedPosition', this.get('dropAbove') ? 'before' : 'after');
        this.resetDropProps();
      }.on('drop'),

      allowDrag: function() {
        return true;
      },

      /**
       * @method startDrag
       * @private
       */

      startDrag: function(event) {
        if (!this.allowDrag(event)) {
          return;
        }
        // stopPropagation to allow nested sortables
        event.stopPropagation();
        this.setEventData(event);
        startedNewDrag = true;
        currentSortableDrag = this;
        // later because browsers clone the element in its state right now
        // and we don't want the `is-dragging` styles applied to the ghost
        Ember.run.later(this, 'set', 'isDragging', true, 0);
        this.sendAction('on-dragstart');
      }.on('dragStart'),

      /**
       * Resets properties set while dragging.
       *
       * Note: Implementations may perform a sort on drop that destroys this
       * component; `dragEnd` cannot fire on a removed element. This code is
       * not guaranteed to run.
       *
       * @method resetOnDragEnd
       * @private
       */

      resetOnDragEnd: function() {
        this.set('isDragging', false);
        this.sendAction('on-dragend');
      }.on('dragEnd'),

      /**
       * Sets the `isDropping` property. We need to know this so we can do
       * different css during a drop (probably stop animating).
       *
       * @method setIsDropping
       * @private
       */

      setIsDropping: function() {
        this.set('isDropping', true);
        // later so css animations can be changed
        Ember.run.later(this, 'set', 'isDropping', false, 10);
      }.on('drop')

    });

    function relativeClientPosition(el, event) {
      var rect = el.getBoundingClientRect();
      var x = event.clientX - rect.left;
      var y = event.clientY - rect.top;
      return {
        x: x,
        y: y,
        px: x / rect.width,
        py: y / rect.height
      };
    }

    // Some messy drags don't trigger dragLeave on the currentDropTarget
    // this will get called in those cases (but not on valid drops)
    window.addEventListener('dragend', function() {
      currentDropTarget && currentDropTarget.resetDropProps();
    }, false);

    __exports__["default"] = Sortable;
  });
require([ 'core/dispatcher' ], function(Dispatcher) {
  var global = this;

  /**
   * Store-testing facilities for jasmine suites.
   *
   * Exposed facilities:
   *
   * 1. Global onChange and onError spies
   *
   * Since it's very common you'll want to pass "onChange" and "onError"
   * callbacks to test store activity, you get these as jasmine spies for free
   * in every spec.
   *
   * They're also exposed to the global context, so you can just reference them
   * as "onChange" and "onError".
   *
   * 2. Helper method: "this.sendAction()"
   *
   * Signature:
   *     this.sendAction(action, payload[, customOnChange, customOnError])
   *
   * Returns:
   *   The promise returned by the Dispatcher.
   *
   * Send an action request through the dispatcher with the given payload.
   *
   * If you don't pass in custom onChange and onError handlers, the global ones
   * will be used.
   *
   *     describe('statistics:generateReport', function() {
   *       this.storeSuite(myStore);
   *
   *       it('should work', function() {
   *         this.sendAction('statistics:generateReport', 'student_analysis');
   *         expect(onChange).toHaveBeenCalled();
   *       });
   *     });
   *
   * 3. Auto-reset of store state, if you pass it in
   *
   * 4. Suite implicitly becomes a PromiseSuite (see jasmine_rsvp) so you can do
   *    `this.flush()` to flush the promise queue.
   *
   * @param  {Store} [store=undefined]
   *         The store you're testing. If you pass this in, you will get an
   *         auto afterEach() block that resets the Store's state by calling
   *         store.__reset__().
   */
  jasmine.Suite.prototype.storeSuite = function(store) {
    this.promiseSuite = true;
    this.beforeEach(function() {
      var onChange = global.onChange = jasmine.createSpy('onChange');
      var onError = global.onError = jasmine.createSpy('onError');

      this.sendAction = function(action, payload, _onChange, _onError) {
        var svc = Dispatcher.dispatch(action, payload);

        _onChange = _onChange || onChange;
        _onError = _onError || onError;

        svc.promise.then(_onChange, _onError);
        this.flush();

        return svc.promise;
      };
    });

    this.afterEach(function() {
      if (store) {
        store.__reset__();
      }
    });
  };
})
define ->

  # duck punches `obj` method `method` with `fn`, supplying the old method
  # as the first argumnet of the new method (so you can call it still)
  #
  # ex.
  #
  #   obj = foo: (words) -> console.log words
  #   punch obj, 'foo', (old, words) ->
  #     # call the old one
  #     old words
  #
  #     # do something new
  #     alert words
  #
  # @param {Object} obj - the object with the method to be punched
  # @param {String} method - the name of the method to be punched
  # @param {Function} fn - the new method definition
  #   @signature fn(old [, args])
  #   @param {Function} old - the old method *already bound* to the object
  #   @param {mixed} args - the previous parameters
  punch = (obj, method, fn) ->
    old = obj[method]
    obj[method] = (args...) ->
      args.unshift -> old.apply obj, arguments
      fn.apply obj, args


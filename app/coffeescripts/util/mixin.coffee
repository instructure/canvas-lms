define ['underscore'], ({extend, flatten}) ->

  ##
  # Merges mixins into target, being mindful of certain properties (like
  # events) that need to be merged also.
  
  magicMethods = ['attach', 'afterRender', 'initialize']
  magicMethodRegex = /// ^ (?:
    __(#{magicMethods.join('|')})__ # cached value with __ prefix/postfix
    | (#{magicMethods.join('|')})   # "raw" uncached method pre-mixin
  ) $ ///

  mixin = (target, mixins...) ->
    target = target.prototype if 'function' is typeof target
    for mixin in mixins
      for key, prop of mixin
        # don't blow away old events, merge them
        if key in ['events', 'defaults', 'els']
          # don't extend parent embedded objects, copy them
          parentClassKey = target.constructor?.prototype[key]
          target[key] = extend({}, parentClassKey, target[key], prop)
        # crazy magic multiple inheritence
        else if match = key.match magicMethodRegex
          [alreadyMixedIn, notMixedInYet] = match[1..]
          (target["__#{alreadyMixedIn or notMixedInYet}__"] ||= []).push prop
        else
          target[key] = prop
    for key in ("__#{method}__" for method in magicMethods)
      target[key] = flatten target[key], true if target[key]
    target


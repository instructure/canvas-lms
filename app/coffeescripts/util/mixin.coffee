define ['underscore'], ({extend}) ->

  ##
  # Merges mixins into target, being mindful of certain properties (like
  # events) that need to be merged also.

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
        else if key in ['attach', 'afterRender', 'initialize']
          (target["__#{key}__"] ||= []).push prop
        else
          target[key] = prop
    target


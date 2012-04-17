# turns {'foo[bar]': 1} into {foo: {bar: 1}}
define ['underscore'], (_) ->
  unflatten = (obj) ->
    _(obj).reduce (newObj, val, key) ->
      keys = key.split('][')
      lastKey = keys.length - 1
    
      # If the first keys part contains [ and the last ends with ], then []
      # are correctly balanced.
      if /\[/.test(keys[0]) && /\]$/.test(keys[lastKey])
        # Remove the trailing ] from the last keys part.
        keys[lastKey] = keys[lastKey].replace(/\]$/, '')
        
        # Split first keys part into two parts on the [ and add them back onto
        # the beginning of the keys array.
        keys = keys.shift().split('[').concat(keys)
        lastKey = keys.length - 1
      else
        # Basic 'foo' style key.
        lastKey = 0
      
      if lastKey
        # Complex key, build deep object structure based on a few rules:
        # * The 'cur' pointer starts at the object top-level.
        # * [] = array push (n is set to array length), [n] = array if n is 
        #   numeric, otherwise object.
        # * If at the last keys part, set the value.
        # * For each keys part, if the current level is undefined create an
        #   object or array based on the type of the next keys part.
        # * Move the 'cur' pointer to the next level.
        # * Rinse & repeat.
        i = 0
        cur = newObj
        while i <= lastKey
          key = if keys[i] is ""
            cur.length 
          else 
            keys[i]
          
          cur = cur[key] = if i < lastKey
            cur[key] or if keys[i + 1] and isNaN(keys[i + 1])
              {} 
            else 
              []
          else 
            val
          i++
        
      else
        # Simple key, even simpler rules, since only scalars and shallow
        # arrays are allowed.
        
        if _.isArray newObj[key]
          # val is already an array, so push on the next value.
          newObj[key].push val
          
        else if newObj[key]?
          # val isn't an array, but since a second value has been specified,
          # convert val into an array.
          newObj[key] = [newObj[key], val]
          
        else
          # val is a scalar.
          newObj[key] = val
          
      return newObj
    , {}
  
function serialize(value) {
  if(typeof value === 'boolean' || value === null) { value = JSON.stringify(value); }
  if(value instanceof HTMLElement) {
    value = value.toString();
  }

  if(typeof value !== 'undefined' && typeof value !== 'string' && value.toString) {
    value = value.toString();
  } else {
    // Otherwise testem croaks
    console.log(typeof value) 
    value = 'n/a';
  }

  return value;
}

QUnit.config['log'].unshift(function(details) {
  try {
    details.actual = serialize(details.actual);
    details.expected = serialize(details.expected);

    if(details.actual instanceof Array) {
      for (var i = 0; i < details.actual.length; i++) {
        details.actual[i] = serialize(details.actual[i]);
      }
    }

    if(details.expected instanceof Array) {
      for (var i = 0; i < details.expected.length; i++) {
        details.expected[i] = serialize(details.expected[i]);
      }
    }    
  } catch(e) {}
});
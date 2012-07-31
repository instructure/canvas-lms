define(['jquery', 'compiled/jquery/serializeForm'], function ($){

  var patterns = {
    validate: /^[a-zA-Z][a-zA-Z0-9_]*(?:\[(?:\d*|[a-zA-Z0-9_]+)\])*$/,
    key:    /[a-zA-Z0-9_]+|(?=\[\])/g,
    push:   /^$/,
    fixed:  /^\d+$/,
    named:  /^[a-zA-Z0-9_]+$/
  };

  var build = function(base, key, value){
    base[key] = value;
    return base;
  };

  $.fn.toJSON = function() {

    var json = {},
        push_counters = {};

    var push_counter = function(key, i){
      if(push_counters[key] === undefined){
        push_counters[key] = 0;
      }
      if(i === undefined){
        return push_counters[key]++;
      }
      else if(i !== undefined && i > push_counters[key]){
        return push_counters[key] = ++i;
      }
    };

    $.each($(this).serializeForm(), function(){

      // skip invalid keys
      if(!patterns.validate.test(this.name)){
        return;
      }

      var k,
        keys = this.name.match(patterns.key),
        merge = this.value,
        reverse_key = this.name;

      while((k = keys.pop()) !== undefined){

        // adjust reverse_key
        reverse_key = reverse_key.replace(new RegExp("\\[" + k + "\\]$"), '');

        // push
        if(k.match(patterns.push)){
          merge = build([], push_counter(reverse_key), merge);
        }

        // fixed
        else if(k.match(patterns.fixed)){
          push_counter(reverse_key, k);
          merge = build([], k, merge);
        }

        // named
        else if(k.match(patterns.named)){
          merge = build({}, k, merge);
        }
      }

      json = $.extend(true, json, merge);
    });

    return json;
  };
});


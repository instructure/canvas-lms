// //inspired from http://www.prototypejs.org/api/template
// 
// //so to take the example from that page, here's how you do it the jquery way.
// 
// //creating a few similar objects
// var conversion1 = {from: 'meters', to: 'feet', factor: 3.28};
// var conversion2 = {from: 'kilojoules', to: 'BTUs', factor: 0.9478};
// var conversion3 = {from: 'megabytes', to: 'gigabytes', factor: 1024};
// 
// //the template  
// var templ = 'Multiply by #{factor} to convert from #{from} to #{to}.';
// 
// //let's format each object
// [conversion1, conversion2, conversion3].each( function(conv){
//     $.template(templ, conv);
// });
// // -> Multiply by 3.28 to convert from meters to feet.
// // -> Multiply by 0.9478 to convert from kilojoules to BTUs.
// // -> Multiply by 1024 to convert from megabytes to gigabytes.
// 
// 
// // NOTE: uses ruby-style string interpolation: #{}
// 


define(['jquery'], function($) {
  $.extend({
    template : function(template, values) {
      // handle a blank template or replacement value object correctly
      template = template   || '';
      values = values || {};
      
    	var regexMatchingPattern = /#\{([^{}]*)}/g; //ex: #{thingToMatch}
      var replacementFunction = function (str, match) {
        return (typeof values[match] === 'string' || typeof values[match] === 'number') ? values[match] : str;
			};
			
			return template.replace(regexMatchingPattern, replacementFunction);
		}
	});
});

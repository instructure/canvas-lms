// we use the React.DOM pragma all over the place
// which the babel loader hates, but don't want to remove it until
// after the cutover to webpack.  This loader just yanks it out
// before babel gets ahold of it

module.exports = function(input){
  this.cacheable();
  var pragmaRexep = /\/\*\*.*@jsx React.DOM.*\*\//;
  var inputSansPragma = input.replace(pragmaRexep, '');
  return inputSansPragma;
};

// We specify partials with an arrow and expect to simply find them
// because out old build would register them manually in a rewrite.
// We should be able to find them by referencing them relative to the jst directory

var addPartialLeader = function(fullName){
  var refPieces = fullName.split("/");
  refPieces[refPieces.length - 1] = "_" + refPieces[refPieces.length - 1];
  return refPieces.join("/");
}

module.exports = function(input){
  this.cacheable();
  var partialsRegexp = /\{\{>(.+)( |})/g;
  // search for all things that look like partial references {{>partial}},
  // replace them with {{> $jst/_partial}}
  var newInput = input.replace(partialsRegexp, function(partialInvocation){
    var fixedInvocation = partialInvocation.replace(/([^\{\}> ]+) ?/, function(partialName){
      // replace the name of the partial with a reference webpack can resolve
      var newPartialName = addPartialLeader("$jst/" + partialName);
      return newPartialName;
    });
    return fixedInvocation
  });

  //search for all sub-partial references like {{>[assignments/partial],
  // replace them with {{> $jst/assignments/_partial}}
  var subPartialsRegexp = /\{\{> ?\[.+?\]/g;
  newInput = newInput.replace(subPartialsRegexp, function(partialInvocation){
    var absoluteReferencedPartial = partialInvocation.replace("[", " $jst/").replace("]", "");
    var fixedInvocation = addPartialLeader(absoluteReferencedPartial)
    return fixedInvocation;
  });

  return newInput;
}

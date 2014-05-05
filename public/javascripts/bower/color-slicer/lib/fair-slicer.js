// This divides a range iteratively using the golden ratio.
// This method keeps gaps to similar size and ensures
// that any small contiguous set is spaced apart.

var PHI = (1+ Math.sqrt(5))/2;

module.exports = function(count, min, max, start) {
  if (min === undefined) {
    min = 0;
  }
  if (max === undefined) {
    max = 1;
  }
  if (start === undefined) {
    start = 0;
  }
  var width = max - min;

  var slices = [];
  var slice = start;
  var shift = width / PHI;
  for (var i = 0; i < count; i++) {
    slices.push(slice);
    slice += shift;
    if (slice > max) {slice -= width;}
  }

  return slices;
};

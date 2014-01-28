// This divides a range iteratively, using progressively smaller binary
// increments. A potential improvement here would be jumping around
// within each pass, to avoid having a temporarily lopsided distribution,
// but it's not too bad.
//
// I originally implemented this using the golden ratio, which gives nice
// results for small numbers, but it's significantly worse at scale.

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

  var step = 1;
  var gapCount = 1;
  var gapIdx = 0;
  var pos = 0;
  var slices = [];
  for (i = _i = 0; 0 <= count ? _i < count : _i > count; i = 0 <= count ? ++_i : --_i) {
    var cut = pos + step;
    pos += step * 2;
    gapIdx++;
    if (gapIdx === gapCount) {
      gapIdx = 0;
      pos = 0;
      step /= 2;
      gapCount = 1 / step / 2;
    }
    cut = min + cut * width + start;
    if (cut >= max) {
      cut -= width;
    }
    slices.push(cut);
  }
  return slices;
};

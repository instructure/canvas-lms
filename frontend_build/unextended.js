// If we use this loader, we're just saying "don't apply extensions to this file".
// The loader itself makes no code transformation, and that's intentional.
module.exports = function (source) {
  return source
}

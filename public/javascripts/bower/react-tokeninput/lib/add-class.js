module.exports = addClass;

function addClass(existing, added) {
  if (!existing) return added;
  if (existing.indexOf(added) > -1) return existing;
  return existing + ' ' + added;
}

function isPresent(passed, name) {
  return (passed && passed[name] !== undefined)
}

export default function(name, options, passed){
  if (isPresent(passed, name)) {
    options[name] = passed[name]
  }
 };

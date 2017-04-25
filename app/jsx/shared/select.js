// select properties from an object and returns a new obj with those props
// inspired by ruby's select method
// example: select(assignment, ['name', 'points']) would return a new object like { name: 'foo', points: 20 }
// esp useful for mapping state props in redux connected components
export default function select (obj, props) {
  return props.reduce((propSet, prop) => {
    // allows aliasing selected props by passing an array like [old_prop, new_prop]
    // for examle select(assignment, ['points', ['assignment_name', 'name']]) will copy `assignment_name` into `name`
    const [src, dest] = Array.isArray(prop) ? prop : [prop, prop]
    return Object.assign(propSet, { [dest]: obj[src] })
  }, {})
}

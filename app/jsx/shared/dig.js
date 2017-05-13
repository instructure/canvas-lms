// dig multiple layers deep inside an object with a single string path
// inspired by ruby's dig method
// example: dig(assignment, 'teacher.name') would return the value of assignment.teacher.name
// useful for deep dynamic extraction of data from objects
export default function dig (obj, path) {
  try {
    return path.split('.').reduce((subObj, key) => subObj[key], obj)
  } catch (e) {
    return undefined
  }
}

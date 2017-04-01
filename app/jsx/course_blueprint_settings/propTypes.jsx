define([
  'react',
], (React) => {
  const { shape, string, arrayOf } = React.PropTypes
  const propTypes = {}

  propTypes.term = shape({
    id: string.isRequired,
    name: string.isRequired,
  })

  propTypes.account = shape({
    id: string.isRequired,
    name: string.isRequired,
  })

  propTypes.course = shape({
    id: string.isRequired,
    name: string.isRequired,
    course_code: string.isRequired,
    term: propTypes.term.isRequired,
    teachers: arrayOf(shape({
      display_name: string.isRequired,
    })).isRequired,
    sis_course_id: string,
  })

  propTypes.termList = arrayOf(propTypes.term)
  propTypes.accountList = arrayOf(propTypes.account)
  propTypes.courseList = arrayOf(propTypes.course)

  return propTypes
})

define([
  'react',
], (React) => {
  const { shape, string, arrayOf } = React.PropTypes
  const propTypes = {}

  propTypes.course = shape({
    id: string.isRequired,
    name: string.isRequired,
  })

  propTypes.term = shape({
    id: string.isRequired,
    name: string.isRequired,
  })

  propTypes.account = shape({
    id: string.isRequired,
    name: string.isRequired,
  })

  propTypes.courseList = arrayOf(propTypes.course)
  propTypes.termList = arrayOf(propTypes.term)
  propTypes.accountList = arrayOf(propTypes.account)

  return propTypes
})

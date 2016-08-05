define([
  'react',
], ({ PropTypes }) => {
  const { shape, arrayOf, string, number } = PropTypes

  return shape({
    course_id: number,
    name: string,
    title: string,
    grading_scheme: string,
    grading_type: string.isRequired,
    points_possible: number.isRequired,
    submission_types: arrayOf(string),
  })
})

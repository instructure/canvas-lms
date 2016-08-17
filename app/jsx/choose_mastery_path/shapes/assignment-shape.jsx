define([
  'react',
  './category-shape',
], ({ PropTypes }, categoryShape) => {
  const { shape, string, number, instanceOf } = PropTypes

  return shape({
    title: string.isRequired,
    points_possible: number.isRequired,
    due_at: instanceOf(Date),
    category: categoryShape.isRequired,
  })
})

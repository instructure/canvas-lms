define([
  'react',
], ({ PropTypes }) => {
  const { shape, string, number } = PropTypes

  return shape({
    id: number.isRequired,
    name: string.isRequired,
    avatar_url: string,
  })
})

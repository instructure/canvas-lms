define([
  'react',
], (React) => {
  const { shape, string } = React.PropTypes

  return shape({
    id: string.isRequired,
    name: string.isRequired,
  })
})

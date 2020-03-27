define [
    'react',
    'react-dom',
    'jsx/observers/ObserversCard'
], (React, ReactDOM, ObserversCard) ->

renderComponent = (reactClass, mountPoint, props = {}, children = null) ->
    component = React.createElement(reactClass, props, children)
    ReactDOM.render(component, mountPoint)

renderObserversCard: () ->
    mountPoint = document.querySelector('[data-component='ObserversCard']')
    @observersCard = renderComponent(ObserversCard, mountPoint, props)
import App from 'jsx/course_blueprint_settings/sidebar'

const wrapper = document.getElementById('wrapper')
const root = document.createElement('div')
root.className = 'bcs__root'
wrapper.appendChild(root)

const app = new App(root)
app.render()

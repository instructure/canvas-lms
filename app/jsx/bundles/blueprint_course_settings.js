import App from 'jsx/blueprint_course_settings/index'

const wrapper = document.getElementById('wrapper')
const root = document.createElement('div')
root.className = 'bcs__root'
wrapper.appendChild(root)

const app = new App(root)
app.render()

import $ from 'jquery'
import Backbone from 'Backbone'
import userSettings from 'compiled/userSettings'
import Gradebook from 'compiled/gradebook/Gradebook'
import NavigationPillView from 'compiled/views/gradebook/NavigationPillView'
import OutcomeGradebookView from 'compiled/views/gradebook/OutcomeGradebookView'

const GradebookRouter = Backbone.Router.extend({
  routes: {
    '': 'tab',
    'tab-:viewName': 'tab'
  },

  initialize () {
    this.isLoaded = false
    this.views = {}
    this.views.assignment = new Gradebook(ENV.GRADEBOOK_OPTIONS)

    if (ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled) {
      this.views.outcome = this.initOutcomes()
    }
  },

  initOutcomes () {
    const book = new OutcomeGradebookView({
      el: $('.outcome-gradebook-container'),
      gradebook: this.views.assignment
    })
    book.render()
    this.navigation = new NavigationPillView({el: $('.gradebook-navigation')})
    this.navigation.on('pillchange', this.handlePillChange.bind(this))
    return book
  },

  handlePillChange (viewname) {
    if (viewname) this.navigate(`tab-${viewname}`, {trigger: true})
  },

  tab (viewName) {
    if (!viewName) viewName = userSettings.contextGet('gradebook_tab')
    window.tab = viewName
    if ((viewName !== 'outcome') || !this.views.outcome) { viewName = 'assignment' }
    if (this.navigation) { this.navigation.setActiveView(viewName) }
    $('.assignment-gradebook-container, .outcome-gradebook-container').addClass('hidden')
    $(`.${viewName}-gradebook-container`).removeClass('hidden')
    this.views[viewName].onShow()
    userSettings.contextSet('gradebook_tab', viewName)
  }
})

const router = new GradebookRouter()
Backbone.history.start()

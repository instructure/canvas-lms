const buildProps = options => (
  Object.assign(({
    assignment: {
      toggleWrapperSelector: ({
        show: '.assignment-buttons',
        edit: '.header-bar .header-bar-right .header-group-left',
      })[options.page],
      itemIdPath: ({
        show: 'ASSIGNMENT_ID',
        edit: 'ASSIGNMENT.id',
      })[options.page],
    },
    quiz: {
      toggleWrapperSelector: ({
        show: '.header-group-left',
        edit: '.header-bar .header-bar-right .header-group-left',
      })[options.page],
      toggleWrapperChildIndex: ({
        edit: 2,
      })[options.page],
      itemIdPath: 'QUIZ.id',
    },
    discussion_topic: {
      toggleWrapperSelector: ({
        show: '.form-inline .pull-right',
        edit: '.discussion-edit-header .text-right',
      })[options.page],
      itemIdPath: ({
        show: 'DISCUSSION.TOPIC.ID',
        edit: 'DISCUSSION_TOPIC.ATTRIBUTES.id',
      })[options.page],
    },
    wiki_page: {
      toggleWrapperSelector: ({
        show: '.header-bar .header-bar-right',
      })[options.page],
      itemIdPath: 'WIKI_PAGE.page_id',
    },
  })[options.itemType], options)
)

export default buildProps

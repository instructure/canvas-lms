define [
  'react'
  '../utils/withGlobalDom'
], (React, withGlobalDom) ->

  FolderChildren = React.createClass

    render: withGlobalDom ->

      div( {className:"ef-folder-list"},
        ul( {role:"tree"},
          li( {role:"treeitem", 'aria-expanded':"true"},
            header( {className:"ef-folder-header"},
              a( {href:"#"}, i( {className:"icon-arrow-down"})),
              a( {href:"#"},
                span( {className:"ef-folder-name"}, "SEE 510B")
              )
            ),
            ul( {role:"group"},
              li( {role:"treeitem"},
                header( {className:"ef-folder-header", style: {'padding-left': '18px'}},
                  a( {href:"#"}, i( {className:"icon-arrow-right"})),
                  a( {href:"#"},
                    span( {className:"ef-folder-name"}, "Assignments")
                  )
                )
              ),
              li( {role:"treeitem", 'aria-expanded':"true", 'aria-selected':"true"},
                header( {className:"ef-folder-header", style: {'padding-left': '18px'}},
                  a( {href:"#"}, i( {className:"icon-arrow-down"})),
                  a( {href:"#"},
                    span( {className:"ef-folder-name"}, "Calculus")
                  )
                ),
                ul( {role:"group"},
                  li( {role:"treeitem"},
                    header( {className:"ef-folder-header", style: {'padding-left': '18px'}},
                      a( {href:"#"}, i( {className:"icon-arrow-right"})),
                      a( {href:"#"},
                        span( {className:"ef-folder-name"}, "1010 Introduction into Calculus")
                      )
                    )
                  ),
                  li( {role:"treeitem"},
                    header( {className:"ef-folder-header", style: {'padding-left': '18px'}},
                      a( {href:"#"}, i( {className:"icon-arrow-right"})),
                      a( {href:"#"},
                        span( {className:"ef-folder-name"}, "1020 Advanced Calclulus - The amazing adventure begines here")
                      )
                    )
                  )
                )
              )
            )
          ),
          li( {role:"treeitem"},
            header( {className:"ef-folder-header"},
              a( {href:"#"}, i( {className:"icon-arrow-right"})),
              a( {href:"#"},
                span( {className:"ef-folder-name"}, "Outcomes")
              )
            )
          ),
          li( {role:"treeitem"},
            header( {className:"ef-folder-header"},
              a( {href:"#"}, i( {className:"icon-arrow-right"})),
              a( {href:"#"},
                span( {className:"ef-folder-name"}, "Quizzes")
              )
            )
          ),
          li( {role:"treeitem"},
            header( {className:"ef-folder-header"},
              a( {href:"#"}, i( {className:"icon-arrow-right"})),
              a( {href:"#"},
                span( {className:"ef-folder-name"}, "Pages")
              )
            )
          )
        )
      )

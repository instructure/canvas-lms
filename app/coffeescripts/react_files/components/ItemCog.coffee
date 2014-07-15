define [
  'react'
  '../utils/withGlobalDom'
  'compiled/models/Folder'
  'compiled/models/File'
  'compiled/react_files/components/RestrictStudentAccessModal'
], (React, withGlobalDom, Folder, File, RestrictStudentAccessModal) ->

  # Expects @props.model to be either a folder or a file collection/backbone model
  ItemCog = React.createClass

    propTypes:
      model: React.PropTypes.oneOfType([
        React.PropTypes.instanceOf(File),
        React.PropTypes.instanceOf(Folder)
      ])

    isAFolderCog: -> @props.model instanceof Folder

    getInitialState: -> restrictStudentModalOpen: false
    openRestricStudentModal: -> @setState restrictStudentModalOpen: true

    render: withGlobalDom ->
      div null,
        RestrictStudentAccessModal open: @state.restrictStudentModalOpen, null

        div className:'ef-hover-options',
          a herf:'#', style: {'color': 'black', 'margin-right': '10px'},
            i className:'icon-download'

          div className:'ef-admin-gear',
            div null,
              a className:'al-trigger al-trigger-gray', role:'button', 'aria-haspopup':'true', 'aria-owns':'content-1', 'aria-label':'Settings', href:'#',
                i className:'icon-settings',
                i className:'icon-mini-arrow-down'

              ul id:'content-1', className:'al-options', role:'menu', tabindex:'0', 'aria-hidden':'true', 'aria-expanded':'false', 'aria-activedescendant':'content-2',

                li {},
                  a href:'#', id:'content-2', tabindex:'-1', role:'menuitem', title:'Edit Name', 'Edit Name'
                li {},
                  a onClick: @openRestricStudentModal, href:'#', id:'content-3', tabindex:'-1', role:'menuitem', title:'Restrict Access', 'Restrict Access'
                li {},
                  a href:'#', id:'content-3', tabindex:'-1', role:'menuitem', title:'Delete', 'Delete'

                (li {},
                  a href:'#', id:'content-3', tabindex:'-1', role:'menuitem', title:'Download as Zip',
                    'Download as Zip'
                ) if @isAFolderCog()



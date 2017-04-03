import EquationEditorView from 'compiled/views/tinymce/EquationEditorView'
import * as Links from 'tinymce_plugins/instructure_links/links'
import InsertUpdateImageView from 'compiled/views/tinymce/InsertUpdateImageView'
import initializeEquella from 'tinymce_plugins/instructure_equella/initializeEquella'
import initializeExternalTools from 'tinymce_plugins/instructure_external_tools/initializeExternalTools'
import mediaEditorLoader from 'tinymce_plugins/instructure_record/mediaEditorLoader'
import INST from 'INST'

  function loadEventListeners (callbacks={}) {
    const validCallbacks = [
      'equationCB',
      'linksCB',
      "imagePickerCB",
      "equellaCB",
      "externalToolCB",
      "recordCB"
    ]

    validCallbacks.forEach( (cbName) => {
      if (callbacks[cbName] === undefined) {
        callbacks[cbName] = function(){ /* no-op*/ }
      }
    })

    document.addEventListener('tinyRCE/initEquation', ({detail}) => {
      const view = new EquationEditorView(detail.ed)
      callbacks.equationCB(view)
    });

    document.addEventListener('tinyRCE/initLinks', ({detail}) => {
      Links.initEditor(detail.ed)
      Links.renderDialog(detail.ed)
      callbacks.linksCB()
    });

    document.addEventListener('tinyRCE/initImagePicker', function(e){
      let view = new InsertUpdateImageView(e.detail.ed, e.detail.selectedNode);
      callbacks.imagePickerCB(view)
    });

    document.addEventListener('tinyRCE/initEquella', function(e) {
      initializeEquella(e.detail.ed)
      callbacks.equellaCB()
    });

    document.addEventListener('tinyRCE/initExternalTools', function(e) {
      initializeExternalTools.init(e.detail.ed, e.detail.url, INST)
      callbacks.externalToolCB()
    });

    document.addEventListener('tinyRCE/initRecord', function(e) {
      mediaEditorLoader.insertEditor(e.detail.ed)
      callbacks.recordCB()
    });
  }

export default loadEventListeners

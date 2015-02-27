/**
 * Copyright (C) 2011 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'compiled/editor/stocktiny',
  'i18n!editor',
  'str/htmlEscape'
], function(tinymce, I18n, htmlEscape) {

  tinymce.create('tinymce.plugins.InstructureEquation', {
    init : function(ed, url) {
      ed.addCommand('instructureEquation', function() {
        require(['compiled/views/tinymce/EquationEditorView'], function(EquationEditorView){
          new EquationEditorView(ed);
        });
      });

      ed.addButton('instructure_equation', {
        title: htmlEscape(I18n.t('Insert Math Equation')),
        cmd: 'instructureEquation',
        image: url + '/img/button.gif'
      });

      ed.onNodeChange.add(function(ed, cm, e) {
        if(e.nodeName == 'IMG' && e.className == 'equation_image') {
          cm.setActive('instructure_equation', true);

          // Since equations are inserted as <img>es, we need to prevent the default
          // 'image' button from activating too. Runs async to make sure this happens
          // AFTER 'image' does it's thing
          setTimeout(function(){ cm.setActive('image', false) }, 1);

        } else {
          cm.setActive('instructure_equation', false);
        }
      });
    }
  });

  // Register plugin
  tinymce.PluginManager.add('instructure_equation', tinymce.plugins.InstructureEquation);
});

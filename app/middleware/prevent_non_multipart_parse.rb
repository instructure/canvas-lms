#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# Rails parses incoming post request data with Content-Type text/xml. We don't
# really want that behavior.

class PreventNonMultipartParse
  def initialize(app)
    @app = app
    @considered_paths = [ /\A\/api\/.*\/sis_imports[^\/]*(\/|)\z/,
                          /\A\/api\/.*\/outcome_imports[^\/]*(\/|)\z/ ]
    @ignored_content_types = [ /\Amultipart\/form-data/i ]
  end

  def call(env)
    env['ORIGINAL_CONTENT_TYPE'] = env['CONTENT_TYPE']
    env['CONTENT_TYPE'] = 'application/octet-stream' if !@considered_paths.detect{ |r| env['PATH_INFO'] =~ r }.nil? && @ignored_content_types.detect{ |r| env['CONTENT_TYPE'] =~ r }.nil?
    @app.call(env)
  end

end

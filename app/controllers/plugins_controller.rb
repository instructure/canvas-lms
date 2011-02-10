#
# Copyright (C) 2011 Instructure, Inc.
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

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class PluginsController < ApplicationController
  before_filter :require_setting_site_admin

  def index
    @plugins = Canvas::Plugin.all
  end
  
  def show
    if find_plugin_setting
      @settings = @plugin.settings
    else
      flash[:notice] = "The plugin #{params[:id]} doesn't exist."
      redirect_to plugins_path
    end
  end

  def update
    if find_plugin_setting
      @plugin_setting.posted_settings = params[:settings]
      if @plugin_setting.save
        flash[:notice] = "Plugin settings successfully updated."
        redirect_to plugin_path(@plugin.id)
      else
        @settings = @plugin.settings
        flash[:error] = "There was an error saving the plugin settings."
        render :action => 'show'
      end
    else
      flash[:error] = "The plugin #{params[:id]} doesn't exist."
      redirect_to plugins_path
    end
  end

  protected
  
  def find_plugin_setting
    if @plugin = Canvas::Plugin.find(params[:id])
      @plugin_setting = PluginSetting.find_by_name(@plugin.id)
      @plugin_setting ||= PluginSetting.new(:name => @plugin.id, :settings => @plugin.default_settings)
      true
    else
      false
    end
  end

  def require_setting_site_admin
    require_site_admin_with_permission(:manage_site_settings)
  end
end

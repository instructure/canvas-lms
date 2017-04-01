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

module Canvas::Plugins::Validators::KalturaValidator
  CAN_BE_BLANK = [:cache_play_list_seconds, :rtmp_domain]

  def self.validate(settings, plugin_setting)
    if settings.map(&:last).all?(&:blank?)
      {}
    else
      errors = false
      settings.each do |k,v|
        if v.blank? && !CAN_BE_BLANK.member?(k.to_sym)
          plugin_setting.errors.add(:base, I18n.t('canvas.plugins.errors.fields_required', 'The field "%{field}" is required', :field => k))
          errors = true
        end
      end
      return false if errors

      if settings[:cache_play_list_seconds].blank?
        settings[:cache_play_list_seconds] = nil
      elsif settings[:cache_play_list_seconds] =~ /\A\d*\z/
        settings[:cache_play_list_seconds] = settings[:cache_play_list_seconds].to_i
      else
        plugin_setting.errors.add(:base, I18n.t('canvas.plugins.errors.need_integer', 'Please enter an integer for the play list cache'))
        return false
      end

      settings[:do_analytics] = Canvas::Plugin.value_to_boolean(settings[:do_analytics])
      settings[:hide_rte_button] = Canvas::Plugin.value_to_boolean(settings[:hide_rte_button])
      settings[:js_uploader] = Canvas::Plugin.value_to_boolean(settings[:js_uploader])
      settings.permit(:domain, :resource_domain, :rtmp_domain, :partner_id,
                     :subpartner_id, :secret_key, :user_secret_key,
                     :player_ui_conf, :kcw_ui_conf, :upload_ui_conf, :cache_play_list_seconds,
                     :kaltura_sis, :do_analytics, :hide_rte_button, :js_uploader).to_h.with_indifferent_access
    end
  end
end

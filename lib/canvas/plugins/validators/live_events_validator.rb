#
# Copyright (C) 2013 Instructure, Inc.
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

module Canvas::Plugins::Validators::LiveEventsValidator
  def self.validate(settings, plugin_setting)
    if settings.map(&:last).all?(&:blank?)
      {}
    else
      err = false

      if settings[:kinesis_stream_name].blank?
        plugin_setting.errors.add(:base, I18n.t('canvas.plugins.errors.stream_name_required', 'The kinesis stream name is required.'))
        err = true
      end

      if settings[:aws_endpoint].blank? && settings[:aws_region].blank?
        plugin_setting.errors.add(:base, I18n.t('canvas.plugins.errors.endpoint_or_region_required', 'The AWS region (or endpoint) is required.'))
        err = true
      end

      if !settings[:aws_endpoint].blank?
        uri = URI.parse(settings[:aws_endpoint].strip) rescue nil
        if !uri
          plugin_setting.errors.add(:base, I18n.t('canvas.plugins.errors.invalid_live_events_url', 'Invalid endpoint, must be a valid URL.'))
        end
      end

      if settings[:aws_access_key_id].blank? || settings[:aws_secret_access_key].blank?
        plugin_setting.errors.add(:base, I18n.t('canvas.plugins.errors.aws_creds_required', 'The AWS credentials are required.'))
        err = true
      end

      if err
        return false
      else
        return settings.slice(:kinesis_stream_name, :aws_access_key_id, :aws_secret_access_key, :aws_region, :aws_endpoint)
      end
    end
  end
end



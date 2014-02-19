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

class EventStream::Record < Struct.new(:attributes)
  def self.attributes(*attribute_names)
    attribute_names.each do |attribute_name|
      define_method attribute_name do
        attributes[attribute_name.to_s]
      end
    end
  end

  attributes :id,
             :created_at,
             :event_type

 def initialize(*args)
    super(*args)

    attributes['id'] ||= UUIDSingleton.instance.generate

    if attributes['request_id'].nil? && request_id = RequestContextGenerator.request_id
      attributes['request_id'] = request_id.to_s
    end

    attributes['created_at'] ||= Time.zone.now
    attributes['created_at'] = Time.zone.at(attributes['created_at'].to_i)

    if attributes['page_view']
      @page_view = attributes.delete('page_view')
    end

    attributes['event_type'] ||= self.class.name.gsub("::#{self.class.name.demodulize}", '').demodulize.underscore
  end

  def changes
    attributes
  end

  def request_id
    attributes['request_id']
  end

  def request_id=(value)
    # Since request_id is stored as text in cassandra we need to force it
    # to be a string.
    attributes['request_id'] = value && value.to_s
  end

  def page_view
    @page_view ||= PageView.find_by_id(request_id)
  end

  def self.from_attributes(attributes)
    new(attributes)
  end
end

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
module BasicLTI
  def self.explicit_signature_settings(timestamp, nonce)
    @timestamp = timestamp
    @nonce = nonce
  end
  
  def self.generate_params(params, url, key, secret)
    require 'uri'
    require 'oauth'
    require 'oauth/consumer'
    uri = URI.parse(url)

    if uri.port == uri.default_port
      host = uri.host
    else
      host = "#{uri.host}:#{uri.port}"
    end

    consumer = OAuth::Consumer.new(key, secret, {
      :site => "#{uri.scheme}://#{host}",
      :signature_method => "HMAC-SHA1"
    })

    path = uri.path
    path = '/' if path.empty?
    if !uri.query.blank?
      CGI.parse(uri.query).each do |query_key, query_values|
        unless params[query_key]
          params[query_key] = query_values.first
        end
      end
    end
    options = {
                :scheme           => 'body',
                :timestamp        => @timestamp,
                :nonce            => @nonce
              }
    request = consumer.create_signed_request(:post, path, nil, options, params.stringify_keys)

    # the request is made by a html form in the user's browser, so we
    # want to revert the escapage and return the hash of post parameters ready
    # for embedding in a html view
    hash = {}
    request.body.split(/&/).each do |param|
      key, val = param.split(/=/).map{|v| CGI.unescape(v) }
      hash[key] = val
    end
    hash
  end
  
  def self.generate(*args)
    BasicLTI::ToolLaunch.new(*args).generate
  end

  # Returns the LTI membership based on the LTI specs here: http://www.imsglobal.org/LTI/v1p1pd/ltiIMGv1p1pd.html#_Toc309649701
  def self.user_lti_data(user, context=nil)
    data = {}
    memberships = []
    concluded_memberships = []

    # collect canvas course/account enrollments
    if context.is_a?(Course)
      memberships += user.current_enrollments.find_all_by_course_id(context.id).uniq
      data['enrollment_state'] = memberships.any?{|membership| membership.state_based_on_date == :active} ? 'active' : 'inactive'
      concluded_memberships = user.concluded_enrollments.find_all_by_course_id(context.id).uniq
    end
    if context.respond_to?(:account_chain) && !context.account_chain_ids.empty?
      memberships += user.account_users.find_all_by_account_id(context.account_chain_ids).uniq
    end

    # convert canvas enrollments to LIS roles
    data['role_types'] = memberships.map{|membership|
      enrollment_to_membership(membership)
    }.uniq
    data['role_types'] = ["urn:lti:sysrole:ims/lis/None"] if memberships.empty?

    data['concluded_role_types'] = concluded_memberships.map{|membership|
      enrollment_to_membership(membership)
    }.uniq
    data['concluded_role_types'] = ["urn:lti:sysrole:ims/lis/None"] if concluded_memberships.empty?

    data
  end

  def self.enrollment_to_membership(membership)
    case membership
      when StudentEnrollment, StudentViewEnrollment
        'Learner'
      when TeacherEnrollment
        'Instructor'
      when TaEnrollment
        'urn:lti:role:ims/lis/TeachingAssistant'
      when DesignerEnrollment
        'ContentDeveloper'
      when ObserverEnrollment
        'urn:lti:instrole:ims/lis/Observer'
      when AccountUser
        'urn:lti:instrole:ims/lis/Administrator'
      else
        'urn:lti:instrole:ims/lis/Observer'
    end
  end
end
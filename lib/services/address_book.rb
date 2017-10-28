#
# Copyright (C) 2016 - present Instructure, Inc.
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

module Services
  class AddressBook
    # regarding these methods' parameters or options, generally:
    #
    #  * `sender` is a User or a user ID
    #  * `context` is an asset string ('course_123', or optionally subscoped
    #    such as 'course_123_teachers') or a Course, CourseSection, or Group
    #  * `users` is a list of Users or user IDs
    #  * `search` is a string
    #  * `exclude` is a list of Users or of user IDs
    #  * `weak_checks` is a truthy/falsey value
    #

    # which of the users does the sender know, and what contexts do they and
    # the sender have in common?
    def self.common_contexts(sender, users, ignore_result=false)
      recipients(sender: sender, user_ids: users, ignore_result: ignore_result).common_contexts
    end

    # which of the users have roles in the context and what are those roles?
    def self.roles_in_context(context, users, ignore_result=false)
      context = context.course if context.is_a?(CourseSection)
      recipients(context: context, user_ids: users, ignore_result: ignore_result).common_contexts
    end

    # which users:
    #
    #  - does the sender know in the context and what are their roles in that
    #    context? (sender present)
    #
    #      --OR--
    #
    #  - have roles in the context and what are those roles? (sender absent;
    #    admin view)
    #
    def self.known_in_context(sender, context, user_ids=nil, ignore_result=false)
      params = { sender: sender, context: context, ignore_result: ignore_result }
      params[:user_ids] = user_ids if user_ids
      response = recipients(params)
      [response.user_ids, response.common_contexts]
    end

    # how many users does the sender know in each of the contexts?
    def self.count_in_contexts(sender, contexts, ignore_result=false)
      counts = count_recipients(sender: sender, contexts: contexts, ignore_result: ignore_result)
      # map back from normalized to argument
      contexts.each do |ctx|
        serialized = serialize_context(ctx)
        if serialized != ctx
          counts[ctx] = counts.delete(serialized)
        end
      end
      counts
    end

    # of the users who are not in `exclude_ids` and whose name matches the
    # `search` term, if any, which:
    #
    #  - does the sender know, and what are their common contexts with the
    #    sender? (no context provided, sender must be)
    #
    #  - does the sender know in the context and what are their roles in that
    #    context? (context provided with sender)
    #
    #      --OR--
    #
    #  - have roles in the context and what are those roles? (context provided
    #    without sender; admin view)
    #
    def self.search_users(sender, options, service_options, ignore_result=false)
      params = options.slice(:search, :context, :exclude_ids, :weak_checks)
      params[:ignore_result] = ignore_result
      params[:sender] = sender

      # interpret pagination as specified in service_options
      params[:per_page] = service_options[:per_page] if service_options[:per_page]
      params[:cursor] = service_options[:cursor] if service_options[:cursor]

      # call out to service
      response = recipients(params)

      # interpret response
      [response.user_ids, response.common_contexts, response.cursors]
    end

    def self.recipients(params)
      Response.new(fetch("/recipients", query_params(params)))
    end

    def self.count_recipients(params)
      return {} if params[:contexts].blank?
      fetch("/recipients/counts", query_params(params))['counts'] || {}
    end

    def self.jwt # public only for testing, should not be used directly
      Canvas::Security.create_jwt({ iat: Time.now.to_i }, nil, jwt_secret)
    rescue StandardError => e
      Canvas::Errors.capture_exception(:address_book, e)
      nil
    end

    class << self
      private
      def setting(key)
        Canvas::DynamicSettings.find("address-book", default_ttl: 5.minutes)[key]
      rescue Imperium::TimeoutError => e
        Canvas::Errors.capture_exception(:address_book, e)
        nil
      end

      def app_host
        setting("app-host")
      end

      def jwt_secret
        Canvas::Security.base64_decode(setting("secret"))
      end

      # generic retrieve, parse
      def fetch(path, params={})
        url = app_host + path
        url += '?' + params.to_query unless params.empty?
        fallback = { "records" => [] }
        timeout_service_name = params[:ignore_result] == 1 ?
          "address_book_performance_tap" :
          "address_book"
        Canvas.timeout_protection(timeout_service_name) do
          response = CanvasHttp.get(url, 'Authorization' => "Bearer #{jwt}")
          if ![200, 202].include?(response.code.to_i)
            Canvas::Errors.capture(CanvasHttp::InvalidResponseCodeError.new(response.code.to_i), {
              extra: { url: url, response: response.body },
              tags: { type: 'address_book_fault' }
            })
            return fallback
          elsif params[:ignore_result] == 1
            return fallback
          else
            return JSON.parse(response.body)
          end
        end || fallback
      end

      # serialize logical params into query string values
      def query_params(params={})
        query_params = {}
        query_params[:cursor] = params[:cursor] if params[:cursor]
        query_params[:per_page] = params[:per_page] if params[:per_page]
        query_params[:search] = params[:search] if params[:search]
        if params[:sender]
          sender = params[:sender]
          sender = User.find(sender) unless sender.is_a?(User)
          visible_accounts = sender.associated_accounts.select{ |account| account.grants_right?(sender, :read_roster) }
          restricted_courses = sender.all_courses.reject{ |course| course.grants_right?(sender, :send_messages) }
          query_params[:for_sender] = serialize_item(sender)
          query_params[:visible_account_ids] = serialize_list(visible_accounts) unless visible_accounts.empty?
          query_params[:restricted_course_ids] = serialize_list(restricted_courses) unless restricted_courses.empty?
        end
        query_params[:in_context] = serialize_context(params[:context]) if params[:context]
        if params[:contexts]
          contexts = params[:contexts].map{ |ctx| serialize_context(ctx) }
          query_params[:in_contexts] = contexts.join(',')
        end
        query_params[:user_ids] = serialize_list(params[:user_ids]) if params[:user_ids]
        query_params[:exclude_ids] = serialize_list(params[:exclude_ids]) if params[:exclude_ids]
        query_params[:weak_checks] = 1 if params[:weak_checks]
        query_params[:ignore_result] = 1 if params[:ignore_result]
        query_params
      end

      def serialize_item(item)
        Shard.global_id_for(item)
      end

      def serialize_list(list) # can be either IDs or objects (e.g. User)
        list.map{ |item| serialize_item(item) }.join(',')
      end

      def serialize_context(context)
        if context.respond_to?(:global_asset_string)
          context.global_asset_string
        else
          context_type, context_id, scope = context.split('_', 3)
          global_context_id = serialize_item(context_id)
          asset_string = "#{context_type}_#{global_context_id}"
          asset_string += "_#{scope}" if scope
          asset_string
        end
      end
    end

    # /recipients returns data in the (JSON) shape:
    #
    #   {
    #     records: [
    #       {
    #         'user_id': '10000000000002',
    #         'contexts': [
    #           { 'context_type': 'course', 'context_id': '10000000000001', 'roles': ['TeacherEnrollment'] }
    #         ],
    #         cursor: ...
    #       },
    #       {
    #         'user_id': '10000000000005',
    #         'contexts': [
    #           { 'context_type': 'course', 'context_id': '10000000000002', 'roles': ['StudentEnrollment'] },
    #           { 'context_type': 'group', 'context_id': '10000000000001', 'roles': ['Member'] }
    #         ],
    #         cursor: ...
    #       }
    #     ],
    #     ...
    #   }
    #
    # where `user_id` is a string representation of the recipient's global
    # user ID, `contexts` is a list of contexts they have in common with
    # the sender, and `cursor` is the cursor to pass to start at the next
    # record. each context states the type, id (again as a string
    # representation of the global ID), and roles the recipient has in that
    # context (to the knowledge of the sender).
    #
    # this class facilitates separating those pieces
    class Response
      def initialize(response)
        @response = response
      end

      # extract just the user IDs from the response, as an ordered list
      def user_ids
        @response['records'].map{ |record| record['user_id'].to_i }
      end

      # reshape the records into a ruby hash with integers instead of strings
      # for IDs (but still global), user_ids promoted to keys, and context
      # types collated. e.g. for the above example, the transformed data would
      # have the (ruby) shape:
      #
      #   {
      #     10000000000002 => {
      #       courses: { 10000000000001 => ['TeacherEnrollment'] },
      #       groups: {}
      #     },
      #     10000000000005 => {
      #       courses: { 10000000000002 => ['StudentEnrollment'] },
      #       groups: { 10000000000001 => ['Member'] }
      #     }
      #   }
      #
      def common_contexts
        common_contexts = {}
        @response['records'].each do |recipient|
          global_user_id = recipient['user_id'].to_i
          contexts = recipient['contexts']
          common_contexts[global_user_id] ||= { courses: {}, groups: {} }
          contexts.each do |context|
            context_type = context['context_type'].pluralize.to_sym
            next unless common_contexts[global_user_id].key?(context_type)
            global_context_id = context['context_id'].to_i
            common_contexts[global_user_id][context_type][global_context_id] = context['roles']
          end
        end
        common_contexts
      end

      # extract the next page cursor from the response
      def cursors
        @response['records'].map{ |record| record['cursor'] }
      end
    end
  end
end

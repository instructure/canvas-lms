module ConditionalRelease
  class MigrationService
    class << self
      def applies_to_course?(course)
        ConditionalRelease::Service.enabled_in_context?(course)
      end

      def begin_export(course, opts)
        data = nil
        if opts[:selective]
          assignment_ids = opts[:exported_assets].map{|asset| (match = asset.match(/assignment_(\d+)/)) && match[1]}.compact
          return unless assignment_ids.any?
          data = {:export_settings => {:selective => '1', :exported_assignment_ids => assignment_ids}}.to_param
        end
        response = CanvasHttp.post(ConditionalRelease::Service.content_exports_url, headers_for(course), form_data: data)
        if response.code =~ /^2/
          json = JSON.parse(response.body)
          {:export_id => json['id'], :course => course}
        else
          raise "Error queueing export for Conditional Release: #{response.body}"
        end
      end

      def export_completed?(export_data)
        response = CanvasHttp.get("#{ConditionalRelease::Service.content_exports_url}/#{export_data[:export_id]}", headers_for(export_data[:course]))
        if response.code =~ /^2/
          json = JSON.parse(response.body)
          case json['state']
          when 'completed'
            true
          when 'failed'
            raise "Content Export for Conditional Release failed"
          else
            false
          end
        else
          raise "Error retrieving export state for Conditional Release: #{response.body}"
        end
      end

      def retrieve_export(export_data)
        response = CanvasHttp.get("#{ConditionalRelease::Service.content_exports_url}/#{export_data[:export_id]}/download", headers_for(export_data[:course]))
        if response.code =~ /^2/
          json = JSON.parse(response.body)
          unless json.values.all?(&:empty?) # don't bother saving if there's nothing to import
            return json
          end
        else
          raise "Error retrieving export for Conditional Release: #{response.body}"
        end
      end

      def send_imported_content(course, imported_content)
        data = {:file => StringIO.new(imported_content.to_json)}
        response = CanvasHttp.post(ConditionalRelease::Service.content_imports_url, headers_for(course), form_data: data, multipart: true)
        if response.code =~ /^2/
          json = JSON.parse(response.body)
          {:import_id => json['id'], :course => course}
        else
          raise "Error sending import for Conditional Release: #{response.body}"
        end
      end

      def import_completed?(import_data)
        response = CanvasHttp.get("#{ConditionalRelease::Service.content_imports_url}/#{import_data[:import_id]}", headers_for(import_data[:course]))
        if response.code =~ /^2/
          json = JSON.parse(response.body)
          case json['state']
          when 'completed'
            true
          when 'failed'
            raise "Content Import for Conditional Release failed"
          else
            false
          end
        else
          raise "Error retrieving import state for Conditional Release: #{response.body}"
        end
      end

      protected

      def headers_for(course)
        token = Canvas::Security::ServicesJwt.generate({
          sub: 'MIGRATION_SERVICE',
          role: 'admin',
          account_id: Context.get_account(course).root_account.lti_guid.to_s,
          context_type: 'Course',
          context_id: course.id.to_s,
          workflow: 'conditonal-release-api'
        })
        {"Authorization" => "Bearer #{token}"}
      end
    end
  end
end
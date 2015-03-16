module Lti
  class CaliperService
    def self.log_page_view(token, params)
      if params['@type'] == 'http://purl.imsglobal.org/caliper/v1/ViewEvent'
        duration = params[:duration]
        url = params[:object] ? params[:object]["@id"] : nil
        Lti::AnalyticsService.log_page_view(token, {duration: duration, url: url})
      end
    end
  end
end

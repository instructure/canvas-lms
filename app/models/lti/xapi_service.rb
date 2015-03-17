module Lti
  class XapiService
    def self.log_page_view(token, params)
      duration = params[:result] ? params[:result]['duration'] : nil
      url = params[:object] ? params[:object][:id] : nil
      Lti::AnalyticsService.log_page_view(token, {duration: duration, url: url})
    end
  end
end

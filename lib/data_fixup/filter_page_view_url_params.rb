module DataFixup::FilterPageViewUrlParams
  def self.run
    if PageView.cassandra?
      run_for_cassandra
    else
      run_for_db
    end
  end

  def self.run_for_db
    scope = PageView.select("request_id, url, created_at").order('request_id').limit(batch_size)
    records = scope.all
    while records.any?
      last_request_id = nil
      records.each do |pv|
        pv.url = LoggingFilter.filter_uri(pv.url)
        PageView.where(request_id: pv.request_id).update_all(url: pv.url) if pv.url_changed?
      end
      last_request_id = records.last.request_id
      records = scope.where("request_id > ?", last_request_id).all
    end
  end

  def self.run_for_cassandra
    last_request_id = ''

    loop do
      rows = get_rows(last_request_id, batch_size)
      break if rows.empty?
      rows.each do |pv|
        next if !pv.url
        pv.url = LoggingFilter.filter_uri(pv.url)
        PageView::EventStream.update(pv) if pv.url_changed?
      end
      Rails.logger.debug("FilterPageViewUrlParams: filtered #{batch_size} page views starting with #{last_request_id.inspect}")
      last_request_id = rows.last.request_id
    end
  end

  def self.batch_size
    Setting.get('filter_page_view_url_params_batch_size', '1000').to_i
  end

  def self.get_rows(last_request_id, batch_size)
    rows = []
    PageView::EventStream.database.execute("SELECT request_id, url, created_at FROM page_views WHERE token(request_id) > token(?) LIMIT ?", last_request_id, batch_size).fetch do |row|
      rows << PageView.from_attributes(row.to_hash)
    end
    rows
  end
end

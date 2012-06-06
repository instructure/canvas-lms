def collection_item_model(opts = {})
  opts = valid_collection_item_attributes.merge(opts)
  collection = opts.delete(:collection) || user.collections.create!(:name => 'test')
  opts[:collection_item_data] ||= collection_item_data_model
  opts[:user] ||= @user || user_model
  collection.collection_items.create!(opts).reload # reload to catch trigger changes
end

def collection_item_data_model(opts = {})
  opts = valid_collection_item_data_attributes.merge(opts)
  data = CollectionItemData.create!(opts)
  data.image_attachment = attachment_model(:uploaded_data => stub_png_data, :context => Account.default)
  data.image_pending = false
  data.save!
  data
end

def valid_collection_item_attributes
  {
    :user_comment => "test item",
  }
end

def valid_collection_item_data_attributes
  {
    :item_type => "url",
    :link_url => "http://www.example.com/test",
  }
end

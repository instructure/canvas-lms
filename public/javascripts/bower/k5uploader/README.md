# K5Uploader

A javascript based uploader for kaltura.

## Installation

`bower install k5uploader`

## Considerations

1. This uploader uses javascript, you may need to set up CORS with your kaltura instance to use it. By default kaltura does not have such headers.

2. The uploader uses xhr2. [Evergreen browsers support it today](http://caniuse.com/#feat=xhr2). Your support needs may limit your ability to use it.

## Usage

```javascript
//grab a file somehow
var file = this.files[0];

// options to configure the uploader
var opts = {
  kaltura_session: {
    ks: '', // valid kaltura session
    subp_id: '', //valid kaltura subpartner id
    partner_id: '', // valid kaltura partner id
    uid: '', // valid kaltura uid
    serverTime: '' // optional timestamp from session
  },
  allowedMediaTypes: ['video', 'audio'], // defaults
  uploadUrl: 'http://kaltura_box.com/index.php/partnerservices2/upload',
  entryUrl: 'http://kaltura_box.com/index.php/partnerservices2/addEntry',
  uiconfUrl: 'http://kaltura_box.com/index.php/partnerservices2/getuiconf',
  entryDefaults: {
    partnerData: "optional custom serialized data here",
  }
};

// create instance with options
var uploader = new K5Uploader(opts);

// wait for 'K5.ready' and upload the file
uploader.addEventListener('K5.ready', function()() {
  uploader.uploadFile(file);
});

```

## Events

The K5Uploader dispatches several events during the upload process. Listen to them or ignore them as your needs dictate.

|Event | Description|
|:---- |:---------- |
|`K5.uiconfError` | there has been an error loading data from the `uiconfUrl` |
| `K5.ready` | a valid kaltura session and uiconf serivce data is loaded. now save to upload |
| `K5.fileError` | uploaded filetype is not included in the `allowedMediaTypes` options |
| `K5.progress` | upload progress is detected |
| `K5.complete` | upload is complete |
| `K5.error` | error uploading file or adding upload via `entryUrl` |

### Dealing with events

In order to register an event handler, the `K5Uploader` includes the following methods:

```javascript
k5Uploader.addEventListener(eventName, callback);
k5Uploader.removeEventListener(eventName, callback)
```


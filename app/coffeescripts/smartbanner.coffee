define [
  'i18n!smartbanner',
  'jquery',
  'vendor/jquery.smartbanner'
], (I18n, $) ->
  $ ->
    # we only care about the android functionality of this library, so pull out
    # this check sothat we don't even try to match other types.
    if navigator.userAgent.match(/Android/i) != null
      $.smartbanner
        title: I18n.t('android_banner_title', 'Canvas by Instructure'),
        author: I18n.t('android_banner_author', 'Instructure Inc.'),
        price: I18n.t('android_banner_price', 'FREE'),
        inGooglePlay: I18n.t('android_banner_in_google_play', 'In Google Play'),
        GooglePlayParams: null,
        icon: '/images/android/logo.png',
        button: I18n.t('android_banner_view_button', 'VIEW'),
        daysHidden: 0,
        daysReminder: 0,
        layer: true

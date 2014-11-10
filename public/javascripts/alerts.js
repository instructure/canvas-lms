/**
 * Copyright (C) 2011 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'i18n!alerts',
  'jquery', // $
  'jquery.ajaxJSON', // ajaxJSON
  'jquery.instructure_forms', // validateForm, formErrors, errorBox
  'jquery.instructure_misc_helpers', // replaceTags
  'vendor/jquery.ba-tinypubsub', // /\.publish/
  'jqueryui/button' // /\.button/
], function(I18n, $) {

  $(function () {
    var $list = $('.alerts_list');

    var getAlertData = function($alert) {
      var criteria = [];
      $alert.find('ul.criteria li').each(function() {
        criteria.push({
          id: $(this).find('input[name="alert[criteria][][id]"]').attr('value'),
          criterion_type: $(this).data('value'),
          threshold: $(this).find('span').text()
        });
      });
      var recipients = [];
      $alert.find('ul.recipients li').each(function() {
        recipients.push($(this).data('value'));
      });
      var repetition = $alert.find('input[name="repetition"]:checked').attr('value');
      if(repetition == "value") {
        repetition = $alert.find('input[name="alert[repetition]"]').attr('value');
      } else {
        repetition = null;
      }
      return {criteria: criteria, recipients: recipients, repetition: repetition};
    }

    var addRecipientInOrder = function($node, $item) {
      $node.append($item);
      return $item;
    }

    var createElement = function(key, element, value, lookup) {
      var $element = $("<" + element + " />");
      $element.data('value', key);
      $element.html(lookup[key][value]);
      if(element == 'li') {
        $element.append(' ');
        $element.append($list.find('>.delete_item_link').clone().toggle());
      } else {
        $element.attr('value', key);
      }
      return $element;
    }

    var createRecipient = function(recipient, element) {
      $element = createElement(recipient, element, 'label', ENV.ALERTS.POSSIBLE_RECIPIENTS);
      if(element == 'li') {
        $element.prepend($("<input type='hidden' name='alert[recipients][]' />").attr('value', recipient));
      }
      return $element;
    }

    var createCriterion = function(criterion, element) {
      var criterion_type = criterion, threshold, id;
      if(typeof criterion == "object") {
        criterion_type = criterion.criterion_type;
        threshold = criterion.threshold;
        id = criterion.id;
      }
      $element = createElement(criterion_type, element, element == 'li' ? 'label' : 'option', ENV.ALERTS.POSSIBLE_CRITERIA)
      if (element == 'li') {
        if (!threshold) {
          threshold = ENV.ALERTS.POSSIBLE_CRITERIA[criterion_type].default_threshold;
        }
        $element.find('span').text(threshold);
        $element.find('input').attr('value', threshold).attr('title', ENV.ALERTS.POSSIBLE_CRITERIA[criterion_type].title);
        $element.prepend($("<input type='hidden' name='alert[criteria][][criterion_type]' />").attr('value', criterion_type));
        if(id) {
          $element.prepend($("<input type='hidden' name='alert[criteria][][id]' />").attr('value', id));
        }
      }
      return $element;
    }

    var restoreAlert = function($alert, data) {
      var $criteria = $alert.find('.criteria');
      $criteria.empty();
      for(var idx in data.criteria) {
        $criteria.append(createCriterion(data.criteria[idx], 'li'));
      }
      var $recipients = $alert.find('.recipients');
      $recipients.empty();
      for(var idx in data.recipients) {
        if (ENV.ALERTS.POSSIBLE_RECIPIENTS[data.recipients[idx]]) {
          $recipients.append(createRecipient(data.recipients[idx], 'li'));
        }
      }
      if(data.repetition) {
        $alert.find('input[name="repetition"][value="value"]').attr('checked', true);
        $alert.find('input[name="alert[repetition]"]').attr('value', data.repetition);
        $alert.find('.repetition_group .no_repetition').toggle(false);
        $alert.find('.repetition_group .repetition').toggle(true).find('span').text(data.repetition);
      } else {
        $alert.find('input[name="repetition"][value="none"]').attr('checked', true);
        $alert.find('.repetition_group .no_repetition').toggle(true);
        $alert.find('.repetition_group .repetition').toggle(false);
      }
    }

    for(var idx in ENV.ALERTS.DATA) {
      var alert = ENV.ALERTS.DATA[idx];
      restoreAlert($('#edit_alert_' + alert.id), alert);
    }

    $('.add_alert_link').click(function(event) {
      event.preventDefault();
      var $blank = $('.alert.blank');
      var $alert = $blank.clone();
      $alert.removeClass('blank');
      $alert.addClass('new');
      if($list.find('.alert:visible').length != 0) {
        $('<div class="alert_separator"></div>').insertBefore($blank);
      }
      var rand = Math.floor(Math.random() * 100000000);
      $alert.find('input').each(function() {
        $(this).attr('id', $.replaceTags($(this).attr('id'), 'id', rand));
      });
      $alert.find('label').each(function() {
        $(this).attr('for', $.replaceTags($(this).attr('for'), 'id', rand));
      });
      $alert.insertBefore($blank);
      $alert.find('.edit_link').trigger('click');
      $alert.toggle(false);
      $alert.slideDown();
    });

    $list.delegate('.edit_link', 'click', function() {
      var $alert = $(this).parents('.alert');
      var data = getAlertData($alert);
      $alert.data('data', data);

      var $criteria_select = $alert.find('.add_criterion_link').prev();
      $criteria_select.empty();
      var count = 0;
      for(var idx in ENV.ALERTS.POSSIBLE_CRITERIA_ORDER) {
        var criterion = ENV.ALERTS.POSSIBLE_CRITERIA_ORDER[idx];
        var found = -1;
        for(var jdx in data.criteria) {
          if(data.criteria[jdx].criterion_type == criterion) {
            found = jdx;
            break;
          }
        }
        if(found == -1) {
          $criteria_select.append(createCriterion(criterion, 'option'));
          count = count + 1;
        }
      }
      if(count == 0) {
        $alert.find('.add_criteria_line').toggle(false);
      }

      var $recipients_select = $alert.find('.add_recipient_link').prev();
      $recipients_select.empty();
      count = 0;
      for(var idx in ENV.ALERTS.POSSIBLE_RECIPIENTS_ORDER) {
        var recipient = ENV.ALERTS.POSSIBLE_RECIPIENTS_ORDER[idx];
        if($.inArray(recipient, data.recipients) == -1) {
          $recipients_select.append(createRecipient(recipient, 'option'));
          count = count + 1;
        }
      }
      if(count == 0) {
        $alert.find('.add_recipients_line').toggle(false);
      }

      $alert.find('.repetition_group label').toggle(true);
      $alert.toggleClass('editing');
      $alert.toggleClass('displaying');
      return false;
    }).delegate('.delete_link', 'click', function() {
      var $alert = $(this).parents('.alert');
      if(!$alert.hasClass('new')) {
        $alert.find('input[name="_method"]').attr('value', 'DELETE');
        $.ajaxJSON($alert.attr('action'), 'POST', $alert.serialize(), function(data) {
          $alert.slideUp(function() {
            $alert.remove();
            $list.find('.alert:first').prev('.alert_separator').remove();
            $list.find('.alert_separator + .alert_separator').remove();
            $list.find('.alert:visible:last').next('.alert_separator').remove();
          });
        });
      } else {
        $alert.slideUp(function() {
          $alert.remove();
          $list.find('.alert:first').prev('.alert_separator').remove();
          $list.find('.alert_separator + .alert_separator').remove();
          $list.find('.alert:visible:last').next('.alert_separator').remove();
        });
      }
      return false;
    }).delegate('.cancel_button', 'click', function() {
      $(this).parent().hideErrors();
      var $alert = $(this).parents('.alert');
      if($alert.hasClass('new')) {
        $alert.slideUp(function() {
          $alert.remove();
          $list.find('.alert:first').prev('.alert_separator').remove();
          $list.find('.alert_separator + .alert_separator').remove();
          $list.find('.alert:visible:last').next('.alert_separator').remove();
        });
      } else {
        var data = $alert.data('data');
        restoreAlert($alert, data);

        $alert.toggleClass('editing', false);
        $alert.toggleClass('displaying', true);
      }
      return false;
    }).delegate('.alert', 'submit', function() {
      var $alert = $(this);

      // Validation (validateForm doesn't support arrays, and formErrors
      // wouldn't be able to locate the correct elements)
      var errors = [];
      if($alert.find('.criteria li').length == 0) {
        errors.push([$alert.find('.add_criterion_link').prev(), I18n.t('errors.criteria_required', "At least one trigger is required")]);
      }
      $alert.find('.criteria input.editing').each(function() {
        var val = $(this).attr('value');
        if(!val || isNaN(val) || parseFloat(val) < 0) {
          errors.push([$(this), I18n.t('errors.threshold_should_be_numeric', "This should be a positive number")]);
        }
      });
      if($alert.find('.recipients li').length == 0) {
        errors.push([$alert.find('.add_recipient_link').prev(), I18n.t('errors.recipients_required', "At least one recipient is required")]);
      }
      if($alert.find('input[name="repetition"]:checked').attr('value') == 'none') {
        $alert.find('input[name="alert[repetition]"]').attr('value', '');
      } else {
        var $repetition = $alert.find('input[name="alert[repetition]"]');
        var val = $repetition.attr('value');
        if(!val || isNaN(val) || parseFloat(val) < 0) {
          errors.push([$repetition, I18n.t('errors.threshold_should_be_numeric', "This should be a positive number")]);
        }
      }
      if(errors.length != 0) {
        $alert.formErrors(errors);
        return false;
      }

      $.ajaxJSON($alert.attr('action'), 'POST', $alert.serialize(), function(data, xhr) {
        $alert.removeClass('new');
        $alert.attr('action', xhr.getResponseHeader('Location'));
        var $method = $alert.find('input[name="_method"]');
        if($method.length == 0) {
          $alert.append($('<input type="hidden" name="_method" value="put" />'));
        }
        $alert.toggleClass('editing', false);
        $alert.toggleClass('displaying', true);
        restoreAlert($alert, data);
      }, function(data) {
        $alert.formErrors(data);
      });
      return false;
    }).delegate('.recipients .delete_item_link', 'click', function() {
      var $li = $(this).parents('li');
      var $add_link = $(this).parents('.alert').find('.add_recipient_link');
      addRecipientInOrder($add_link.prev(), createRecipient($li.data('value'), 'option'));

      $li.slideUp(function() {
        $li.remove();
      });
      $add_link.parent().slideDown(function() {
        $add_link.parent().css('display', '');
      });
      return false;
    }).delegate('.add_recipient_link', 'click', function() {
      var $recipients = $(this).parents('.alert').find('.recipients');
      var $select = $(this).prev();
      var recipient = $select.attr('value');
      addRecipientInOrder($recipients, createRecipient(recipient, 'li')).toggle().slideDown();
      var $errorBox = $select.data('associated_error_box');
      if($errorBox) {
        $errorBox.fadeOut('slow', function() {
          $errorBox.remove();
        });
      }

      $select.find('option[value="' + recipient + '"]').remove();

      if($select.find('*').length == 0) {
        $(this).parent().slideUp();
      }
      return false;
    }).delegate('.criteria .delete_item_link', 'click', function() {
      var $li = $(this).parents('li');
      var $add_link = $(this).parents('.alert').find('.add_criterion_link');
      addRecipientInOrder($add_link.prev(), createCriterion($li.data('value'), 'option'));

      $li.slideUp(function(){
        $li.remove();
      });
      $add_link.parent().slideDown(function() {
        $add_link.parent().css('display', '');
      });
      return false;
    }).delegate('.add_criterion_link', 'click', function() {
      var $criteria = $(this).parents('.alert').find('.criteria');
      var $select = $(this).prev();
      var criterion = $select.attr('value');
      addRecipientInOrder($criteria, createCriterion(criterion, 'li')).toggle().slideDown();
      var $errorBox = $select.data('associated_error_box');
      if($errorBox) {
        $errorBox.fadeOut('slow', function() {
          $errorBox.remove();
        });
      }

      $select.find('option[value="' + criterion + '"]').remove();

      if($select.find('*').length == 0) {
        $(this).parent().slideUp();
      }
      return false;
    }).delegate('input[name="repetition"]', 'click', function() {
      var $error_box = $(this).parents('.alert').find('input[name="alert[repetition]"]').data('associated_error_box');
      if($error_box) {
        $error_box.fadeOut('slow', function() {
          $error_box.remove();
        });
      }
    }).delegate('label.repetition', 'click', function(event){
      event.preventDefault();
      $(this).parents('.alert').find('input[name="repetition"]').prop('checked', true);
    });
  });
});


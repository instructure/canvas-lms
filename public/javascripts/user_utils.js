define(['jquery'], function($) {

// see also User.name_parts in user.rb
return {
  nameParts: function(name, prior_surname) {
    var SUFFIXES = /^(Sn?r\.?|Senior|Jn?r\.?|Junior|II|III|IV|V|VI|Esq\.?|Esquire)$/i
    var surname, given, suffix, given_parts, prior_surname_parts, name_parts;
    if (!name || $.trim(name) === '') {
      return [null, null, null];
    }
    name_parts = $.map(name.split(','), function(str) {
      return $.trim(str);
    });
    surname = name_parts[0];
    given = name_parts[1];
    suffix = name_parts.slice(2).join(', ');
    if (suffix === '') {
      suffix = null;
    }

    if (suffix && !SUFFIXES.test(suffix)) {
      given = given + ' ' + suffix;
      suffix = null;
    }

    if (typeof given === 'string') {
      // John Doe, Sr.
      if (!suffix && SUFFIXES.test(given)) {
        suffix = given;
        given = surname;
        surname = null;
      }
    } else {
      // John Doe
      given = $.trim(name);
      surname = null;
    }

    given_parts = given.split(/\s+/)
    if (given_parts.length === 1 && given_parts[0] === '') {
      given_parts = [];
    }
    // John Doe Sr.
    if (!suffix && given_parts.length > 1 && SUFFIXES.test(given_parts[given_parts.length - 1])) {
      suffix = given_parts.pop();
    }
    // Use prior information on the last name to try and reconstruct it
    // This just checks if prior_surname was provided, and if it matches
    // the trailing words of given_parts
    if (!surname && prior_surname && !(/^\s*$/).test(prior_surname) &&
        (prior_surname_parts = prior_surname.split(/\s+/)) &&
        given_parts.length >= prior_surname_parts.length &&
        given_parts.slice(given_parts.length - prior_surname_parts.length).join(' ') === prior_surname_parts.join(' ')) {
      surname = given_parts.splice(given_parts.length - prior_surname_parts.length, prior_surname_parts.length).join(' ')
    }
    // Last resort; last name is just the last word given
    if (!surname && given_parts.length > 1) {
      surname = given_parts.pop();
    }

    return [ given_parts.length === 0 ? null : given_parts.join(' '), surname, suffix ];
  },
  lastNameFirst: function(parts) {
    var given = $.trim([parts[0], parts[2]].join(' '));
    return $.trim((parts[1] ? parts[1] + ', ' + given : given));
  },
  firstNameFirst: function(parts) {
    return $.trim(parts.join(' ').replace(/\s+/, ' '));
  }
};
});


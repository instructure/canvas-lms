define([], () => {
  // parse the list of names entered by our user into an array
  // separates entries on , or \n
  // deals with entries like '"Last, First" email' where there's a common w/in quotes
  function parseNameList (nameList) {
    const names = [];
    let iStart = 0;
    let inQuote = false;
    for (let i = 0; i < nameList.length; ++i) {
      const c = nameList.charAt(i);
      if (c === '"') {
        inQuote = !inQuote;
      } else if ((c === ',' && !inQuote) || c === '\n') {
        const n = nameList.slice(iStart, i).trim();
        if (n.length) names.push(n);
        iStart = i + 1;
      }
    }
    const n = nameList.slice(iStart).trim();
    if (n.length) names.push(n);
    return names;
  }

  function findEmailInEntry (entry) {
    const tokens = entry.split(/\s+/);
    const emailIndex = tokens.findIndex(t => t.indexOf('@') >= 0);
    return tokens[emailIndex];
  }

  const emailValidator = /.+@.+\..+/;

  return {parseNameList, findEmailInEntry, emailValidator};
});

var utility = require('browser-build').utility
var args = process.argv.slice(2);
utility.spawn("mocha.cmd --harmony -R spec " + args.join(' '));

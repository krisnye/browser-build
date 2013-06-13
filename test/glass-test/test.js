var cp = require("child_process");
var np = require("path");
var args = process.argv.slice(2);
var glassTestModuleId;
try {
    // normal case
    glassTestModuleId = require.resolve('glass-test');
}
catch (e){
    //  testing ourself
    glassTestModuleId = 'lib/index.js';
}

var isWindows = process.platform == 'win32'
var ext = isWindows ? ".cmd" : "";
args = args.map(function(x){return np.normalize('./') + np.relative(np.dirname(glassTestModuleId), x);});
cp.spawn("node" + ext, [glassTestModuleId].concat(args), {stdio:'inherit'});

var make_system_action = function(name) {
    return function() {
        var subprocess = require("subprocess");
        subprocess.check_call("/usr/share/i2pd-ui/bin/i2pbrowser.sh", [name]);
    };
};

exports.enable_proxy = make_system_action("on");
exports.disable_proxy = make_system_action("off");
exports.kill_browser = make_system_action("kill");

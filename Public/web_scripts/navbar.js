// navbar.js

const markActiveNavbarItem = function(code) {
    // active
    var activableMenuItems = docElemByClass("activable")
    const prefixRegex = new RegExp("^http[s]{0,1}:\/\/" + window.location.host, "g");

    var items = Array.prototype.filter.call(activableMenuItems, function(item) {
        // We use the regex to allow relative hrefs
        var pathStr = item.href.replace(prefixRegex, "")

        // Toggle according to the href:
        if (window.location.pathname.startsWith(pathStr)) {
            item.classList.add("active");
        } else {
            item.classList.remove("active");
        }
    });
};

window.onload = function() {
    markActiveNavbarItem();
};
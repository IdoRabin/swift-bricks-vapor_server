// master.js
// MARK: Find elements
function findBestElementForFlashing(element) {
    
    var results = {};
    // console.log("findBestElementForFlashing for element", element.tagName, element.id ?? element.textContent);
    if (isElementBIIcon(element)) {
        results[50] = element;
    } else if (isElementButton(element)) {
        results[60] = element;
    }
    
    // Button
    for (subitem of element.children) {
        if (typeof subitem == 'object') {
            if (isElementBIIcon(subitem)) {
                results[70] = subitem;
            } else if (isElementButton(subitem)) {
                results[80] = subitem;
            }
            
            for (subsubitem of subitem.children) {
                if (typeof subsubitem == 'object') {
                    if (isElementBIIcon(subsubitem)) {
                        results[90] = subsubitem;
                    } else if (isElementButton(subsubitem)) {
                        results[99] = subsubitem;
                    }
                }
            }
        }
    }
    
    var founds = [];
    for (var i = 100;i >= 0; i--) {
        if (results[i]) {
            founds.push(results[i]);
        }
    }
    
    // May return undefined result:
    // console.log('findBestElementForFlashing found ' + founds.length +' items:' , founds);
    return founds[0];
}

function findBIIconForChange(element) {
    //console.log('   findBIIconForChange elem', element.tagName, 'curCName: [' + element.className +']', 'prevCName:[' + element.prevClassIconChange +']');
    
    if (isElementBIIcon(element)) {
        // console.log('    findBIIconForChange base elem was icon', element.tagName);
        return element;
    } else {
        // console.log('   findBIIconForChange ' + element.children.length + ' children');
    }
    
    for (var subitem of element.children) {
        // console.log('    findBIIconForChange subitem: ' + subitem);
        if (typeof subitem == 'object') {
            if (isElementBIIcon(subitem)) {
                return subitem;
            } else {
                for (var subsubitem of subitem.children) {
                    // console.log('    findBIIconForChange subsubitem: ' + subsubitem);
                    if (typeof subsubitem == 'object' && isElementBIIcon(subsubitem)) {
                        return subsubitem;
                    }
                }
            }
        }
    }
}

function isElementBIIcon(elem) {
    if (!elem) {
        // console.log('isElementBIIcon ELEM IS UNDEFINED!');
        return false;
    }
    
    var result = elem.className.split(' ').includes('bi');
    // console.log('      isElementBIIcon ', result, 'elem:[' + elem.tagName + '] cur className:['+ elem.className + ']');
    return (result);
}

function isElementButton(elem) {
    return (elem.tagName == "BUTTON");
}

function getTransitionEndEventName() {
    var existingTransitionKey = "transitionEndEventNameKey";
    var transitionName = sessionStorage.getItem(existingTransitionKey);
    if (transitionName) {
        // Cached
        return transitionName;
    }
    
    var transitions = {
        "transition"      : "transitionend",
        "OTransition"     : "oTransitionEnd",
        "MozTransition"   : "transitionend",
        "WebkitTransition": "webkitTransitionEnd"
    }
    
    let bodyStyle = document.body.style;
    for(let transition in transitions) {
        if(bodyStyle[transition] != undefined) {
            var transitionName = transitions[transition];
            // Save to sesssion cache:
            sessionStorage.setItem(existingTransitionKey, transitionName);
            return transitionName;
        }
    }
}

// MARK: Changes to element properties
function animateBkgColor(element, toCol, onCompletionBlock) {
    // Guard
    if (!element) { return; }
    if (element.isAnimating) { return; }
    
    var transition = window.getComputedStyle(element , null).getPropertyValue('transition');
    
    if (transition && transition.includes('background-color')) {
        // Use the existing transition: (assuming it allows for background-color)
    } else if (element.style.getPropertyValue('transition')) {
        // Use the existing transition: (assuming it allows for background-color)
        //console.log('animateBkgColor element has transition', element.style.getPropertyValue('transition'));
        transition = element.style.getPropertyValue('transition');
    } else if (element.style.cssText.split('transition:').length == 1) {
        // Add the transition now:
        var transitionStr = 'transition: color .15s ease-in-out,background-color .15s ease-in-out,border-color .15s ease-in-out,box-shadow .15s ease-in-out;';
        element.style.cssText += transitionStr;
        transition = window.getComputedStyle(element , null).getPropertyValue('transition');
    }
    
    if (onCompletionBlock) {
        // detect transition end
        var transitionEndEventName = getTransitionEndEventName();
        if (transitionEndEventName) {
            
            // "Once" will remove the listener automatically after one call completes:
            element.addEventListener(transitionEndEventName, ()=>{
                setTimeout(()=>{
                    onCompletionBlock();
                }, 5); // msec
            }, { once: true});
        }
    }
    
    // "Copy to clipboard" icon toggles with checkmark:
    element.style['background-color'] = toCol;
}

function removeElemEventListener(element) {
    var transitionEndEventName = getTransitionEndEventName();
    if (transitionEndEventName && element) {
        element.removeEventListener(transitionEndEventName, element);
    }
}

// MARK: Get element property
function getElementBkgColor(element) {
    return window.getComputedStyle(element ,null).getPropertyValue('background-color');
}

// MARK: Trigger UI / Actions
function animateClipboardCopy(element, isSuccess) {
    if (!element) { return ; }
    
    var elemForColorChange = findBestElementForFlashing(element);
    // We have the elemnt for flashing:
    if (elemForColorChange) {
        // --app-failure-color: #dc3545ff; /* d red */
        // --app-success-color: #19CC54ff; /* d green */
        
        // Color change
        var fromColor = getElementBkgColor(elemForColorChange) ?? "#ffffff00";
        var toColor = isSuccess ? "#66CC66A0" : "#dc3545A0"; // Green / red
        var iconElem = self.findBIIconForChange(element)
        var prevIconName = 'bi-question'; // default
        var newIconName = 'bi-question-circle'; // default
        if (iconElem) {
            prevIconName = iconElem.className.toLowerCase().split(' ').filter((name)=>{ return name.toLowerCase().startsWith('bi-')}).join(' ');
            
            if (iconElem.className.includes('clipboard')) {
                // Clipboard icon (checked / unchecked)
                newIconName = iconElem.className.includes('bi-clipboard-check') ? 'bi-clipboard' : 'bi-clipboard-check';
                
            } else if (iconElem.className.includes('person')) {
                // Person icon (checked / unchecked)
                newIconName = prevClassX.includes('bi-person-check') ? 'bi-person' : 'bi-person-check';
            }
        }
        
        // Icon set:
        if (true || !element.animatingClipboardCopy) {
            element.animatingClipboardCopy = 1;
            element.isAnimating = true;
            
            // Toggle icon:
            iconElem.classList.remove(prevIconName);
            iconElem.classList.add(newIconName);
            
            // Color set
            if (element.animatingClipboardCopy == 1) {
                element.animatingClipboardCopy = 2;
                animateBkgColor(elemForColorChange, toColor, ()=>{
                    // When color set ends:
                    // Color revert
                    if (element.animatingClipboardCopy == 2) {
                        element.animatingClipboardCopy = 3;
                        animateBkgColor(elemForColorChange, fromColor, ()=>{
                            // Icon revert:
                            if (element.animatingClipboardCopy == 3) {
                                
                                iconElem.classList.add(prevIconName);
                                iconElem.classList.remove(newIconName);
                                element.isAnimatingClipboardCopy = undefined;
                                element.isAnimating = undefined;
                                removeElemEventListener(element);
                            }
                        });
                    }
                });
            }
        }
    } else {
        console.error('Failed finding best element for animateClipboardCopy in', elem);
    }
}

function copyTextToClipboard(text, flashElement) {
    // Guards
    if (typeof text !== 'string') { return; }
    
    // Trim / cleanup / sanitize
    text = text.trim();
    if (!text) { return; }
    
    // For different broswers / core kits?
    var permissionNames = ["clipboard-write", "write-on-clipboard"];
    var existingPermissionKey = "copyToClipboardFoundPermission";
    var sessionFoundPermission = sessionStorage.getItem(existingPermissionKey);
    if (sessionFoundPermission) {
        // The correct permission in the array was already found/used once in this session
        permissionNames = [sessionFoundPermission.replace('_', '-')];
    }
    
    var wasSuccess = false
    for (var perm of permissionNames) {
        navigator.permissions.query({ name: perm }).then((result) => {
            /* result is of class PermissionStatus {
             name : "clipboard_write" ...
             onchange : null ..
             state : "granted" ..
             }*/
            if (result.state == "granted" || result.state == "prompt") {
                // Save to local storage
                sessionStorage.setItem(existingPermissionKey, result.name);
                wasSuccess = true;
                
                navigator.clipboard.writeText(text).then(() => {
                    /* Resolved - text copied to clipboard successfully */
                    console.log("permissions.query text copied to clipboard successfully with permission:[", result.name, "] text:\n", text);
                    animateClipboardCopy(flashElement, true);
                },() => {
                    /* Rejected - text failed to copy to the clipboard */
                    console.error("permissions.query text failed to copy");
                    animateClipboardCopy(flashElement, false);
                });
            } else {
                console.error("Copy text feature is available only when server implements https (TLS)");
                
                // If all options have failed:
                if (result.name == permissionNames[permissionNames.length - 1] &&
                    wasSuccess == false) {
                    animateClipboardCopy(flashElement, false);
                }
            }
        });
    }
}

function copyToClipboard(e, flashElement) {
    if (typeof e === 'string') {
        var elemId = e
        let parts = e.split('§'); // seperator
                                  // console.log('master.copyToClipboard parts:', typeof parts, parts.length, parts);
        
        if (parts.length == 1) {
            // Copy provided text directly to clipboard
            // console.log('master.copyToClipboard text:', e);
            copyTextToClipboard(parts[0], flashElement);
        } else if (parts.length >= 2) {
            // Split provided text - and try tp parse a key value pair
            var key = parts[0]; // as string
            var val = parts[1]; // as string
            if (key === "id" && val) {
                // Search for element and copy its text content:
                var elem = document.getElementById(val);
                if (elem) {
                    var content = elem.textContent.trim();
                    
                    if (parts.length >= 4) {
                        var key2 = parts[2]; // as string
                        
                        // "replace:from:to:"
                        if (key2 == "replace" && parts.length >= 5) {
                            var replaceFrom = parts[3]; // as string
                            var replaceTo = parts[4]; // as string
                                                      // console.log('master.copyToClipboard replace', replaceFrom, 'to:', replaceTo);
                            content = content.replaceAll(replaceFrom, replaceTo);
                        }
                    }
                    
                    if (content) {
                        // console.log('master.copyToClipboard text by id:', val, 'content:\n', content);
                        copyTextToClipboard(content, flashElement);
                    }
                }
            }
        }
    } else {
        // Object
        var text = e.textContent.trim();
        // console.log('master.copyToClipboard element textContent:', text);
        if (text) {
            copyTextToClipboard(text, flashElement ?? e);
        } else {
            console.error('master.copyToClipboard NO TEXT CONTENT for element', e, e.textContent);
        }
    }
}


// This requires loading error_codes.js
// MARK: Handle error codes
var AppErrorByCode = {
    "0" : {
        reasonPhrase : "Unknown",
        code : 0,
        key : "http_stt_continue",
    },
}

const getErrorByCode = function(code) {
    if (code >= 0 && code < 65536) {
        return AppErrorByCode[String(code)];
    }
    return undefined;
}

const initAndFlipErrorCodes = function() {
    for (const itemKey in AppErrorCode) {
        let val  = AppErrorCode[itemKey];
        if (val != undefined) {
            let isHttpStatus = val.code >= 100 && val.code < 600;
            val["isHttpStatus"] = isHttpStatus;
            
            AppErrorByCode[String(val.code)] = {
                "reasonPhrase" : val.reasonPhrase,
                "code" : val.code,
                "key" : itemKey,
                "isHttpStatus" : isHttpStatus
            }
        }
    }
    
    // Logs amount of error codes:
    // console.log("AppErrorByCode: " + String(Object.keys(AppErrorCode).length) + " codes")
}

// On init, will flip the error / code map once to get a reversed mapping:
initAndFlipErrorCodes.bind(this);
initAndFlipErrorCodes();

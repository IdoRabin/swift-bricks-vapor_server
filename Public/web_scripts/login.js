// Login.js

// MARK: events
const txtPwd = document.getElementById("password");
const txtUsername = document.getElementById("username");
const chkRememberMe = document.getElementById("rememberme");
const btnSubmit = document.getElementById("submit");
const webForm = document.getElementById("form");

const STORAGE_REMEMBER_ME_KEY = "login/rememberme";
const STORAGE_USERNAME_KEY    = "login/username";

// Users may change this - Note that its also validated on server side.
const minTextSze = 4;
const maxTextSze = 64;

// On loading
const onLoad = function(e) {
    btnSubmit.disabled = true;
    
    var isRememberedMe = localStorage.getItem(STORAGE_REMEMBER_ME_KEY);
    chkRememberMe.checked = isRememberedMe;
    if (isRememberedMe) {
        var loadedUserName = localStorage.getItem(STORAGE_USERNAME_KEY);
        
        // Users may change this - Note that its also validated on server side.
        if (loadedUserName != undefined && loadedUserName.length >= minTextSze && loadedUserName.length <= maxTextSze) {
            // console.log("localStorage.username =", localStorage.username);
            txtUsername.value = loadedUserName;
        }
    }
}
onLoad();

// Various Functions
const isFormValid = function(e) {
    var lenPwd = txtPwd.value.length;
    var lenUser = txtUsername.value.length;
    // Users may change this - Note that its also validated on server side.
    return (lenPwd >= minTextSze && lenUser >= minTextSze) && (lenPwd <= maxTextSze && lenUser <= maxTextSze);
}

const usernameHandler = function(e) {
    //  console.log("usernameHandler", e.target.value);
    validateSubmitButton();
}

const passwordHandler = function(e) {
    // console.log("passwordHandler", e.target.value);
    validateSubmitButton();
}

const validateSubmitButton = function(e) {
    var allow = isFormValid();
    btnSubmit.disabled = !allow;
    // console.log("validateSubmitButton allow", allow);
}

const chkboxHandler = function(e) {
    // console.log("chkboxHandler", e.target.checked)
}

// Replace native "submit" action
const onsubmit = function(e) {
    // Native "submit" action:
    e.preventDefault();
    
    submitHandler(this);
    
    return false;
};

const setUIEnabled = function(isEnabled) {
    txtPwd.disabled = !isEnabled;
    txtUsername.disabled = !isEnabled;
    chkRememberMe.disabled = !isEnabled;
    btnSubmit.disabled = !isEnabled;
    if (isEnabled) {
        document.body.style.cursor = 'default';
    } else {
        document.body.style.cursor = 'wait';
    }
}

const saveStateInStorage = function() {
    // Save to local storage
    localStorage.setItem(STORAGE_REMEMBER_ME_KEY, chkRememberMe.checked);
    if (chkRememberMe.checked) {
        localStorage.setItem(STORAGE_USERNAME_KEY, txtUsername.value);
    } else {
        localStorage.setItem(STORAGE_USERNAME_KEY, "");
    }
}

function updateControlForMessage(inputId, labelId, msg) {
    const input = document.getElementById(inputId);
    const label = document.getElementById(labelId);
    //console.log("updateControlForMessage " + input.id + " label " + label.id + " msg " + msg)
    
    if (input && label) {
        let show = msg.length > 0;
        label.innerText = msg;
        
        // Bootsterap: Change class for display:
        var newClass = input.className;
        if (newClass == undefined) { newClass = ""; }
        if (show && !newClass.includes("is-invalid")) {
            // Show
            newClass += " is-invalid";
        } else if (newClass.includes("is-invalid")) {
            // Hide
            newClass.replace("is-invalid", "");
        }
        // console.log(">>> " + inputId + " classname = [" + input.className + "]");
        input.className = newClass;
    }
}

function updateControlsForMessages(usrname, pwdmsg, general) {
    if (username.length > 0) {
        updateControlForMessage("username", "invalid_username", username);
    }
    if (pwdmsg.length > 0) {
        updateControlForMessage("password", "invalid_password", pwdmsg);
    }
    if (general.length > 0) {
        updateControlForMessage("global_warning", "invalid_global", general);
    }
}

function updateUIForMessage(code, msg) {
    let appError = getErrorByCode(code)

    if (appError == null) {
        updateControlsForMessages("", "", msg ?? AppErrorCode.undefined.reasonPhrase + " | " + code);
    }

    // updateControlsForMessages(usrname, pwdmsg, general)
    console.log("|| code " + code + " message: " + msg)
    switch (appError.key) {
    case AppErrorCode.user_login_failed.code:
            updateControlsForMessages("", "", msg ?? appError.reasonPhrase);
            break;
            
    case AppErrorCode.user_login_failed_no_permission.code:
            updateControlsForMessages("", "", msg ?? appError.reasonPhrase);
            break;
            
    case AppErrorCode.user_login_failed_bad_credentials.code:
            updateControlsForMessages("", "", msg ?? appError.reasonPhrase);
            break;
            
    case AppErrorCode.user_login_failed_permissions_revoked.code:
            updateControlsForMessages("", "", msg ?? appError.reasonPhrase);
            break;
            
    case AppErrorCode.user_login_failed_user_name.code:
            updateControlsForMessages(msg ?? appError.reasonPhrase, "", "");
            break;
            
    case AppErrorCode.user_login_failed_password.code:
            updateControlsForMessages("", msg ?? appError.reasonPhrase, "");
            break;
            
    case AppErrorCode.user_login_failed_name_and_password.code:
            updateControlsForMessages(msg ?? appError.reasonPhrase, msg ?? appError.reasonPhrase, msg ?? appError.reasonPhrase);
            break;
            
    case AppErrorCode.user_login_failed_user_not_found.code:
            updateControlsForMessages("", "", msg ?? appError.reasonPhrase);
            break;
    default:
            updateControlsForMessages("", "", msg ?? appError.reasonPhrase);
            break;
    }
    
    // Re-Enable UI:
    setTimeout(() => {
        setUIEnabled(true);
    }, "250")
    
}

const submitHandler = function(e) {
    e.preventDefault();
    
    if (isFormValid()) {
        // console.log("submitHandler", e.target.value);
        var isAllowBasicAuth = true

        // Diabele UI
        setUIEnabled(false);
        saveStateInStorage();
        
        // Collect "form" data
        data = {
            "username" : txtUsername.value,
            "password" : txtPwd.value,
            "remember_me" : chkRememberMe.checked
        };
        
        var headers = {
            "Content-Type": "application/json",
        }
        if (isAllowBasicAuth) {
            // A kind of basic auth flavor:
            headers["Authorization"] = "Basic" + " " + btoa(data.username + ":" + data.password) // btoa(str) means toBase64(str)
        }

        // Peform the login:
        // POST Url request: (no redirect)
        var statusCode = 200;
        fetch("requestLogin", {
        method: "POST", // or 'PUT'
        headers: headers,
        body: JSON.stringify(data),
        }).then((response) => {
            // console.log('parsed response', response.status)
            statusCode = response.status;
            return response.json();
        }).then(function(json) {
            console.log("json", json);
            updateUIForMessage(statusCode, json["error_reason"]);
        }).catch((ex) => {
            console.log('parsing JSON failed', ex);
            setUIEnabled(true);
        });
    } else {
        console.log("form input was not valid!! ");
    }
}

// Listeners:
txtPwd.addEventListener("input", passwordHandler);
txtUsername.addEventListener("input", usernameHandler);
chkRememberMe.addEventListener("input", chkboxHandler);
btnSubmit.addEventListener("click", submitHandler);

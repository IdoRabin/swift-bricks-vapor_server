// Login.js

// MARK: events
const txtPwd = docElemById("password");
const txtUsername = docElemById("username");
const chkRememberMe = docElemById("rememberme");
const btnSubmit = docElemById("submit");
const webForm = docElemById("form");
const togglePassword = docElemById('togglePassword');

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

const saveLoginResult = function(success, json) {
    /*
     // Expected response (UserSession.Public)
     {
         "start_time": 728330356.491394,
         "start_source": "login",
         "client_redirect" : "/bla/blo/bli", // NOTE: Optional ! when appears, expected to redirect using window.location
         "access_token": {
             "expires_at": 736189156.491081,
             "token": "yKTjh26E5\/q8M31qVakBxQ=="
         },
         "user": {
             "updated_at": 727976219.655946,
             "avatar_url": "\/images\/avatars\/no_avatar.png",
             "display_name": "idorabin",
             "created_at": 727976219.655946,
             "id": "0F30C72C-3047-4305-A9D2-3D1D8D1E97D1"
         }
     }
     */
    if (success) {
        // BEARER TOKEN IS SAVED AS A COOKIE! it is safer NOT to store it in the localstorage
        localStorage.setItem('bearer_token', json["access_token"]["token"]);
        localStorage.setItem('user', json["user"]);
        // expected to have a "Set-Cookie" response header for a cookie named "X-Bricks Server-Cookie"
    } else {
        // "Logout"
        logout()
    }
}

function updateControlForMessage(inputId, labelId, msg) {
    const input = docElemById(inputId);
    const label = docElemById(labelId);
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
        if (msg == "success") { newClass = ""; }
        
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
    case AppErrorCode.http_stt_ok.code:
        updateControlsForMessages("", "", "success");

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

const togglePasswordHandler = function(e) {
    // See: https://www.geeksforgeeks.org/how-to-toggle-password-visibility-in-forms-using-bootstrap-icons/
    // Toggle the type attribute using
    // getAttribure() method
    const type = txtPwd.getAttribute('type') === 'password' ? 'text' : 'password';
    txtPwd.setAttribute('type', type);
    // Toggle the eye and bi-eye icon
    this.classList.toggle('bi-eye');
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
        fetch("login", {
        method: "POST", // or 'PUT'
        headers: headers,
        body: JSON.stringify(data),
        }).then((response) => {
            // console.log('parsed response', response.status)
            statusCode = response.status;
            return response.json();
        }).then(function(json) {
            
            var isSuccess = false;
            if (statusCode == 200 || (statusCode >= 300 && statusCode <= 400)) {
                setUIEnabled(false); // locks UI until redirect?
                isSuccess = true;
            } else {
                updateUIForMessage(statusCode, json["error_reason"]);
                setUIEnabled(true);
            }

            // Save locally the username, user id and user avatar URL:
            saveLoginResult(isSuccess, json)
            console.log("login response json: ", json);
            
            if (json["client_redirect"]) {
                // client_redirect contains the string URL to redirect to
                console.log("will redirect to:" + json["client_redirect"]);
                window.location.href = json["client_redirect"];
            } else {
                // RELOAD?
            }

        }).catch((ex) => {
            console.log('parsing JSON failed', ex);
            updateUIForMessage(statusCode, ex);
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
togglePassword.addEventListener("click", togglePasswordHandler);

//
//  terms.js
//  
//
//  Created by Ido on 06/11/2022.
//

function fetchPageBodyTextAsURIComponent() {
    var div = document.getElementById("terms_document_text_div")
    // var result = div.innerText;
    var result = div.textContent;
    // Cleanup: need to sanitize code from ampersnd and semicolon and double quots
    // Cannot send text inside mailto with colon, equals, ampersend and more
    result = result.replace("<script>", "");
    result = encodeURIComponent(result);
    for (var i=0;i<3;i++) {
        result = result.replaceAll("%09%09%09","%20");
        result = result.replaceAll("%09%09",   "%20");
        result = result.replaceAll("%09",      "%20");
        result = result.replaceAll("%20%20","%20");
    }
    result = result.replaceAll("%0A","%0A%0A");
    result = result.replaceAll("%0A%0A%0A%0A","%0A");
    result = result.replaceAll("%0A%0A%0A","%0A");
    result = result.replaceAll("%0A%0A%20%0A%0A%20","%0A");
    result = result.replace(/[%0A%0A%20;]{0,22}$/,'');
    result = result.replace(/;$/g,'');
    
    return result
}

function sendBodyTextAsEmail() {
    
    // Section 2 of RFC 2368 says that the body field is supposed to be in text/plain format, so you can't do HTML.
    var txt = fetchPageBodyTextAsURIComponent();
    window.location.href = "mailto:?subject=Bricks server terms and conditions&body=" + txt + ";"
}

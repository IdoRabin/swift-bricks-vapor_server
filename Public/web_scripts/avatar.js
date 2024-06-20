const logout = function(e) {
    console.log('LOGOUT CALLED === ');
    localStorage.removeItem['user'];
    localStorage.removeItem['bearer_token'];

    // Clear cookie as well
    cookies.remove('X-Bricks-Server-Cookie', { domain: window.location.hostname});
    cookies.remove('X-Bricks-BTOK-Server-Cookie', { domain: window.location.hostname});
}

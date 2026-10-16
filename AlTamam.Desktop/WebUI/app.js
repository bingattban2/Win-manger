document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;

    // Strict typed JSON request schema: requestId, action, version, payload
    const request = {
        requestId: crypto.randomUUID(),
        action: 'Login',
        version: '1.0',
        payload: { username, password }
    };

    if (window.chrome && window.chrome.webview) {
        window.chrome.webview.postMessage(request);
    } else {
        document.getElementById('message').innerText = 'WebView2 bridge not found. Running outside desktop app?';
    }
});

// Listen for responses
if (window.chrome && window.chrome.webview) {
    window.chrome.webview.addEventListener('message', event => {
        const response = event.data;
        if (!response.success) {
            document.getElementById('message').innerText = response.userMessage || 'حدث خطأ غير معروف';
        } else {
            document.getElementById('message').innerText = 'تم تسجيل الدخول بنجاح';
            document.getElementById('message').style.color = '#2ecc71';
        }
    });
}

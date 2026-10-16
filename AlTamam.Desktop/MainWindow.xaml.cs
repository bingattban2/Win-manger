using System;
using System.IO;
using System.Text.Json;
using System.Windows;
using Microsoft.Web.WebView2.Core;

namespace AlTamam.Desktop;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        InitializeAsync();
    }

    private async void InitializeAsync()
    {
        var userDataFolder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AlTamamAlYawmi", "WebView2");
        var env = await CoreWebView2Environment.CreateAsync(null, userDataFolder);
        await webView.EnsureCoreWebView2Async(env);

        // Map local virtual host
        var webUIPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "WebUI");
        webView.CoreWebView2.SetVirtualHostNameToFolderMapping(
            "app.altamam.local",
            webUIPath,
            CoreWebView2HostResourceAccessKind.Allow);

        // Security restrictions
        webView.CoreWebView2.Settings.AreDevToolsEnabled = false;
        webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
        webView.CoreWebView2.Settings.IsStatusBarEnabled = false;

        webView.CoreWebView2.WebMessageReceived += CoreWebView2_WebMessageReceived;

        webView.Source = new Uri("https://app.altamam.local/index.html");
    }

    private void CoreWebView2_WebMessageReceived(object? sender, CoreWebView2WebMessageReceivedEventArgs e)
    {
        try
        {
            var json = e.TryGetWebMessageAsString();
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            var requestId = root.GetProperty("requestId").GetString();
            var action = root.GetProperty("action").GetString();

            if (action == "Login")
            {
                // Dummy response for Phase 01 structure check
                var response = new
                {
                    requestId,
                    success = false,
                    errorCode = "PHASE01",
                    userMessage = "تم رفض تسجيل الدخول - سيتم بناء الصلاحيات في المرحلة 02"
                };
                webView.CoreWebView2.PostWebMessageAsJson(JsonSerializer.Serialize(response));
            }
        }
        catch (Exception ex)
        {
            var errorResponse = new
            {
                success = false,
                errorCode = "SYSTEM_ERROR",
                userMessage = "خطأ غير متوقع",
                details = ex.Message // Log this instead in production
            };
            webView.CoreWebView2.PostWebMessageAsJson(JsonSerializer.Serialize(errorResponse));
        }
    }
}

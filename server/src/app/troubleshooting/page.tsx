import Link from 'next/link';

export default function TroubleshootingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-4 py-12">
      <div className="max-w-3xl mx-auto">
        <div className="bg-white rounded-lg shadow-xl p-8">
          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-gray-800 mb-2">
              Troubleshooting Guide
            </h1>
            <p className="text-gray-600">
              Common issues and solutions for TypeWise AI authentication
            </p>
          </div>

          {/* Issue 1: App Doesn't Open */}
          <div className="mb-8 pb-8 border-b">
            <h2 className="text-xl font-semibold text-gray-800 mb-3 flex items-center">
              <span className="bg-blue-100 text-blue-800 rounded-full w-8 h-8 flex items-center justify-center mr-3 text-sm font-bold">
                1
              </span>
              App Doesn&apos;t Open After Login
            </h2>
            <div className="ml-11 space-y-4">
              <div>
                <h3 className="font-medium text-gray-700 mb-2">Symptoms:</h3>
                <ul className="list-disc list-inside text-gray-600 space-y-1">
                  <li>Browser shows success message but app stays closed</li>
                  <li>URL changes to &quot;ggapp://auth?token=...&quot; but nothing happens</li>
                </ul>
              </div>
              <div>
                <h3 className="font-medium text-gray-700 mb-2">Solutions:</h3>
                <ol className="list-decimal list-inside text-gray-600 space-y-2">
                  <li>
                    <strong>Check if the app is installed:</strong> Make sure TypeWise AI is properly installed on your Mac.
                  </li>
                  <li>
                    <strong>Open the app manually:</strong> Launch TypeWise AI from your Applications folder, then try signing in again.
                  </li>
                  <li>
                    <strong>Use manual token entry:</strong> Copy the authentication token from the success page and paste it in the app&apos;s settings (if available).
                  </li>
                  <li>
                    <strong>Reinstall the app:</strong> If the issue persists, try uninstalling and reinstalling TypeWise AI.
                  </li>
                </ol>
              </div>
            </div>
          </div>

          {/* Issue 2: Not Authenticated Error */}
          <div className="mb-8 pb-8 border-b">
            <h2 className="text-xl font-semibold text-gray-800 mb-3 flex items-center">
              <span className="bg-blue-100 text-blue-800 rounded-full w-8 h-8 flex items-center justify-center mr-3 text-sm font-bold">
                2
              </span>
              &quot;Not Authenticated&quot; Errors in App
            </h2>
            <div className="ml-11 space-y-4">
              <div>
                <h3 className="font-medium text-gray-700 mb-2">Symptoms:</h3>
                <ul className="list-disc list-inside text-gray-600 space-y-1">
                  <li>App shows &quot;Not authenticated&quot; message</li>
                  <li>AI features are disabled</li>
                </ul>
              </div>
              <div>
                <h3 className="font-medium text-gray-700 mb-2">Solutions:</h3>
                <ol className="list-decimal list-inside text-gray-600 space-y-2">
                  <li>
                    <strong>Check your internet connection:</strong> Make sure you&apos;re connected to the internet.
                  </li>
                  <li>
                    <strong>Verify server URL:</strong> In the app settings, ensure the server URL is correct (default: http://localhost:3000).
                  </li>
                  <li>
                    <strong>Sign in again:</strong> Click the &quot;Sign In&quot; button in the app to re-authenticate.
                  </li>
                  <li>
                    <strong>Check server status:</strong> Make sure the TypeWise AI server is running.
                  </li>
                </ol>
              </div>
            </div>
          </div>

          {/* Issue 3: Token Expired */}
          <div className="mb-8 pb-8 border-b">
            <h2 className="text-xl font-semibold text-gray-800 mb-3 flex items-center">
              <span className="bg-blue-100 text-blue-800 rounded-full w-8 h-8 flex items-center justify-center mr-3 text-sm font-bold">
                3
              </span>
              Token Expired
            </h2>
            <div className="ml-11 space-y-4">
              <div>
                <h3 className="font-medium text-gray-700 mb-2">Symptoms:</h3>
                <ul className="list-disc list-inside text-gray-600 space-y-1">
                  <li>App suddenly shows as unauthenticated</li>
                  <li>Error messages about expired sessions</li>
                </ul>
              </div>
              <div>
                <h3 className="font-medium text-gray-700 mb-2">Solutions:</h3>
                <ol className="list-decimal list-inside text-gray-600 space-y-2">
                  <li>
                    <strong>Sign in again:</strong> Authentication tokens expire after 7 days for security. Simply sign in again to get a new token.
                  </li>
                </ol>
              </div>
            </div>
          </div>

          {/* Issue 4: Server Connection Issues */}
          <div className="mb-8 pb-8 border-b">
            <h2 className="text-xl font-semibold text-gray-800 mb-3 flex items-center">
              <span className="bg-blue-100 text-blue-800 rounded-full w-8 h-8 flex items-center justify-center mr-3 text-sm font-bold">
                4
              </span>
              Server Connection Issues
            </h2>
            <div className="ml-11 space-y-4">
              <div>
                <h3 className="font-medium text-gray-700 mb-2">Symptoms:</h3>
                <ul className="list-disc list-inside text-gray-600 space-y-1">
                  <li>&quot;Cannot connect to server&quot; errors</li>
                  <li>Login page doesn&apos;t load</li>
                  <li>AI requests fail or timeout</li>
                </ul>
              </div>
              <div>
                <h3 className="font-medium text-gray-700 mb-2">Solutions:</h3>
                <ol className="list-decimal list-inside text-gray-600 space-y-2">
                  <li>
                    <strong>Check if server is running:</strong> Make sure the TypeWise AI server is started and running.
                  </li>
                  <li>
                    <strong>Verify server URL:</strong> The default server URL is <code className="bg-gray-100 px-2 py-1 rounded">http://localhost:3000</code>. Check your app settings to confirm.
                  </li>
                  <li>
                    <strong>Check firewall settings:</strong> Ensure your firewall isn&apos;t blocking connections to the server.
                  </li>
                  <li>
                    <strong>Try restarting the server:</strong> Stop and restart the TypeWise AI server.
                  </li>
                </ol>
              </div>
            </div>
          </div>

          {/* Issue 5: For Developers */}
          <div className="mb-8">
            <h2 className="text-xl font-semibold text-gray-800 mb-3 flex items-center">
              <span className="bg-blue-100 text-blue-800 rounded-full w-8 h-8 flex items-center justify-center mr-3 text-sm font-bold">
                5
              </span>
              For Developers: URL Scheme Not Registered
            </h2>
            <div className="ml-11 space-y-4">
              <div>
                <h3 className="font-medium text-gray-700 mb-2">Symptoms:</h3>
                <ul className="list-disc list-inside text-gray-600 space-y-1">
                  <li>Building from source and browser redirect doesn&apos;t work</li>
                  <li>&quot;ggapp://&quot; URLs not recognized</li>
                </ul>
              </div>
              <div>
                <h3 className="font-medium text-gray-700 mb-2">Solutions:</h3>
                <ol className="list-decimal list-inside text-gray-600 space-y-2">
                  <li>
                    <strong>Register URL scheme in Xcode:</strong>
                    <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
                      <li>Open the Xcode project</li>
                      <li>Select the app target</li>
                      <li>Go to the &quot;Info&quot; tab</li>
                      <li>Add a new URL Type with identifier: <code className="bg-gray-100 px-1 rounded">ggapp</code></li>
                      <li>Add URL scheme: <code className="bg-gray-100 px-1 rounded">ggapp</code></li>
                    </ul>
                  </li>
                  <li>
                    <strong>Rebuild the app:</strong> Clean build folder and rebuild the app.
                  </li>
                </ol>
              </div>
            </div>
          </div>

          {/* Get Help Section */}
          <div className="bg-gray-50 rounded-lg p-6 mt-8">
            <h2 className="text-lg font-semibold text-gray-800 mb-3">
              Still Need Help?
            </h2>
            <p className="text-gray-600 mb-4">
              If you&apos;re still experiencing issues after trying these solutions:
            </p>
            <ul className="list-disc list-inside text-gray-600 space-y-2 mb-4">
              <li>Check the server logs for error messages</li>
              <li>Review the app console output for debugging information</li>
              <li>Contact support with details about your issue</li>
            </ul>
            <Link
              href="/login"
              className="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
            >
              Back to Login
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}

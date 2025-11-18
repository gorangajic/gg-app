'use client';

import { useEffect, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import Link from 'next/link';

export default function AuthSuccessPage() {
  const searchParams = useSearchParams();
  const token = searchParams.get('token');
  const [showTroubleshooting, setShowTroubleshooting] = useState(false);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!token) return;

    // Attempt to redirect to the Mac app
    const attemptRedirect = () => {
      window.location.href = `ggapp://auth?token=${encodeURIComponent(token)}`;
    };

    // Try redirect after 500ms
    const redirectTimer = setTimeout(attemptRedirect, 500);

    // Show troubleshooting if still on page after 3 seconds
    const troubleshootingTimer = setTimeout(() => {
      setShowTroubleshooting(true);
    }, 3000);

    return () => {
      clearTimeout(redirectTimer);
      clearTimeout(troubleshootingTimer);
    };
  }, [token]);

  const handleCopyToken = () => {
    if (token) {
      navigator.clipboard.writeText(token);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const handleOpenApp = () => {
    if (token) {
      window.location.href = `ggapp://auth?token=${encodeURIComponent(token)}`;
    }
  };

  if (!token) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
        <div className="bg-white rounded-lg shadow-xl p-8 max-w-md w-full">
          <div className="text-center">
            <div className="text-red-500 text-5xl mb-4">⚠️</div>
            <h1 className="text-2xl font-bold text-gray-800 mb-2">
              Invalid Authentication
            </h1>
            <p className="text-gray-600 mb-6">
              No authentication token was provided. Please try signing in again.
            </p>
            <Link
              href="/login"
              className="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
            >
              Back to Login
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-xl p-8 max-w-md w-full">
        <div className="text-center">
          {/* Success Icon */}
          <div className="inline-flex items-center justify-center w-16 h-16 bg-green-100 rounded-full mb-4">
            <svg
              className="w-10 h-10 text-green-600"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M5 13l4 4L19 7"
              />
            </svg>
          </div>

          <h1 className="text-2xl font-bold text-gray-800 mb-2">
            Authentication Successful!
          </h1>

          {!showTroubleshooting ? (
            <>
              <p className="text-gray-600 mb-4">
                Opening TypeWise AI...
              </p>
              <div className="flex justify-center mb-6">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              </div>
            </>
          ) : (
            <>
              <p className="text-gray-600 mb-6">
                If the app didn&apos;t open automatically, try the options below.
              </p>

              {/* Troubleshooting Options */}
              <div className="space-y-4 mb-6">
                <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-left">
                  <h3 className="font-semibold text-blue-900 mb-2">
                    Option 1: Open App Manually
                  </h3>
                  <p className="text-sm text-blue-800 mb-3">
                    Click the button below to try opening the app again.
                  </p>
                  <button
                    onClick={handleOpenApp}
                    className="w-full bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    Open TypeWise AI
                  </button>
                </div>

                <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 text-left">
                  <h3 className="font-semibold text-yellow-900 mb-2">
                    Option 2: Copy Token
                  </h3>
                  <p className="text-sm text-yellow-800 mb-3">
                    Copy your authentication token and paste it in the app settings.
                  </p>
                  <button
                    onClick={handleCopyToken}
                    className="w-full bg-yellow-600 text-white px-4 py-2 rounded-lg hover:bg-yellow-700 transition-colors"
                  >
                    {copied ? 'Copied!' : 'Copy Token'}
                  </button>
                </div>
              </div>

              {/* Additional Help */}
              <div className="border-t pt-4">
                <p className="text-sm text-gray-600 mb-2">
                  Still having issues?
                </p>
                <Link
                  href="/troubleshooting"
                  className="text-blue-600 hover:text-blue-700 underline text-sm"
                >
                  View Troubleshooting Guide
                </Link>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

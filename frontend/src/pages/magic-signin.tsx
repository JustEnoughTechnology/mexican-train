import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/router';

export default function MagicSigninPage() {
  const router = useRouter();
  const { token } = router.query;
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading');
  const [message, setMessage] = useState('');
  const [user, setUser] = useState<any>(null);

  useEffect(() => {
    if (!token) return;

    const processMagicSignin = async () => {
      try {
        const baseUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8082/api';
        const response = await fetch(`${baseUrl}/auth/magic-signin/${token}`);
        const data = await response.json();

        if (response.ok) {
          setStatus('success');
          setMessage('Successfully signed in!');
          setUser(data.user);

          // Store user data in sessionStorage
          const userHandle = `auth_${data.user.email}`;
          const displayName = data.user.username;
          
          sessionStorage.setItem('userHandle', userHandle);
          sessionStorage.setItem('displayName', displayName);
          sessionStorage.setItem('userType', 'authenticated');
          sessionStorage.setItem('userEmail', data.user.email);

          // Redirect to lobby after a moment
          setTimeout(() => {
            router.push('/lobby');
          }, 2000);
        } else {
          setStatus('error');
          setMessage(data.detail || 'Magic link sign-in failed.');
        }
      } catch (error) {
        console.error('Magic signin error:', error);
        setStatus('error');
        setMessage('Network error. Please try again.');
      }
    };

    processMagicSignin();
  }, [token, router]);

  const handleContinue = () => {
    if (status === 'success') {
      router.push('/lobby');
    } else {
      router.push('/auth?mode=magic-link');
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">🚂 Mexican Train</h1>
          <h2 className="text-xl text-gray-700">Magic Link Sign-in</h2>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md text-center">
          {status === 'loading' && (
            <div>
              <div className="animate-spin rounded-full h-8 w-8 border-2 border-blue-600 border-t-transparent mx-auto mb-4"></div>
              <p className="text-gray-600">Processing your magic link...</p>
            </div>
          )}

          {status === 'success' && (
            <div>
              <svg className="h-12 w-12 text-green-500 mx-auto mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
              <h3 className="text-lg font-medium text-green-800 mb-2">Welcome back!</h3>
              <p className="text-green-700 mb-2">{message}</p>
              {user && (
                <p className="text-sm text-gray-600 mb-6">
                  Signed in as: <span className="font-medium">{user.username}</span>
                </p>
              )}
              <p className="text-sm text-gray-500 mb-6">Redirecting to lobby...</p>
              <button
                onClick={handleContinue}
                className="bg-green-600 text-white px-6 py-2 rounded-lg hover:bg-green-700 transition-colors"
              >
                Continue to Lobby
              </button>
            </div>
          )}

          {status === 'error' && (
            <div>
              <svg className="h-12 w-12 text-red-500 mx-auto mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
              <h3 className="text-lg font-medium text-red-800 mb-2">Sign-in Failed</h3>
              <p className="text-red-700 mb-6">{message}</p>
              <div className="space-x-4">
                <button
                  onClick={handleContinue}
                  className="bg-red-600 text-white px-6 py-2 rounded-lg hover:bg-red-700 transition-colors"
                >
                  Try Again
                </button>
                <button
                  onClick={() => router.push('/')}
                  className="bg-gray-600 text-white px-6 py-2 rounded-lg hover:bg-gray-700 transition-colors"
                >
                  Go Home
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/router';

export default function VerifyEmailPage() {
  const router = useRouter();
  const { token } = router.query;
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading');
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (!token) return;

    const verifyEmail = async () => {
      try {
        const baseUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8082/api';
        const response = await fetch(`${baseUrl}/auth/verify-email/${token}`);
        const data = await response.json();

        if (response.ok) {
          setStatus('success');
          setMessage('Email verified successfully! You can now sign in.');
        } else {
          setStatus('error');
          setMessage(data.detail || 'Email verification failed.');
        }
      } catch (error) {
        console.error('Verification error:', error);
        setStatus('error');
        setMessage('Network error. Please try again.');
      }
    };

    verifyEmail();
  }, [token]);

  const handleContinue = () => {
    if (status === 'success') {
      router.push('/auth?mode=login');
    } else {
      router.push('/auth?mode=register');
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">🚂 Mexican Train</h1>
          <h2 className="text-xl text-gray-700">Email Verification</h2>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md text-center">
          {status === 'loading' && (
            <div>
              <div className="animate-spin rounded-full h-8 w-8 border-2 border-blue-600 border-t-transparent mx-auto mb-4"></div>
              <p className="text-gray-600">Verifying your email...</p>
            </div>
          )}

          {status === 'success' && (
            <div>
              <svg className="h-12 w-12 text-green-500 mx-auto mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
              <h3 className="text-lg font-medium text-green-800 mb-2">Email Verified!</h3>
              <p className="text-green-700 mb-6">{message}</p>
              <button
                onClick={handleContinue}
                className="bg-green-600 text-white px-6 py-2 rounded-lg hover:bg-green-700 transition-colors"
              >
                Continue to Sign In
              </button>
            </div>
          )}

          {status === 'error' && (
            <div>
              <svg className="h-12 w-12 text-red-500 mx-auto mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
              <h3 className="text-lg font-medium text-red-800 mb-2">Verification Failed</h3>
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
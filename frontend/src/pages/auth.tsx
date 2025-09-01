import React, { useState } from 'react';
import { useRouter } from 'next/router';

type AuthMode = 'login' | 'register' | 'magic-link' | 'reset-password';

interface FormData {
  email: string;
  password: string;
  confirmPassword: string;
  username: string;
}

interface FormErrors {
  email?: string;
  password?: string;
  confirmPassword?: string;
  username?: string;
  general?: string;
}

export default function AuthPage() {
  const router = useRouter();
  const [mode, setMode] = useState<AuthMode>('login');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState('');
  const [formData, setFormData] = useState<FormData>({
    email: '',
    password: '',
    confirmPassword: '',
    username: ''
  });
  const [errors, setErrors] = useState<FormErrors>({});

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {};

    // Email validation
    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    }

    // Password validation for login/register
    if ((mode === 'login' || mode === 'register') && !formData.password) {
      newErrors.password = 'Password is required';
    }

    // Additional validation for registration
    if (mode === 'register') {
      if (!formData.username) {
        newErrors.username = 'Username is required';
      } else if (formData.username.length < 2 || formData.username.length > 20) {
        newErrors.username = 'Username must be 2-20 characters';
      } else if (!/^[a-zA-Z0-9_-]+$/.test(formData.username)) {
        newErrors.username = 'Username can only contain letters, numbers, underscores, and dashes';
      }

      if (formData.password.length < 8) {
        newErrors.password = 'Password must be at least 8 characters';
      }

      if (formData.password !== formData.confirmPassword) {
        newErrors.confirmPassword = 'Passwords do not match';
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;

    setLoading(true);
    setErrors({});
    setSuccess('');

    try {
      const baseUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8082/api';
      let endpoint = '';
      let body: any = {};

      switch (mode) {
        case 'register':
          endpoint = '/auth/register';
          body = {
            email: formData.email,
            password: formData.password,
            username: formData.username
          };
          break;
        case 'login':
          endpoint = '/auth/login';
          body = {
            email: formData.email,
            password: formData.password
          };
          break;
        case 'magic-link':
          endpoint = '/auth/magic-link';
          body = { email: formData.email };
          break;
        case 'reset-password':
          endpoint = '/auth/password-reset';
          body = { email: formData.email };
          break;
      }

      const response = await fetch(`${baseUrl}${endpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      const data = await response.json();

      if (!response.ok) {
        if (data.detail) {
          if (typeof data.detail === 'string') {
            setErrors({ general: data.detail });
          } else if (data.detail.message && data.detail.errors) {
            setErrors({ 
              general: data.detail.message,
              password: data.detail.errors.join(', ')
            });
          }
        } else {
          setErrors({ general: 'An error occurred. Please try again.' });
        }
        return;
      }

      // Handle success
      if (mode === 'login') {
        // Store user data and redirect to lobby
        const userHandle = `auth_${data.user.email}`;
        const displayName = data.user.username;
        
        sessionStorage.setItem('userHandle', userHandle);
        sessionStorage.setItem('displayName', displayName);
        sessionStorage.setItem('userType', 'authenticated');
        sessionStorage.setItem('userEmail', data.user.email);
        
        setSuccess('Login successful! Redirecting...');
        setTimeout(() => router.push('/lobby'), 1500);
      } else {
        // Show success message for other actions
        setSuccess(data.message || 'Success! Please check your email.');
        
        if (mode === 'register') {
          // Switch to login mode after successful registration
          setTimeout(() => {
            setMode('login');
            setSuccess('');
            setFormData({ ...formData, password: '', confirmPassword: '' });
          }, 3000);
        }
      }
    } catch (error) {
      console.error('Auth error:', error);
      setErrors({ general: 'Network error. Please check your connection and try again.' });
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setFormData({ email: '', password: '', confirmPassword: '', username: '' });
    setErrors({});
    setSuccess('');
  };

  const switchMode = (newMode: AuthMode) => {
    setMode(newMode);
    resetForm();
  };

  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">🚂 Mexican Train</h1>
          <h2 className="text-xl text-gray-700">
            {mode === 'login' && 'Sign in to your account'}
            {mode === 'register' && 'Create your account'}
            {mode === 'magic-link' && 'Get a magic sign-in link'}
            {mode === 'reset-password' && 'Reset your password'}
          </h2>
        </div>

        {/* Success Message */}
        {success && (
          <div className="bg-green-50 border border-green-200 rounded-lg p-4">
            <div className="flex">
              <svg className="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
              <p className="ml-3 text-sm text-green-700">{success}</p>
            </div>
          </div>
        )}

        {/* Error Message */}
        {errors.general && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <div className="flex">
              <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
              </svg>
              <p className="ml-3 text-sm text-red-700">{errors.general}</p>
            </div>
          </div>
        )}

        {/* Form */}
        <form className="mt-8 space-y-6 bg-white p-6 rounded-lg shadow-md" onSubmit={handleSubmit}>
          <div className="space-y-4">
            {/* Email Field */}
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                Email address
              </label>
              <input
                id="email"
                name="email"
                type="email"
                required
                className={`mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                  errors.email ? 'border-red-300' : 'border-gray-300'
                }`}
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                placeholder="Enter your email"
              />
              {errors.email && <p className="mt-1 text-sm text-red-600">{errors.email}</p>}
            </div>

            {/* Username Field (Register only) */}
            {mode === 'register' && (
              <div>
                <label htmlFor="username" className="block text-sm font-medium text-gray-700">
                  Username
                </label>
                <input
                  id="username"
                  name="username"
                  type="text"
                  required
                  className={`mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                    errors.username ? 'border-red-300' : 'border-gray-300'
                  }`}
                  value={formData.username}
                  onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                  placeholder="Choose a username"
                />
                {errors.username && <p className="mt-1 text-sm text-red-600">{errors.username}</p>}
              </div>
            )}

            {/* Password Field (Login/Register only) */}
            {(mode === 'login' || mode === 'register') && (
              <div>
                <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                  Password
                </label>
                <input
                  id="password"
                  name="password"
                  type="password"
                  required
                  className={`mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                    errors.password ? 'border-red-300' : 'border-gray-300'
                  }`}
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  placeholder="Enter your password"
                />
                {errors.password && <p className="mt-1 text-sm text-red-600">{errors.password}</p>}
                {mode === 'register' && (
                  <p className="mt-1 text-xs text-gray-500">
                    Must be at least 8 characters with uppercase, lowercase, and number
                  </p>
                )}
              </div>
            )}

            {/* Confirm Password Field (Register only) */}
            {mode === 'register' && (
              <div>
                <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700">
                  Confirm Password
                </label>
                <input
                  id="confirmPassword"
                  name="confirmPassword"
                  type="password"
                  required
                  className={`mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 ${
                    errors.confirmPassword ? 'border-red-300' : 'border-gray-300'
                  }`}
                  value={formData.confirmPassword}
                  onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
                  placeholder="Confirm your password"
                />
                {errors.confirmPassword && <p className="mt-1 text-sm text-red-600">{errors.confirmPassword}</p>}
              </div>
            )}
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={loading}
            className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent mr-2"></div>
                Processing...
              </div>
            ) : (
              <>
                {mode === 'login' && 'Sign In'}
                {mode === 'register' && 'Create Account'}
                {mode === 'magic-link' && 'Send Magic Link'}
                {mode === 'reset-password' && 'Send Reset Link'}
              </>
            )}
          </button>
        </form>

        {/* Mode Switcher */}
        <div className="text-center space-y-2">
          {mode === 'login' && (
            <>
              <p className="text-sm text-gray-600">
                Don't have an account?{' '}
                <button
                  onClick={() => switchMode('register')}
                  className="text-blue-600 hover:text-blue-500 font-medium"
                >
                  Sign up
                </button>
              </p>
              <div className="space-x-4 text-sm">
                <button
                  onClick={() => switchMode('magic-link')}
                  className="text-blue-600 hover:text-blue-500"
                >
                  Magic Link Sign-in
                </button>
                <button
                  onClick={() => switchMode('reset-password')}
                  className="text-blue-600 hover:text-blue-500"
                >
                  Forgot Password?
                </button>
              </div>
            </>
          )}
          
          {mode === 'register' && (
            <p className="text-sm text-gray-600">
              Already have an account?{' '}
              <button
                onClick={() => switchMode('login')}
                className="text-blue-600 hover:text-blue-500 font-medium"
              >
                Sign in
              </button>
            </p>
          )}
          
          {(mode === 'magic-link' || mode === 'reset-password') && (
            <p className="text-sm text-gray-600">
              Remember your password?{' '}
              <button
                onClick={() => switchMode('login')}
                className="text-blue-600 hover:text-blue-500 font-medium"
              >
                Sign in
              </button>
            </p>
          )}
          
          <div className="pt-4">
            <button
              onClick={() => router.push('/')}
              className="text-gray-600 hover:text-gray-800 text-sm"
            >
              ← Back to Home
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
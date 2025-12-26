/**
 * Djezzy POS Dashboard - API Helper
 * Handles JWT authentication and API requests
 */

const api = {
    baseUrl: '/api',

    // Get stored access token
    getToken() {
        return localStorage.getItem('access_token');
    },

    // Get stored refresh token
    getRefreshToken() {
        return localStorage.getItem('refresh_token');
    },

    // Store tokens
    setTokens(access, refresh) {
        localStorage.setItem('access_token', access);
        if (refresh) {
            localStorage.setItem('refresh_token', refresh);
        }
    },

    // Clear tokens
    clearTokens() {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
    },

    // Refresh access token
    async refreshToken() {
        const refresh = this.getRefreshToken();
        if (!refresh) {
            return null;
        }

        try {
            const response = await fetch(`${this.baseUrl}/token/refresh/`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ refresh })
            });

            if (response.ok) {
                const data = await response.json();
                this.setTokens(data.access);
                return data.access;
            }
        } catch (e) {
            console.error('Token refresh failed:', e);
        }

        this.clearTokens();
        return null;
    },

    // Get CSRF token from cookie
    getCsrfToken() {
        const name = 'csrftoken';
        let cookieValue = null;
        if (document.cookie && document.cookie !== '') {
            const cookies = document.cookie.split(';');
            for (let i = 0; i < cookies.length; i++) {
                const cookie = cookies[i].trim();
                if (cookie.substring(0, name.length + 1) === (name + '=')) {
                    cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                    break;
                }
            }
        }
        return cookieValue;
    },

    // Main fetch wrapper
    async fetch(url, options = {}) {
        let token = this.getToken();

        const headers = {
            'Content-Type': 'application/json',
            'X-CSRFToken': this.getCsrfToken(),
            ...(token && { 'Authorization': `Bearer ${token}` }),
            ...options.headers
        };

        let response = await fetch(`${this.baseUrl}${url}`, {
            ...options,
            headers,
            credentials: 'same-origin'
        });

        // Handle 401 - try to refresh token
        if (response.status === 401 && token) {
            const newToken = await this.refreshToken();
            if (newToken) {
                headers['Authorization'] = `Bearer ${newToken}`;
                response = await fetch(`${this.baseUrl}${url}`, {
                    ...options,
                    headers,
                    credentials: 'same-origin'
                });
            }
        }

        return response;
    },

    // GET request
    async get(url) {
        const response = await this.fetch(url);
        return response.json();
    },

    // POST request
    async post(url, data) {
        const response = await this.fetch(url, {
            method: 'POST',
            body: JSON.stringify(data)
        });
        return response;
    },

    // PUT request
    async put(url, data) {
        const response = await this.fetch(url, {
            method: 'PUT',
            body: JSON.stringify(data)
        });
        return response;
    },

    // PATCH request
    async patch(url, data) {
        const response = await this.fetch(url, {
            method: 'PATCH',
            body: JSON.stringify(data)
        });
        return response;
    },

    // DELETE request
    async delete(url) {
        const response = await this.fetch(url, {
            method: 'DELETE'
        });
        return response;
    },

    // Login and get tokens
    async login(username, password) {
        try {
            const response = await fetch(`${this.baseUrl}/token/`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password })
            });

            if (response.ok) {
                const data = await response.json();
                this.setTokens(data.access, data.refresh);
                return { success: true };
            } else {
                return { success: false, error: 'Identifiants incorrects' };
            }
        } catch (e) {
            return { success: false, error: 'Erreur de connexion' };
        }
    },

    // Logout
    logout() {
        this.clearTokens();
        window.location.href = '/dashboard/login/';
    }
};

// Utility functions
function formatDate(dateString) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
    });
}

function formatDateTime(dateString) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleDateString('fr-FR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function formatPrice(price, currency = 'DA') {
    return `${Number(price).toLocaleString('fr-FR')} ${currency}`;
}

function formatData(mb) {
    if (mb >= 1024) {
        return `${(mb / 1024).toFixed(0)} Go`;
    }
    return `${mb} Mo`;
}

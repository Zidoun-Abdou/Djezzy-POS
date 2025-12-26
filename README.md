# Djezzy POS

Point of Sale system for Djezzy mobile operator - managing telecom offers, phone number assignments, and customer contracts.

## Project Structure

```
Djezzy-POS/
├── backend/     # Django REST API
├── mobile/      # Flutter mobile application
└── README.md
```

## Backend (Django)

### Features
- User authentication with JWT tokens
- Offer management (mobile plans)
- Phone number inventory management
- Contract creation and management
- Admin interface for data management

### Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

### API Endpoints
- `POST /api/token/` - Login
- `POST /api/token/refresh/` - Refresh token
- `GET /api/user/me/` - Current user info
- `GET /api/offers/` - List offers
- `GET /api/offers/active/` - Active offers with phone numbers
- `GET /api/phone-numbers/available/` - Available phone numbers
- `POST /api/contracts/` - Create contract
- `GET /admin/` - Admin interface

## Mobile (Flutter)

### Features
- Agent login
- Offer selection
- Phone number selection
- ID card scanning (MRZ + NFC)
- Digital signature capture
- Contract PDF generation
- Email submission

### Setup
```bash
cd mobile
flutter pub get
flutter run
```

## Tech Stack

### Backend
- Django 4.2+
- Django REST Framework
- SimpleJWT for authentication
- PostgreSQL (production)

### Mobile
- Flutter 3.x
- camera, signature, pdf packages
- NFC/MRZ reading capabilities

## License
Proprietary - Djezzy

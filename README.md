# Djezzy POS

Point of Sale system for Djezzy mobile operator - managing telecom offers, phone number assignments, and customer contracts.

## Project Structure

```
Djezzy-POS/
├── backend/     # Django REST API + Web Dashboard
├── mobile/      # Flutter mobile application
└── README.md
```

## Backend (Django)

### Features
- User authentication with JWT tokens
- Role-based access control (Admin / Agent Commercial)
- Offer management (mobile plans)
- Phone number inventory management
- Contract creation and management
- PDF contract generation with Arabic support
- Admin dashboard with comprehensive statistics
- Agent dashboard with performance charts (Chart.js)

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
- `GET /api/contracts/{id}/pdf/` - Download contract PDF
- `GET /api/contracts/my-stats/` - Agent performance statistics
- `GET /admin/` - Admin interface

### Web Dashboard
- **Admin Dashboard**: Full statistics (Users, Offers, Numbers, Contracts) + status overview + management
- **Agent Dashboard**: Personal stats + performance charts:
  - Sales performance (7-day line chart)
  - Available numbers (donut chart)
  - Top offers sold (bar chart)

## Mobile (Flutter)

### Features
- Agent login with JWT authentication
- Offer selection with pricing details
- Phone number selection from available inventory
- ID card scanning:
  - MRZ (Machine Readable Zone) camera scanning
  - NFC chip reading with local decoding (offline)
- Personal data extraction (names, NIN, birth date, address)
- Digital signature capture
- Contract PDF generation with Arabic support
- PDF download from sales history
- Email submission

### Setup
```bash
cd mobile
flutter pub get
flutter run
```

### Key Components
- **MRZ Scanner**: Camera-based ID card text recognition
- **NFC Reader**: Reads Algerian ID card chips with local DatagroupDecoder:
  - DG2: Face photo extraction (JPEG/JP2)
  - DG7: Signature image extraction
  - DG11: Personal data (Arabic ISO-8859-6)
  - DG12: Document data (daira, baladia, dates)
- **PDF Generator**: Creates bilingual contracts with Djezzy branding
- **Sales History**: View and download past contracts as PDF

## Tech Stack

### Backend
- Django 4.2+
- Django REST Framework
- SimpleJWT for authentication
- ReportLab for PDF generation
- arabic-reshaper + python-bidi for Arabic text
- Chart.js for dashboard visualizations
- PostgreSQL (production) / SQLite (development)

### Mobile
- Flutter 3.x
- camera, signature_pad packages
- NFC reading with local decoding
- PDF generation with printing package
- url_launcher, open_filex for PDF viewing

## User Roles

### Administrateur (Admin)
- Full access to all features
- Manage users, offers, phone numbers
- View all statistics and reports
- Change phone number statuses

### Agent Commercial
- View active offers
- Select phone numbers for contracts
- Scan customer ID cards
- Create and sign contracts
- View personal sales history
- Download contract PDFs

## License
Proprietary - Djezzy

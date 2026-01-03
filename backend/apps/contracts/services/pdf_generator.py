"""
PDF Generator Service for Djezzy POS Contracts.
Generates PDF contracts matching the mobile app design.
"""
import io
import base64
from pathlib import Path
from datetime import datetime

from django.conf import settings
from django.core.files.base import ContentFile

from reportlab.lib.pagesizes import A4
from reportlab.lib.colors import HexColor, white, black
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.utils import ImageReader
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import Paragraph
from reportlab.lib.enums import TA_JUSTIFY

from PIL import Image

try:
    import arabic_reshaper
    from bidi.algorithm import get_display
    ARABIC_SUPPORT = True
except ImportError:
    ARABIC_SUPPORT = False


class ContractPDFGenerator:
    """Generate PDF contracts matching mobile app design."""

    # Djezzy brand colors
    DJEZZY_RED = HexColor('#ED1C24')
    DJEZZY_DARK = HexColor('#C41820')
    LIGHT_GRAY = HexColor('#F5F5F5')
    BORDER_GRAY = HexColor('#CCCCCC')
    TEXT_GRAY = HexColor('#666666')
    LIGHT_RED = HexColor('#FFF5F5')
    LIGHT_GREEN = HexColor('#E8F5E9')
    GREEN_TEXT = HexColor('#2E7D32')

    def __init__(self, contract):
        self.contract = contract
        self.width, self.height = A4
        self._register_fonts()

    def _register_fonts(self):
        """Register Arabic font for RTL text."""
        try:
            # Try multiple possible font locations
            font_paths = [
                Path(settings.BASE_DIR) / 'static' / 'fonts' / 'Amiri-Regular.ttf',
                Path(settings.STATICFILES_DIRS[0]) / 'fonts' / 'Amiri-Regular.ttf' if settings.STATICFILES_DIRS else None,
            ]

            for font_path in font_paths:
                if font_path and font_path.exists():
                    pdfmetrics.registerFont(TTFont('Amiri', str(font_path)))
                    self.arabic_font = 'Amiri'
                    return

            self.arabic_font = 'Helvetica'
        except Exception:
            self.arabic_font = 'Helvetica'

    def _reshape_arabic(self, text):
        """Reshape Arabic text for proper display."""
        if not text or not ARABIC_SUPPORT:
            return text or ''
        try:
            reshaped = arabic_reshaper.reshape(text)
            return get_display(reshaped)
        except Exception:
            return text

    def _load_logo(self):
        """Load Djezzy logo image."""
        try:
            logo_paths = [
                Path(settings.BASE_DIR) / 'static' / 'dashboard' / 'images' / 'djezzy_logo.png',
                Path(settings.STATICFILES_DIRS[0]) / 'dashboard' / 'images' / 'djezzy_logo.png' if settings.STATICFILES_DIRS else None,
            ]

            for logo_path in logo_paths:
                if logo_path and logo_path.exists():
                    return ImageReader(str(logo_path))
            return None
        except Exception:
            return None

    def _load_customer_photo(self):
        """Load customer photo from contract."""
        try:
            if self.contract.customer_photo and self.contract.customer_photo.name:
                return ImageReader(self.contract.customer_photo.path)
            return None
        except Exception:
            return None

    def _load_signature(self):
        """Load signature from base64."""
        try:
            if self.contract.signature_base64:
                # Remove data URL prefix if present
                sig_data = self.contract.signature_base64
                if ',' in sig_data:
                    sig_data = sig_data.split(',')[1]

                sig_bytes = base64.b64decode(sig_data)
                sig_io = io.BytesIO(sig_bytes)
                return ImageReader(sig_io)
            return None
        except Exception:
            return None

    def generate(self):
        """Generate PDF and return bytes."""
        buffer = io.BytesIO()
        c = canvas.Canvas(buffer, pagesize=A4)

        # Start drawing from top
        y_position = self.height - 40

        # Draw sections
        y_position = self._draw_header(c, y_position)
        y_position -= 30
        y_position = self._draw_client_info(c, y_position)
        y_position -= 25
        y_position = self._draw_offer_section(c, y_position)
        y_position -= 25
        y_position = self._draw_terms(c, y_position)
        y_position -= 30
        y_position = self._draw_signature(c, y_position)

        c.save()
        buffer.seek(0)
        return buffer.getvalue()

    def _draw_header(self, c, y):
        """Draw header with logo and contract info."""
        x = 40
        box_width = self.width - 80
        box_height = 80

        # Red background
        c.setFillColor(self.DJEZZY_RED)
        c.roundRect(x, y - box_height, box_width, box_height, 8, fill=1, stroke=0)

        # Logo
        logo = self._load_logo()
        if logo:
            c.drawImage(logo, x + 20, y - 55, width=100, height=35, preserveAspectRatio=True, mask='auto')
        else:
            c.setFillColor(white)
            c.setFont('Helvetica-Bold', 24)
            c.drawString(x + 20, y - 45, 'DJEZZY')

        # Contract title
        c.setFillColor(white)
        c.setFont('Helvetica-Bold', 14)
        c.drawString(x + 20, y - 70, "CONTRAT D'ABONNEMENT")

        # Contract number and date (right side)
        c.setFont('Helvetica', 10)
        c.drawRightString(x + box_width - 20, y - 40, f"N: {self.contract.contract_number}")
        formatted_date = self.contract.created_at.strftime('%d/%m/%Y') if self.contract.created_at else '-'
        c.drawRightString(x + box_width - 20, y - 55, f"Date: {formatted_date}")

        return y - box_height

    def _draw_section_title(self, c, y, title):
        """Draw section title with red background."""
        x = 40
        c.setFillColor(self.DJEZZY_RED)
        c.roundRect(x, y - 20, 180, 24, 4, fill=1, stroke=0)
        c.setFillColor(white)
        c.setFont('Helvetica-Bold', 11)
        c.drawString(x + 10, y - 14, title)
        return y - 30

    def _draw_client_info(self, c, y):
        """Draw client information section with photo."""
        y = self._draw_section_title(c, y, 'INFORMATIONS CLIENT')
        y -= 10

        x = 40
        box_width = self.width - 80
        box_height = 220

        # Border box
        c.setStrokeColor(self.BORDER_GRAY)
        c.setLineWidth(1)
        c.roundRect(x, y - box_height, box_width, box_height, 8, fill=0, stroke=1)

        # Customer photo
        photo = self._load_customer_photo()
        photo_x = x + 16
        photo_y = y - 116
        photo_w = 70
        photo_h = 90

        if photo:
            # Red border around photo
            c.setStrokeColor(self.DJEZZY_RED)
            c.setLineWidth(2)
            c.rect(photo_x - 2, photo_y - 2, photo_w + 4, photo_h + 4, fill=0, stroke=1)
            c.drawImage(photo, photo_x, photo_y, width=photo_w, height=photo_h, preserveAspectRatio=True, mask='auto')
        else:
            # Placeholder
            c.setFillColor(self.LIGHT_GRAY)
            c.setStrokeColor(self.BORDER_GRAY)
            c.setLineWidth(1)
            c.rect(photo_x, photo_y, photo_w, photo_h, fill=1, stroke=1)
            c.setFillColor(self.TEXT_GRAY)
            c.setFont('Helvetica', 9)
            c.drawCentredString(photo_x + photo_w/2, photo_y + photo_h/2, 'Photo')

        # Client info (right of photo)
        info_x = photo_x + photo_w + 20
        info_y = y - 20
        line_height = 14

        # Personal info rows
        info_rows = [
            ('Nom', self.contract.customer_last_name or '-'),
            ('Prenom', self.contract.customer_first_name or '-'),
        ]

        # Arabic names (if available)
        if self.contract.customer_last_name_ar:
            info_rows.append(('Nom (Arabe)', self._reshape_arabic(self.contract.customer_last_name_ar)))
        if self.contract.customer_first_name_ar:
            info_rows.append(('Prenom (Arabe)', self._reshape_arabic(self.contract.customer_first_name_ar)))

        # Draw divider
        info_rows.append(('---DIVIDER---', ''))

        # More info
        birth_date = self.contract.customer_birth_date.strftime('%d/%m/%Y') if self.contract.customer_birth_date else '-'
        info_rows.extend([
            ('Date de naissance', birth_date),
            ('Lieu de naissance', self.contract.customer_birth_place or '-'),
            ('Sexe', self.contract.customer_sex or '-'),
        ])

        info_rows.append(('---DIVIDER---', ''))

        # ID info
        id_expiry = self.contract.customer_id_expiry.strftime('%d/%m/%Y') if self.contract.customer_id_expiry else '-'
        info_rows.extend([
            ('N Carte d\'identite', self.contract.customer_id_number or '-'),
            ('NIN', self.contract.customer_nin or '-'),
            ('Daira', self.contract.customer_daira or '-'),
            ('Baladia', self.contract.customer_baladia or '-'),
            ('Date d\'expiration CNI', id_expiry),
        ])

        for label, value in info_rows:
            if label == '---DIVIDER---':
                c.setStrokeColor(HexColor('#EEEEEE'))
                c.setLineWidth(0.5)
                c.line(info_x, info_y - 5, x + box_width - 20, info_y - 5)
                info_y -= 10
            else:
                c.setFillColor(self.TEXT_GRAY)
                c.setFont('Helvetica-Bold', 9)
                c.drawString(info_x, info_y, label)

                # Use Arabic font for Arabic text
                if 'Arabe' in label and self.arabic_font == 'Amiri':
                    c.setFont(self.arabic_font, 9)
                else:
                    c.setFont('Helvetica', 9)
                c.setFillColor(black)
                c.drawString(info_x + 120, info_y, str(value))
                info_y -= line_height

        return y - box_height

    def _draw_offer_section(self, c, y):
        """Draw offer details section."""
        y = self._draw_section_title(c, y, 'OFFRE SELECTIONNEE')
        y -= 10

        x = 40
        box_width = self.width - 80
        box_height = 120

        # Light red background
        c.setFillColor(self.LIGHT_RED)
        c.setStrokeColor(self.DJEZZY_RED)
        c.setLineWidth(1)
        c.roundRect(x, y - box_height, box_width, box_height, 8, fill=1, stroke=1)

        # Offer name and price
        offer = self.contract.offer
        c.setFillColor(self.DJEZZY_RED)
        c.setFont('Helvetica-Bold', 16)
        c.drawString(x + 16, y - 25, offer.name)
        c.drawRightString(x + box_width - 16, y - 25, f"{offer.price} DZD")

        # Phone number
        phone = self.contract.phone_number
        info_y = y - 50
        line_height = 16

        offer_info = [
            ('Numero attribue', phone.formatted_number if phone else '-'),
            ('Internet', f"{offer.data_amount} Go" if offer.data_amount else '-'),
            ('Validite', f"{offer.validity_days} jours" if offer.validity_days else '-'),
        ]

        if offer.voice_minutes:
            offer_info.append(('Appels', f"{offer.voice_minutes} min"))
        if offer.sms_count:
            offer_info.append(('SMS', f"{offer.sms_count} SMS"))

        for label, value in offer_info:
            c.setFillColor(black)
            c.setFont('Helvetica', 10)
            c.drawString(x + 16, info_y, label)
            c.setFont('Helvetica-Bold', 10)
            c.drawRightString(x + box_width - 16, info_y, str(value))
            info_y -= line_height

        return y - box_height

    def _draw_terms(self, c, y):
        """Draw terms and conditions section."""
        y = self._draw_section_title(c, y, 'CONDITIONS GENERALES')
        y -= 10

        x = 40
        box_width = self.width - 80
        box_height = 60

        # Gray background
        c.setFillColor(self.LIGHT_GRAY)
        c.roundRect(x, y - box_height, box_width, box_height, 4, fill=1, stroke=0)

        # Terms text
        terms_text = (
            "En signant ce contrat, le client accepte les conditions generales d'utilisation "
            "des services Djezzy. Le client certifie que les informations fournies sont "
            "exactes et s'engage a respecter les termes du contrat. Djezzy se reserve le "
            "droit de suspendre ou resilier le service en cas de non-respect des conditions. "
            "Pour toute reclamation, veuillez contacter le service client au 777."
        )

        c.setFillColor(HexColor('#555555'))
        c.setFont('Helvetica', 8)

        # Split text into lines that fit
        text_x = x + 12
        text_y = y - 15
        max_width = box_width - 24
        words = terms_text.split()
        lines = []
        current_line = []

        for word in words:
            current_line.append(word)
            if c.stringWidth(' '.join(current_line), 'Helvetica', 8) > max_width:
                current_line.pop()
                lines.append(' '.join(current_line))
                current_line = [word]

        if current_line:
            lines.append(' '.join(current_line))

        for line in lines[:5]:  # Max 5 lines
            c.drawString(text_x, text_y, line)
            text_y -= 10

        return y - box_height

    def _draw_signature(self, c, y):
        """Draw signature section."""
        x = 40
        box_width = self.width - 80
        box_height = 100

        # Border box
        c.setStrokeColor(self.BORDER_GRAY)
        c.setLineWidth(1)
        c.roundRect(x, y - box_height, box_width, box_height, 8, fill=0, stroke=1)

        # Title
        c.setFillColor(black)
        c.setFont('Helvetica-Bold', 11)
        c.drawString(x + 16, y - 20, 'SIGNATURE DU CLIENT')

        # Signature image box
        sig_x = x + 16
        sig_y = y - 85
        sig_w = 160
        sig_h = 55

        c.setStrokeColor(self.BORDER_GRAY)
        c.setFillColor(white)
        c.roundRect(sig_x, sig_y, sig_w, sig_h, 4, fill=1, stroke=1)

        # Draw signature if available
        signature = self._load_signature()
        if signature:
            c.drawImage(signature, sig_x + 5, sig_y + 5, width=sig_w - 10, height=sig_h - 10, preserveAspectRatio=True, mask='auto')
        else:
            c.setFillColor(self.TEXT_GRAY)
            c.setFont('Helvetica', 9)
            c.drawCentredString(sig_x + sig_w/2, sig_y + sig_h/2, '[Signature]')

        # Customer name and date
        info_x = sig_x + sig_w + 20
        c.setFillColor(black)
        c.setFont('Helvetica-Bold', 10)
        c.drawString(info_x, y - 45, self.contract.customer_full_name)

        c.setFont('Helvetica', 9)
        formatted_date = self.contract.created_at.strftime('%d/%m/%Y') if self.contract.created_at else '-'
        c.drawString(info_x, y - 60, f"Date: {formatted_date}")

        # Confirmation box
        confirm_x = info_x
        confirm_y = y - 90
        confirm_w = box_width - sig_w - 60
        confirm_h = 25

        c.setFillColor(self.LIGHT_GREEN)
        c.roundRect(confirm_x, confirm_y, confirm_w, confirm_h, 4, fill=1, stroke=0)

        c.setFillColor(self.GREEN_TEXT)
        c.setFont('Helvetica', 7)
        c.drawString(confirm_x + 8, confirm_y + 10, "Je confirme que c'est ma carte d'identite nationale")

        return y - box_height

    def save_to_contract(self):
        """Generate PDF and save to contract's pdf_file field."""
        pdf_bytes = self.generate()
        filename = f"contrat_{self.contract.contract_number}.pdf"
        self.contract.pdf_file.save(
            filename,
            ContentFile(pdf_bytes),
            save=True
        )
        return self.contract.pdf_file

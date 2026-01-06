"""
PDF Generator Service for Djezzy POS Contracts.
Generates PDF contracts matching the mobile app design using Platypus.
"""
import io
import base64
from pathlib import Path

from django.conf import settings
from django.core.files.base import ContentFile

from reportlab.lib.pagesizes import A4
from reportlab.lib.colors import HexColor, white, black
from reportlab.lib.units import mm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_RIGHT, TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    Image as RLImage, KeepTogether, HRFlowable
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

from PIL import Image as PILImage

try:
    import arabic_reshaper
    from bidi.algorithm import get_display
    ARABIC_SUPPORT = True
except ImportError:
    ARABIC_SUPPORT = False


class ContractPDFGenerator:
    """Generate PDF contracts matching mobile app design using Platypus."""

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
        self._setup_styles()

    def _register_fonts(self):
        """Register Arabic font for RTL text."""
        self.arabic_font = 'Helvetica'
        try:
            font_paths = [
                Path(settings.BASE_DIR) / 'static' / 'fonts' / 'Amiri-Regular.ttf',
                Path(settings.STATICFILES_DIRS[0]) / 'fonts' / 'Amiri-Regular.ttf' if settings.STATICFILES_DIRS else None,
            ]
            for font_path in font_paths:
                if font_path and font_path.exists():
                    pdfmetrics.registerFont(TTFont('Amiri', str(font_path)))
                    self.arabic_font = 'Amiri'
                    return
        except Exception:
            pass

    def _setup_styles(self):
        """Setup paragraph styles."""
        self.styles = getSampleStyleSheet()

        # Header title style
        self.styles.add(ParagraphStyle(
            name='HeaderTitle',
            fontName='Helvetica-Bold',
            fontSize=16,
            textColor=white,
            spaceAfter=8,
        ))

        # Section title style
        self.styles.add(ParagraphStyle(
            name='SectionTitle',
            fontName='Helvetica-Bold',
            fontSize=12,
            textColor=white,
            spaceBefore=0,
            spaceAfter=0,
        ))

        # Info label style
        self.styles.add(ParagraphStyle(
            name='InfoLabel',
            fontName='Helvetica-Bold',
            fontSize=9,
            textColor=self.TEXT_GRAY,
        ))

        # Info value style
        self.styles.add(ParagraphStyle(
            name='InfoValue',
            fontName='Helvetica',
            fontSize=9,
            textColor=black,
        ))

        # Arabic info value style (uses Amiri font for Arabic text)
        self.styles.add(ParagraphStyle(
            name='InfoValueArabic',
            fontName=self.arabic_font,
            fontSize=9,
            textColor=black,
        ))

        # Offer title style
        self.styles.add(ParagraphStyle(
            name='OfferTitle',
            fontName='Helvetica-Bold',
            fontSize=16,
            textColor=self.DJEZZY_RED,
        ))

        # Terms text style
        self.styles.add(ParagraphStyle(
            name='TermsText',
            fontName='Helvetica',
            fontSize=9,
            textColor=HexColor('#555555'),
            alignment=TA_JUSTIFY,
            leading=12,
        ))

        # Feature bullet style
        self.styles.add(ParagraphStyle(
            name='FeatureBullet',
            fontName='Helvetica',
            fontSize=9,
            textColor=black,
            leftIndent=15,
            bulletIndent=5,
        ))

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
                    return str(logo_path)
            return None
        except Exception:
            return None

    def _load_customer_photo(self):
        """Load customer photo from contract."""
        try:
            if self.contract.customer_photo and self.contract.customer_photo.name:
                return self.contract.customer_photo.path
            return None
        except Exception:
            return None

    def _load_signature(self):
        """Load signature from base64."""
        try:
            if self.contract.signature_base64:
                sig_data = self.contract.signature_base64
                if ',' in sig_data:
                    sig_data = sig_data.split(',')[1]
                sig_bytes = base64.b64decode(sig_data)
                sig_io = io.BytesIO(sig_bytes)
                return sig_io
            return None
        except Exception:
            return None

    def generate(self):
        """Generate PDF and return bytes."""
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            rightMargin=40,
            leftMargin=40,
            topMargin=40,
            bottomMargin=40,
        )

        # Build document elements
        elements = []

        # Header
        elements.append(self._build_header())
        elements.append(Spacer(1, 25))

        # Client Information Section
        elements.append(self._build_section_title('INFORMATIONS CLIENT'))
        elements.append(Spacer(1, 10))
        elements.append(self._build_client_info())
        elements.append(Spacer(1, 15))

        # Contact Information Section
        elements.append(self._build_section_title('COORDONNEES'))
        elements.append(Spacer(1, 10))
        elements.append(self._build_contact_section())
        elements.append(Spacer(1, 25))

        # Offer Section
        elements.append(self._build_section_title('OFFRE SELECTIONNEE'))
        elements.append(Spacer(1, 10))
        elements.append(self._build_offer_section())
        elements.append(Spacer(1, 25))

        # Terms Section
        elements.append(self._build_section_title('CONDITIONS GENERALES'))
        elements.append(Spacer(1, 10))
        elements.append(self._build_terms_section())
        elements.append(Spacer(1, 25))

        # Signature Section
        elements.append(self._build_signature_section())

        doc.build(elements)
        buffer.seek(0)
        return buffer.getvalue()

    def _build_header(self):
        """Build header with logo and contract info."""
        logo_path = self._load_logo()

        # Contract info
        contract_number = self.contract.contract_number
        formatted_date = self.contract.created_at.strftime('%d/%m/%Y') if self.contract.created_at else '-'

        # Header content
        if logo_path:
            logo = RLImage(logo_path, width=100, height=35)
        else:
            logo = Paragraph('<b>DJEZZY</b>', ParagraphStyle(
                'LogoText', fontName='Helvetica-Bold', fontSize=24, textColor=white
            ))

        title = Paragraph("CONTRAT D'ABONNEMENT", self.styles['HeaderTitle'])

        info_style = ParagraphStyle('HeaderInfo', fontName='Helvetica', fontSize=10, textColor=white, alignment=TA_RIGHT)
        contract_info = Paragraph(f"N: {contract_number}<br/>Date: {formatted_date}", info_style)

        # Create header table
        header_data = [[
            [logo, title],
            contract_info
        ]]

        header_table = Table(header_data, colWidths=[350, 150])
        header_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), self.DJEZZY_RED),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('LEFTPADDING', (0, 0), (-1, -1), 20),
            ('RIGHTPADDING', (0, 0), (-1, -1), 20),
            ('TOPPADDING', (0, 0), (-1, -1), 15),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 15),
            ('ROUNDEDCORNERS', [8, 8, 8, 8]),
        ]))

        return header_table

    def _build_section_title(self, title):
        """Build section title with red background."""
        title_para = Paragraph(title, self.styles['SectionTitle'])

        title_table = Table([[title_para]], colWidths=[180])
        title_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), self.DJEZZY_RED),
            ('LEFTPADDING', (0, 0), (-1, -1), 12),
            ('RIGHTPADDING', (0, 0), (-1, -1), 12),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('ROUNDEDCORNERS', [4, 4, 4, 4]),
        ]))

        return title_table

    def _build_client_info(self):
        """Build client information section with photo."""
        # Customer photo
        photo_path = self._load_customer_photo()
        if photo_path:
            try:
                photo = RLImage(photo_path, width=70, height=90)
            except:
                photo = Paragraph('<b>Photo</b>', ParagraphStyle('PhotoPlaceholder',
                    fontName='Helvetica', fontSize=9, textColor=self.TEXT_GRAY, alignment=TA_CENTER))
        else:
            photo = Paragraph('<b>Photo</b>', ParagraphStyle('PhotoPlaceholder',
                fontName='Helvetica', fontSize=9, textColor=self.TEXT_GRAY, alignment=TA_CENTER))

        # Build info rows
        info_rows = []

        # Personal info
        info_rows.append(self._info_row('Nom', self.contract.customer_last_name or '-'))
        info_rows.append(self._info_row('Prenom', self.contract.customer_first_name or '-'))

        if self.contract.customer_last_name_ar:
            info_rows.append(self._info_row('Nom (Arabe)', self._reshape_arabic(self.contract.customer_last_name_ar), is_arabic=True))
        if self.contract.customer_first_name_ar:
            info_rows.append(self._info_row('Prenom (Arabe)', self._reshape_arabic(self.contract.customer_first_name_ar), is_arabic=True))

        # Divider
        info_rows.append([HRFlowable(width='100%', thickness=0.5, color=HexColor('#EEEEEE'))])

        # Birth info
        birth_date = self.contract.customer_birth_date.strftime('%d/%m/%Y') if self.contract.customer_birth_date else '-'
        info_rows.append(self._info_row('Date de naissance', birth_date))
        info_rows.append(self._info_row('Lieu de naissance', self.contract.customer_birth_place or '-'))
        if self.contract.customer_birth_place_ar:
            info_rows.append(self._info_row('Lieu (Arabe)', self._reshape_arabic(self.contract.customer_birth_place_ar), is_arabic=True))
        info_rows.append(self._info_row('Sexe', self.contract.customer_sex or '-'))
        if self.contract.customer_blood_type:
            info_rows.append(self._info_row('Groupe sanguin', self.contract.customer_blood_type))

        # Divider
        info_rows.append([HRFlowable(width='100%', thickness=0.5, color=HexColor('#EEEEEE'))])

        # ID info
        id_expiry = self.contract.customer_id_expiry.strftime('%d/%m/%Y') if self.contract.customer_id_expiry else '-'
        info_rows.append(self._info_row("N Carte d'identite", self.contract.customer_id_number or '-'))
        info_rows.append(self._info_row('NIN', self.contract.customer_nin or '-'))
        info_rows.append(self._info_row('Daira', self.contract.customer_daira or '-'))
        info_rows.append(self._info_row('Baladia', self.contract.customer_baladia or '-'))
        info_rows.append(self._info_row("Date d'expiration CNI", id_expiry))

        # Info table
        info_table = Table(info_rows, colWidths=[120, 280])
        info_table.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('TOPPADDING', (0, 0), (-1, -1), 3),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ]))

        # Photo cell with border
        photo_table = Table([[photo]], colWidths=[74])
        photo_table.setStyle(TableStyle([
            ('BOX', (0, 0), (-1, -1), 2, self.DJEZZY_RED),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('TOPPADDING', (0, 0), (-1, -1), 2),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
        ]))

        # Main layout table
        main_data = [[photo_table, info_table]]
        main_table = Table(main_data, colWidths=[90, 410])
        main_table.setStyle(TableStyle([
            ('BOX', (0, 0), (-1, -1), 1, self.BORDER_GRAY),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('LEFTPADDING', (0, 0), (-1, -1), 12),
            ('RIGHTPADDING', (0, 0), (-1, -1), 12),
            ('TOPPADDING', (0, 0), (-1, -1), 12),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('ROUNDEDCORNERS', [8, 8, 8, 8]),
        ]))

        return main_table

    def _info_row(self, label, value, is_arabic=False):
        """Create an info row with label and value."""
        label_para = Paragraph(label, self.styles['InfoLabel'])
        style = self.styles['InfoValueArabic'] if is_arabic else self.styles['InfoValue']
        value_para = Paragraph(str(value), style)
        return [label_para, value_para]

    def _build_contact_section(self):
        """Build contact information section (phone, email, address)."""
        # Build info rows
        info_rows = []
        info_rows.append(self._info_row('Telephone', self.contract.customer_phone or '-'))
        info_rows.append(self._info_row('Email', self.contract.customer_email or '-'))
        info_rows.append(self._info_row('Adresse', self.contract.customer_address or '-'))

        # Info table
        info_table = Table(info_rows, colWidths=[120, 380])
        info_table.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]))

        # Wrapper with border
        wrapper_table = Table([[info_table]], colWidths=[500])
        wrapper_table.setStyle(TableStyle([
            ('BOX', (0, 0), (-1, -1), 1, self.BORDER_GRAY),
            ('LEFTPADDING', (0, 0), (-1, -1), 12),
            ('RIGHTPADDING', (0, 0), (-1, -1), 12),
            ('TOPPADDING', (0, 0), (-1, -1), 12),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('ROUNDEDCORNERS', [8, 8, 8, 8]),
        ]))

        return wrapper_table

    def _build_offer_section(self):
        """Build offer details section with features."""
        offer = self.contract.offer
        phone = self.contract.phone_number

        # Offer header
        offer_name = Paragraph(offer.name, self.styles['OfferTitle'])
        offer_price = Paragraph(f"{offer.price} DA", ParagraphStyle(
            'OfferPrice', fontName='Helvetica-Bold', fontSize=16, textColor=self.DJEZZY_RED, alignment=TA_RIGHT
        ))

        header_row = [[offer_name, offer_price]]
        header_table = Table(header_row, colWidths=[300, 180])

        # Offer details
        details = []
        details.append(self._offer_row('Numero attribue', phone.formatted_number if phone else '-'))

        if offer.data_allowance_mb:
            data_gb = offer.data_allowance_mb // 1024
            data_text = f"{data_gb} Go" if data_gb > 0 else f"{offer.data_allowance_mb} Mo"
            details.append(self._offer_row('Internet', data_text))

        if offer.validity_days:
            validity_text = '1 mois' if offer.validity_days >= 28 else f"{offer.validity_days} jours"
            details.append(self._offer_row('Validite', validity_text))

        if offer.voice_minutes:
            details.append(self._offer_row('Appels', f"{offer.voice_minutes} min"))

        if offer.sms_count:
            details.append(self._offer_row('SMS', f"{offer.sms_count} SMS"))

        details_table = Table(details, colWidths=[300, 180])
        details_table.setStyle(TableStyle([
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ]))

        # Features section (Avantages inclus)
        features_elements = []
        if hasattr(offer, 'features') and offer.features:
            features_list = offer.features if isinstance(offer.features, list) else []
        else:
            # Default features based on offer type
            features_list = [
                'Appels illimites vers Djezzy',
                'Internet 4G',
                'SMS illimites Djezzy',
            ]

        if features_list:
            features_elements.append(HRFlowable(width='100%', thickness=0.5, color=HexColor('#FFCCCC')))
            features_elements.append(Spacer(1, 8))
            features_elements.append(Paragraph('<b>Avantages inclus:</b>', ParagraphStyle(
                'FeaturesTitle', fontName='Helvetica-Bold', fontSize=10, textColor=black
            )))
            features_elements.append(Spacer(1, 6))

            for feature in features_list:
                bullet = Paragraph(f"<bullet>&bull;</bullet> {feature}", self.styles['FeatureBullet'])
                features_elements.append(bullet)

        # Combine all into one table cell
        content = [header_table, Spacer(1, 10), details_table]
        content.extend(features_elements)

        # Wrapper table with background
        wrapper_data = [[content]]
        wrapper_table = Table(wrapper_data, colWidths=[500])
        wrapper_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), self.LIGHT_RED),
            ('BOX', (0, 0), (-1, -1), 1, self.DJEZZY_RED),
            ('LEFTPADDING', (0, 0), (-1, -1), 16),
            ('RIGHTPADDING', (0, 0), (-1, -1), 16),
            ('TOPPADDING', (0, 0), (-1, -1), 16),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 16),
            ('ROUNDEDCORNERS', [8, 8, 8, 8]),
        ]))

        return wrapper_table

    def _offer_row(self, label, value):
        """Create an offer info row."""
        label_para = Paragraph(label, ParagraphStyle('OfferLabel', fontName='Helvetica', fontSize=11, textColor=black))
        value_para = Paragraph(f"<b>{value}</b>", ParagraphStyle('OfferValue', fontName='Helvetica-Bold', fontSize=11, textColor=black, alignment=TA_RIGHT))
        return [label_para, value_para]

    def _build_terms_section(self):
        """Build terms and conditions section."""
        terms_text = (
            "En signant ce contrat, le client accepte les conditions generales d'utilisation "
            "des services Djezzy. Le client certifie que les informations fournies sont "
            "exactes et s'engage a respecter les termes du contrat. Djezzy se reserve le "
            "droit de suspendre ou resilier le service en cas de non-respect des conditions. "
            "Pour toute reclamation, veuillez contacter le service client au 777."
        )

        terms_para = Paragraph(terms_text, self.styles['TermsText'])

        terms_table = Table([[terms_para]], colWidths=[500])
        terms_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), self.LIGHT_GRAY),
            ('LEFTPADDING', (0, 0), (-1, -1), 12),
            ('RIGHTPADDING', (0, 0), (-1, -1), 12),
            ('TOPPADDING', (0, 0), (-1, -1), 12),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('ROUNDEDCORNERS', [4, 4, 4, 4]),
        ]))

        return terms_table

    def _build_signature_section(self):
        """Build signature section."""
        # Signature image - larger size to preserve original display
        sig_io = self._load_signature()
        if sig_io:
            try:
                sig_img = RLImage(sig_io, width=200, height=80)
            except:
                sig_img = Paragraph('[Signature]', ParagraphStyle('SigPlaceholder',
                    fontName='Helvetica', fontSize=9, textColor=self.TEXT_GRAY, alignment=TA_CENTER))
        else:
            sig_img = Paragraph('[Signature]', ParagraphStyle('SigPlaceholder',
                fontName='Helvetica', fontSize=9, textColor=self.TEXT_GRAY, alignment=TA_CENTER))

        # Signature box - wider to accommodate larger signature
        sig_table = Table([[sig_img]], colWidths=[210])
        sig_table.setStyle(TableStyle([
            ('BOX', (0, 0), (-1, -1), 1, self.BORDER_GRAY),
            ('BACKGROUND', (0, 0), (-1, -1), white),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 10),
            ('ROUNDEDCORNERS', [4, 4, 4, 4]),
        ]))

        # Customer info
        customer_name = self.contract.customer_full_name or 'Client'
        formatted_date = self.contract.created_at.strftime('%d/%m/%Y') if self.contract.created_at else '-'

        info_elements = [
            Paragraph(f"<b>{customer_name}</b>", ParagraphStyle('SigName', fontName='Helvetica-Bold', fontSize=11, textColor=black)),
            Spacer(1, 4),
            Paragraph(f"Date: {formatted_date}", ParagraphStyle('SigDate', fontName='Helvetica', fontSize=10, textColor=black)),
            Spacer(1, 10),
        ]

        # Confirmation box
        confirm_para = Paragraph("Je confirme que c'est ma carte d'identite nationale",
            ParagraphStyle('ConfirmText', fontName='Helvetica', fontSize=8, textColor=self.GREEN_TEXT))
        confirm_table = Table([[confirm_para]], colWidths=[200])
        confirm_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), self.LIGHT_GREEN),
            ('LEFTPADDING', (0, 0), (-1, -1), 8),
            ('RIGHTPADDING', (0, 0), (-1, -1), 8),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('ROUNDEDCORNERS', [4, 4, 4, 4]),
        ]))

        info_elements.append(confirm_table)

        # Title
        title_para = Paragraph('<b>SIGNATURE DU CLIENT</b>', ParagraphStyle(
            'SigTitle', fontName='Helvetica-Bold', fontSize=12, textColor=black))

        # Main layout - adjusted widths for larger signature
        main_data = [[sig_table, info_elements]]
        main_table = Table(main_data, colWidths=[220, 260])
        main_table.setStyle(TableStyle([
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('LEFTPADDING', (0, 0), (-1, -1), 0),
            ('RIGHTPADDING', (0, 0), (-1, -1), 0),
        ]))

        # Outer wrapper
        wrapper_data = [[title_para], [Spacer(1, 12)], [main_table]]
        wrapper_table = Table(wrapper_data, colWidths=[500])
        wrapper_table.setStyle(TableStyle([
            ('BOX', (0, 0), (-1, -1), 1, self.BORDER_GRAY),
            ('LEFTPADDING', (0, 0), (-1, -1), 16),
            ('RIGHTPADDING', (0, 0), (-1, -1), 16),
            ('TOPPADDING', (0, 0), (-1, -1), 16),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 16),
            ('ROUNDEDCORNERS', [8, 8, 8, 8]),
        ]))

        return wrapper_table

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

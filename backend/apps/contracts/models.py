from django.db import models
from django.utils import timezone
from apps.offers.models import Offer
from apps.phone_numbers.models import PhoneNumber


def contract_pdf_path(instance, filename):
    """Generate upload path for contract PDFs."""
    return f'contracts/{instance.contract_number}/{filename}'


def contract_photo_path(instance, filename):
    """Generate upload path for customer photos."""
    return f'contracts/{instance.contract_number}/photo_{filename}'


class Contract(models.Model):
    """Contract model for Djezzy subscriptions."""

    STATUS_CHOICES = [
        ('draft', 'Brouillon'),
        ('signed', 'Signe'),
        ('validated', 'Valide'),
        ('cancelled', 'Annule'),
    ]

    # Contract identification
    contract_number = models.CharField(
        max_length=50,
        unique=True,
        verbose_name='Numero de contrat'
    )

    # Customer information (from ID card)
    customer_first_name = models.CharField(
        max_length=100,
        verbose_name='Prenom'
    )
    customer_last_name = models.CharField(
        max_length=100,
        verbose_name='Nom'
    )
    customer_first_name_ar = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Prenom (Arabe)'
    )
    customer_last_name_ar = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Nom (Arabe)'
    )
    customer_birth_date = models.DateField(
        null=True,
        blank=True,
        verbose_name='Date de naissance'
    )
    customer_birth_place = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Lieu de naissance'
    )
    customer_sex = models.CharField(
        max_length=10,
        blank=True,
        verbose_name='Sexe'
    )
    customer_nin = models.CharField(
        max_length=50,
        verbose_name='NIN'
    )
    customer_id_number = models.CharField(
        max_length=50,
        verbose_name='Numero CNI'
    )
    customer_id_expiry = models.DateField(
        null=True,
        blank=True,
        verbose_name='Date d\'expiration CNI'
    )
    customer_daira = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Daira'
    )
    customer_baladia = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Commune'
    )

    # Relations
    offer = models.ForeignKey(
        Offer,
        on_delete=models.PROTECT,
        related_name='contracts',
        verbose_name='Offre'
    )
    phone_number = models.ForeignKey(
        PhoneNumber,
        on_delete=models.PROTECT,
        related_name='contracts',
        verbose_name='Numero attribue'
    )

    # Files
    pdf_file = models.FileField(
        upload_to=contract_pdf_path,
        blank=True,
        null=True,
        verbose_name='Fichier PDF'
    )
    customer_photo = models.ImageField(
        upload_to=contract_photo_path,
        blank=True,
        null=True,
        verbose_name='Photo du client'
    )
    signature_base64 = models.TextField(
        blank=True,
        verbose_name='Signature (Base64)'
    )

    # Contact
    customer_email = models.EmailField(
        blank=True,
        verbose_name='Email du client'
    )
    email_sent = models.BooleanField(
        default=False,
        verbose_name='Email envoye'
    )
    email_sent_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Date d\'envoi email'
    )

    # Status
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='draft',
        verbose_name='Statut'
    )

    # Metadata
    created_by = models.ForeignKey(
        'accounts.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='contracts_created',
        verbose_name='Cree par'
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date de creation'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Derniere modification'
    )
    signed_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Date de signature'
    )

    class Meta:
        verbose_name = 'Contrat'
        verbose_name_plural = 'Contrats'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.contract_number} - {self.customer_full_name}"

    @property
    def customer_full_name(self):
        """Return customer full name."""
        return f"{self.customer_first_name} {self.customer_last_name}"

    def save(self, *args, **kwargs):
        if not self.contract_number:
            self.contract_number = self.generate_contract_number()
        super().save(*args, **kwargs)

    @staticmethod
    def generate_contract_number():
        """Generate unique contract number."""
        from datetime import datetime
        import random
        date_str = datetime.now().strftime('%Y%m%d')
        random_suffix = str(random.randint(1000, 9999))
        return f"DJ-{date_str}-{random_suffix}"

    def mark_as_signed(self):
        """Mark contract as signed."""
        self.status = 'signed'
        self.signed_at = timezone.now()
        self.save()

    def mark_email_sent(self):
        """Mark email as sent."""
        self.email_sent = True
        self.email_sent_at = timezone.now()
        self.save()

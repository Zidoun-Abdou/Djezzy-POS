from django.db import models
from django.core.validators import RegexValidator


class PhoneNumber(models.Model):
    """Phone number model for Djezzy SIM cards."""

    STATUS_CHOICES = [
        ('available', 'Disponible'),
        ('assigned', 'Attribue'),
        ('reserved', 'Reserve'),
        ('blocked', 'Bloque'),
    ]

    phone_validator = RegexValidator(
        regex=r'^07[0-9]{8}$',
        message='Le numero doit commencer par 07 et contenir exactement 10 chiffres.'
    )

    number = models.CharField(
        max_length=10,
        unique=True,
        validators=[phone_validator],
        verbose_name='Numero'
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='available',
        verbose_name='Statut'
    )
    assigned_to_name = models.CharField(
        max_length=200,
        blank=True,
        verbose_name='Attribue a (Nom)'
    )
    assigned_to_nin = models.CharField(
        max_length=50,
        blank=True,
        verbose_name='NIN du client'
    )
    assigned_date = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Date d\'attribution'
    )
    notes = models.TextField(
        blank=True,
        verbose_name='Notes'
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date de creation'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Derniere modification'
    )

    class Meta:
        verbose_name = 'Numero de telephone'
        verbose_name_plural = 'Numeros de telephone'
        ordering = ['number']

    def __str__(self):
        return self.formatted_number

    @property
    def formatted_number(self):
        """Return formatted phone number."""
        if len(self.number) == 10:
            return f"{self.number[:4]} {self.number[4:6]} {self.number[6:8]} {self.number[8:]}"
        return self.number

    def assign_to(self, name, nin):
        """Assign this number to a customer."""
        from django.utils import timezone
        self.status = 'assigned'
        self.assigned_to_name = name
        self.assigned_to_nin = nin
        self.assigned_date = timezone.now()
        self.save()

    def make_available(self):
        """Make this number available again."""
        self.status = 'available'
        self.assigned_to_name = ''
        self.assigned_to_nin = ''
        self.assigned_date = None
        self.save()

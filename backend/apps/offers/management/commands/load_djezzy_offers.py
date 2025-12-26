"""
Management command to load Djezzy offers into the database.
Based on current Djezzy Legend offers from official sources.
"""

from django.core.management.base import BaseCommand
from apps.offers.models import Offer


class Command(BaseCommand):
    help = 'Load Djezzy Legend offers into the database'

    def handle(self, *args, **options):
        # Djezzy Legend offers based on current market research
        offers_data = [
            {
                'name': 'LEGEND 2500',
                'code': 'LEGEND2500',
                'description': 'Offre premium avec appels illimites vers tous les reseaux nationaux',
                'price': 2500,
                'currency': 'DZD',
                'data_allowance_mb': 102400,  # 100 GB
                'voice_minutes': 99999,  # Unlimited
                'sms_count': 100,
                'validity_days': 30,
                'features': [
                    'Appels illimites vers tous reseaux',
                    'Internet haut debit 4G',
                    'SMS illimites Djezzy',
                    '100 SMS vers autres operateurs'
                ],
                'is_active': True,
                'is_featured': True,
                'display_order': 1,
            },
            {
                'name': 'LEGEND 2000',
                'code': 'LEGEND2000',
                'description': 'Offre complete avec 70 Go et appels illimites',
                'price': 2000,
                'currency': 'DZD',
                'data_allowance_mb': 71680,  # 70 GB
                'voice_minutes': 99999,  # Unlimited
                'sms_count': 50,
                'validity_days': 30,
                'features': [
                    'Appels illimites vers tous reseaux',
                    'Internet haut debit 4G',
                    'SMS illimites Djezzy',
                    '50 SMS vers autres operateurs'
                ],
                'is_active': True,
                'is_featured': True,
                'display_order': 2,
            },
            {
                'name': 'LEGEND 1500',
                'code': 'LEGEND1500',
                'description': 'Offre avantageuse avec 50 Go et appels illimites Djezzy',
                'price': 1500,
                'currency': 'DZD',
                'data_allowance_mb': 51200,  # 50 GB
                'voice_minutes': 99999,  # Unlimited to Djezzy
                'sms_count': 100,
                'validity_days': 30,
                'features': [
                    'Appels illimites vers Djezzy',
                    'Internet 4G',
                    'SMS illimites Djezzy'
                ],
                'is_active': True,
                'is_featured': True,
                'display_order': 3,
            },
            {
                'name': 'LEGEND 1000',
                'code': 'LEGEND1000',
                'description': 'Offre equilibree avec 30 Go',
                'price': 1000,
                'currency': 'DZD',
                'data_allowance_mb': 30720,  # 30 GB
                'voice_minutes': 99999,  # Unlimited to Djezzy
                'sms_count': 100,
                'validity_days': 30,
                'features': [
                    'Appels illimites vers Djezzy',
                    'Internet 4G',
                    'SMS illimites Djezzy'
                ],
                'is_active': True,
                'is_featured': False,
                'display_order': 4,
            },
            {
                'name': 'LEGEND 500',
                'code': 'LEGEND500',
                'description': 'Offre mensuelle economique avec 10 Go',
                'price': 500,
                'currency': 'DZD',
                'data_allowance_mb': 10240,  # 10 GB
                'voice_minutes': 500,
                'sms_count': 100,
                'validity_days': 30,
                'features': [
                    '500 min vers Djezzy',
                    'Internet mobile 4G',
                    '100 SMS'
                ],
                'is_active': True,
                'is_featured': False,
                'display_order': 5,
            },
            {
                'name': 'LEGEND 150',
                'code': 'LEGEND150',
                'description': 'Offre hebdomadaire avec 5 Go',
                'price': 150,
                'currency': 'DZD',
                'data_allowance_mb': 5120,  # 5 GB
                'voice_minutes': 100,
                'sms_count': 50,
                'validity_days': 7,
                'features': [
                    '100 min vers Djezzy',
                    'Internet mobile',
                    '50 SMS'
                ],
                'is_active': True,
                'is_featured': False,
                'display_order': 6,
            },
            {
                'name': 'LEGEND 100',
                'code': 'LEGEND100',
                'description': 'Offre 3 jours avec 3 Go',
                'price': 100,
                'currency': 'DZD',
                'data_allowance_mb': 3072,  # 3 GB
                'voice_minutes': 50,
                'sms_count': 30,
                'validity_days': 3,
                'features': [
                    '50 min vers Djezzy',
                    'Internet mobile',
                    '30 SMS'
                ],
                'is_active': True,
                'is_featured': False,
                'display_order': 7,
            },
            {
                'name': 'LEGEND 50',
                'code': 'LEGEND50',
                'description': 'Offre journaliere avec 1 Go',
                'price': 50,
                'currency': 'DZD',
                'data_allowance_mb': 1024,  # 1 GB
                'voice_minutes': 20,
                'sms_count': 20,
                'validity_days': 1,
                'features': [
                    '20 min vers Djezzy',
                    'Internet mobile',
                    '20 SMS'
                ],
                'is_active': True,
                'is_featured': False,
                'display_order': 8,
            },
        ]

        created_count = 0
        updated_count = 0

        for offer_data in offers_data:
            offer, created = Offer.objects.update_or_create(
                code=offer_data['code'],
                defaults=offer_data
            )
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'Created offer: {offer.name}')
                )
            else:
                updated_count += 1
                self.stdout.write(
                    self.style.WARNING(f'Updated offer: {offer.name}')
                )

        self.stdout.write(
            self.style.SUCCESS(
                f'\nDone! Created: {created_count}, Updated: {updated_count}'
            )
        )

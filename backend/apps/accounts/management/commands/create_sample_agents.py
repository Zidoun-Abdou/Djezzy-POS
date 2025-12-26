"""
Management command to create sample agent users for testing.
"""

from django.core.management.base import BaseCommand
from apps.accounts.models import User


class Command(BaseCommand):
    help = 'Create sample agent users for testing'

    def add_arguments(self, parser):
        parser.add_argument(
            '--password',
            type=str,
            default='Djezzy2024!',
            help='Password for all sample agents (default: Djezzy2024!)'
        )
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Delete existing sample agents before creating new ones'
        )

    def handle(self, *args, **options):
        password = options['password']

        # Sample agent data
        agents_data = [
            {
                'username': 'agent1',
                'email': 'agent1@djezzy.dz',
                'first_name': 'Ahmed',
                'last_name': 'Benali',
                'role': 'agent',
                'phone_number': '0770123456',
                'store_location': 'Alger Centre',
            },
            {
                'username': 'agent2',
                'email': 'agent2@djezzy.dz',
                'first_name': 'Fatima',
                'last_name': 'Hadj',
                'role': 'agent',
                'phone_number': '0771234567',
                'store_location': 'Oran',
            },
            {
                'username': 'agent3',
                'email': 'agent3@djezzy.dz',
                'first_name': 'Karim',
                'last_name': 'Mansouri',
                'role': 'agent',
                'phone_number': '0772345678',
                'store_location': 'Constantine',
            },
            {
                'username': 'agent4',
                'email': 'agent4@djezzy.dz',
                'first_name': 'Sara',
                'last_name': 'Boudiaf',
                'role': 'agent',
                'phone_number': '0773456789',
                'store_location': 'Annaba',
            },
            {
                'username': 'manager1',
                'email': 'manager1@djezzy.dz',
                'first_name': 'Mohamed',
                'last_name': 'Cherif',
                'role': 'manager',
                'phone_number': '0774567890',
                'store_location': 'Alger - Siege',
            },
        ]

        if options['clear']:
            # Delete only sample agents (not superusers or other admins)
            sample_usernames = [a['username'] for a in agents_data]
            deleted_count = User.objects.filter(username__in=sample_usernames).delete()[0]
            self.stdout.write(
                self.style.WARNING(f'Deleted {deleted_count} existing sample agents')
            )

        created_count = 0
        updated_count = 0

        for agent_data in agents_data:
            username = agent_data.pop('username')

            user, created = User.objects.update_or_create(
                username=username,
                defaults=agent_data
            )

            # Set password
            user.set_password(password)
            user.save()

            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'Created: {user.get_full_name()} ({username})')
                )
            else:
                updated_count += 1
                self.stdout.write(
                    self.style.WARNING(f'Updated: {user.get_full_name()} ({username})')
                )

        self.stdout.write(
            self.style.SUCCESS(
                f'\nDone! Created: {created_count}, Updated: {updated_count}'
            )
        )
        self.stdout.write(
            self.style.SUCCESS(f'Password for all agents: {password}')
        )

        # Show summary
        self.stdout.write('\nSample Agents Summary:')
        self.stdout.write('-' * 60)
        for agent in agents_data:
            agent['username'] = agent.get('username', list(agents_data)[agents_data.index(agent)]['username'] if 'username' in agent else 'N/A')

        # Reload and display
        for user in User.objects.filter(role__in=['agent', 'manager']).exclude(is_superuser=True):
            self.stdout.write(
                f'  {user.username}: {user.get_full_name()} | '
                f'{user.get_role_display()} | {user.store_location}'
            )

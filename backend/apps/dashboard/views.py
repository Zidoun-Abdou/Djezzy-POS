from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import login, logout, authenticate
from django.contrib.auth.decorators import login_required
from django.views.decorators.http import require_http_methods
from apps.contracts.models import Contract


def login_view(request):
    """Dashboard login page."""
    if request.user.is_authenticated:
        # Check if agent needs OTP verification
        if request.user.role == 'agent' and not request.session.get('otp_verified'):
            return redirect('dashboard:otp')
        return redirect('dashboard:index')

    error = None
    if request.method == 'POST':
        username = request.POST.get('username', '').strip()
        password = request.POST.get('password', '')

        if username and password:
            user = authenticate(request, username=username, password=password)
            if user is not None:
                login(request, user)
                # Agents need OTP verification
                if user.role == 'agent':
                    return redirect('dashboard:otp')
                return redirect('dashboard:index')
            else:
                error = 'Nom d\'utilisateur ou mot de passe incorrect'
        else:
            error = 'Veuillez remplir tous les champs'

    return render(request, 'dashboard/login.html', {'error': error})


@login_required(login_url='/dashboard/login/')
def otp_view(request):
    """OTP verification page for agents."""
    # Only agents need OTP verification
    if request.user.role != 'agent':
        return redirect('dashboard:index')

    # If already verified, go to dashboard
    if request.session.get('otp_verified'):
        return redirect('dashboard:index')

    error = None
    message = None

    if request.method == 'POST':
        otp = request.POST.get('otp', '').strip()

        if otp and len(otp) == 6:
            # Demo mode: accept any 6-digit code
            request.session['otp_verified'] = True
            return redirect('dashboard:index')
        else:
            error = 'Veuillez entrer un code a 6 chiffres'

    # Handle resend request
    if request.GET.get('resend'):
        message = 'Un nouveau code a ete envoye'

    return render(request, 'dashboard/otp.html', {'error': error, 'message': message})


@login_required(login_url='/dashboard/login/')
def logout_view(request):
    """Logout and redirect to login."""
    # Clear OTP verification on logout
    request.session.pop('otp_verified', None)
    logout(request)
    return redirect('dashboard:login')


@login_required(login_url='/dashboard/login/')
def index_view(request):
    """Dashboard home with statistics."""
    # Agents must verify OTP first
    if request.user.role == 'agent' and not request.session.get('otp_verified'):
        return redirect('dashboard:otp')
    return render(request, 'dashboard/index.html')


@login_required(login_url='/dashboard/login/')
def users_view(request):
    """Users management page."""
    return render(request, 'dashboard/users.html')


@login_required(login_url='/dashboard/login/')
def offers_view(request):
    """Offers management page."""
    return render(request, 'dashboard/offers.html')


@login_required(login_url='/dashboard/login/')
def phone_numbers_view(request):
    """Phone numbers management page."""
    return render(request, 'dashboard/phone_numbers.html')


@login_required(login_url='/dashboard/login/')
def contracts_view(request):
    """Contracts list page."""
    return render(request, 'dashboard/contracts.html')


@login_required(login_url='/dashboard/login/')
def contract_detail_view(request, pk):
    """Contract detail page."""
    contract = get_object_or_404(Contract, pk=pk)
    return render(request, 'dashboard/contract_detail.html', {'contract': contract})


@login_required(login_url='/dashboard/login/')
def my_sales_view(request):
    """Agent's sales history page."""
    return render(request, 'dashboard/my_sales.html')

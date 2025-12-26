from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import login, logout, authenticate
from django.contrib.auth.decorators import login_required
from django.views.decorators.http import require_http_methods
from apps.contracts.models import Contract


def login_view(request):
    """Dashboard login page."""
    if request.user.is_authenticated:
        return redirect('dashboard:index')

    error = None
    if request.method == 'POST':
        username = request.POST.get('username', '').strip()
        password = request.POST.get('password', '')

        if username and password:
            user = authenticate(request, username=username, password=password)
            if user is not None:
                login(request, user)
                return redirect('dashboard:index')
            else:
                error = 'Nom d\'utilisateur ou mot de passe incorrect'
        else:
            error = 'Veuillez remplir tous les champs'

    return render(request, 'dashboard/login.html', {'error': error})


@login_required(login_url='/dashboard/login/')
def logout_view(request):
    """Logout and redirect to login."""
    logout(request)
    return redirect('dashboard:login')


@login_required(login_url='/dashboard/login/')
def index_view(request):
    """Dashboard home with statistics."""
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

from django.urls import path
from . import views

app_name = 'dashboard'

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('', views.index_view, name='index'),
    path('users/', views.users_view, name='users'),
    path('offers/', views.offers_view, name='offers'),
    path('phone-numbers/', views.phone_numbers_view, name='phone_numbers'),
    path('contracts/', views.contracts_view, name='contracts'),
    path('contracts/<int:pk>/', views.contract_detail_view, name='contract_detail'),
    path('my-sales/', views.my_sales_view, name='my_sales'),
]

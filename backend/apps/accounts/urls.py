from django.urls import path
from . import views

app_name = 'accounts'

urlpatterns = [
    # Current user endpoints
    path('me/', views.current_user, name='current-user'),
    path('me/update/', views.update_profile, name='update-profile'),
    path('me/change-password/', views.change_password, name='change-password'),

    # Admin user management endpoints
    path('', views.list_users, name='list-users'),
    path('create/', views.create_user, name='create-user'),
    path('<int:user_id>/', views.user_detail, name='user-detail'),
    path('<int:user_id>/toggle-active/', views.toggle_user_active, name='toggle-user-active'),
]

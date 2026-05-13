from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Partner, BarberShop, Staff, Service, Appointment

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'email', 'is_partner', 'is_owner', 'is_staff')
    fieldsets = UserAdmin.fieldsets + (
        ('Roles', {'fields': ('is_partner', 'is_owner', 'phone_number')}),
    )

@admin.register(Partner)
class PartnerAdmin(admin.ModelAdmin):
    list_display = ('user', 'referral_code', 'commission_rate', 'total_earned')
    search_fields = ('user__username', 'referral_code')

@admin.register(BarberShop)
class BarberShopAdmin(admin.ModelAdmin):
    list_display = ('name', 'owner', 'referred_by', 'whatsapp_number', 'is_active')
    list_filter = ('is_active', 'referred_by')
    search_fields = ('name', 'whatsapp_number')

@admin.register(Staff)
class StaffAdmin(admin.ModelAdmin):
    list_display = ('name', 'shop', 'is_active')
    list_filter = ('shop', 'is_active')

@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ('name', 'shop', 'price', 'duration_minutes')
    list_filter = ('shop',)

@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ('client_name', 'shop', 'staff', 'start_time', 'status')
    list_filter = ('status', 'shop', 'staff')
    search_fields = ('client_name', 'client_phone')

from django.contrib import admin
from django.contrib.auth.models import Group
from django.utils.html import format_html
from .models import User, Partner, BarberShop, Staff, Service, Appointment, WhatsAppFlow, WhatsAppTemplate, MetaConfig

if admin.site.is_registered(Group):
    admin.site.unregister(Group)

@admin.register(MetaConfig)
class MetaConfigAdmin(admin.ModelAdmin):
    list_display = ('name', 'app_id', 'is_active')
    fieldsets = (
        ('Configuración General', {'fields': ('name', 'app_id', 'app_secret', 'access_token', 'verify_token', 'is_active')}),
        ('Simulador de Webhook', {'fields': ('test_payload', 'simulate_button')}),
    )
    readonly_fields = ('simulate_button',)

    def simulate_button(self, obj):
        return format_html(
            '<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>'
            '<button type="button" class="button" onclick="simulateWebhook()" style="background:#417690;">🚀 Simular Mensaje</button>'
            '<script>function simulateWebhook(){{ const p=document.getElementById("id_test_payload").value; if(!p) return Swal.fire("Error","JSON vacío","error"); Swal.showLoading(); fetch("/api/webhook",{{method:"POST",body:p}}).then(r=>r.json()).then(d=>Swal.fire("OK",d.status,"success")); }}</script>'
        )

@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ('name', 'shop', 'price', 'duration_minutes', 'is_active', 'image_preview')
    list_filter = ('shop', 'is_active')
    search_fields = ('name',)

    def image_preview(self, obj):
        if obj.image_url:
            return format_html('<img src="{}" style="width: 50px; height: 50px; border-radius: 5px; object-fit: cover;" />', obj.image_url)
        return "Sin foto"
    image_preview.short_description = "Vista Previa"

@admin.register(BarberShop)
class BarberShopAdmin(admin.ModelAdmin):
    list_display = ('name', 'whatsapp_number', 'is_active')
    filter_horizontal = ('available_flows', 'available_templates')
    fieldsets = (
        ('Información General', {'fields': ('name', 'client_name', 'referred_by', 'whatsapp_number', 'timezone', 'is_active')}),
        ('Asignación de Recursos', {'fields': ('available_flows', 'available_templates', 'default_flow')}),
        ('Identificadores de Meta', {'fields': ('whatsapp_phone_number_id', 'whatsapp_waba_id')}),
    )

@admin.register(WhatsAppFlow)
class WhatsAppFlowAdmin(admin.ModelAdmin):
    list_display = ('name', 'flow_id', 'is_active', 'test_button')
    readonly_fields = ('test_button',)
    def test_button(self, obj):
        if obj and obj.pk:
            return format_html('<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script><button type="button" class="button" onclick="runFlowTest({id})" style="background:#79aec8;">Probar Flow</button><script>function runFlowTest(id){{ Swal.showLoading(); fetch("/api/test-flow/"+id).then(r=>r.json()).then(d=>Swal.fire(d.success?"¡Enviado!":"Error",d.message,d.success?"success":"error")); }}</script>', id=obj.pk)
        return "Guarda para probar"

@admin.register(WhatsAppTemplate)
class WhatsAppTemplateAdmin(admin.ModelAdmin):
    list_display = ('name', 'language_code', 'is_active', 'test_button')
    readonly_fields = ('test_button',)
    def test_button(self, obj):
        if obj and obj.pk:
            return format_html('<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script><button type="button" class="button" onclick="runTemplateTest({id})" style="background:#79aec8;">Probar Plantilla</button><script>function runTemplateTest(id){{ Swal.showLoading(); fetch("/api/test-template/"+id).then(r=>r.json()).then(d=>Swal.fire(d.success?"¡Enviado!":"Error",d.message,d.success?"success":"error")); }}</script>', id=obj.pk)
        return "Guarda para probar"

@admin.register(Partner)
class PartnerAdmin(admin.ModelAdmin):
    list_display = ('user', 'referral_code')

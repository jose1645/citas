from django.db import models
from django.contrib.auth.models import AbstractUser
from django.conf import settings

class User(AbstractUser):
    is_partner = models.BooleanField(default=False)
    is_owner = models.BooleanField(default=False)
    phone_number = models.CharField(max_length=20, blank=True, null=True)

    def __str__(self):
        return f"{self.username}"

class MetaConfig(models.Model):
    name = models.CharField(max_length=100, default="Configuración Principal Meta")
    app_id = models.CharField(max_length=50, blank=True, null=True)
    app_secret = models.CharField(max_length=100, blank=True, null=True)
    access_token = models.TextField(help_text="System User Access Token")
    verify_token = models.CharField(max_length=100, default="teleferico_seguro_123")
    catalog_id = models.CharField(max_length=50, blank=True, null=True, help_text="ID del catálogo de Meta Commerce")
    flow_private_key = models.TextField(blank=True, null=True, help_text="Llave Privada RSA para WhatsApp Flows")
    flow_public_key = models.TextField(blank=True, null=True, help_text="Llave Pública RSA para WhatsApp Flows")
    is_active = models.BooleanField(default=True)
    test_payload = models.TextField(blank=True, null=True, help_text="Pega aquí un JSON de Meta para simular un mensaje")

    class Meta:
        verbose_name = "Meta App Config"
        verbose_name_plural = "Meta App Config"

    def __str__(self):
        return self.name

class WhatsAppFlow(models.Model):
    name = models.CharField(max_length=100, help_text="Nombre descriptivo del flujo")
    flow_id = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = "WhatsApp Flow (Biblioteca)"
        verbose_name_plural = "WhatsApp Flows (Biblioteca)"

    def __str__(self):
        return self.name

class WhatsAppTemplate(models.Model):
    name = models.CharField(max_length=100, help_text="Nombre de la plantilla en Meta", unique=True)
    category = models.CharField(max_length=50, blank=True, null=True)
    language_code = models.CharField(max_length=10, default='es_MX')
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = "WhatsApp Template (Biblioteca)"
        verbose_name_plural = "WhatsApp Templates (Biblioteca)"

    def __str__(self):
        return self.name

class Partner(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='partner_profile')
    referral_code = models.CharField(max_length=20, unique=True)
    commission_rate = models.DecimalField(max_digits=5, decimal_places=2, default=20.00)
    total_earned = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)

    def __str__(self):
        return f"Partner: {self.user.username} [{self.referral_code}]"

class BarberShop(models.Model):
    name = models.CharField(max_length=100)
    client_name = models.CharField(max_length=100, blank=True, null=True)
    referred_by = models.ForeignKey(Partner, on_delete=models.SET_NULL, null=True, blank=True, related_name='referred_shops')
    whatsapp_number = models.CharField(max_length=20, unique=True)
    timezone = models.CharField(max_length=50, default='America/Mexico_City')
    
    # Meta API Identifiers
    whatsapp_phone_number_id = models.CharField(max_length=50, blank=True, null=True)
    whatsapp_waba_id = models.CharField(max_length=50, blank=True, null=True)

    # Dinamic Assignment
    available_flows = models.ManyToManyField(WhatsAppFlow, blank=True, related_name='assigned_shops')
    available_templates = models.ManyToManyField(WhatsAppTemplate, blank=True, related_name='assigned_shops')
    
    # Campo para definir qué flujo es el default para esta tienda
    default_flow = models.ForeignKey(WhatsAppFlow, on_delete=models.SET_NULL, null=True, blank=True, related_name='default_for_shops')

    # Billing Info
    legal_name = models.CharField(max_length=150, blank=True, null=True)
    tax_id = models.CharField(max_length=50, blank=True, null=True)
    billing_address = models.TextField(blank=True, null=True)
    billing_email = models.EmailField(blank=True, null=True)
    wants_invoice = models.BooleanField(default=False)
    wants_ticket = models.BooleanField(default=False)

    # Ubicación Física y Mapa
    address = models.CharField(max_length=255, blank=True, null=True, help_text="Dirección completa física")
    latitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True, help_text="Latitud para el mapa")
    longitude = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True, help_text="Longitud para el mapa")
    business_hours = models.CharField(max_length=255, blank=True, null=True, default="Lunes a Sábado de 10:00 AM a 8:00 PM", help_text="Horario de atención comercial")

    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class Staff(models.Model):
    shop = models.ForeignKey(BarberShop, on_delete=models.CASCADE, related_name='staff')
    name = models.CharField(max_length=100)
    is_active = models.BooleanField(default=True)

class Service(models.Model):
    shop = models.ForeignKey(BarberShop, on_delete=models.CASCADE, related_name='services')
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True, help_text="Descripción de lo que incluye el servicio")
    price = models.DecimalField(max_digits=10, decimal_places=2)
    duration_minutes = models.PositiveIntegerField(default=30)
    image_url = models.URLField(blank=True, null=True, help_text="URL de la foto del servicio (para mostrar en WhatsApp)")
    is_active = models.BooleanField(default=True)

    def get_retailer_id(self):
        return f"shop_{self.shop.id}_service_{self.id}"

    def save(self, *args, **kwargs):
        is_new = self.pk is None
        super().save(*args, **kwargs)
        # Sync with Meta Catalog
        from .utils import WhatsAppClient
        client = WhatsAppClient()
        client.sync_catalog_product(
            retailer_id=self.get_retailer_id(),
            name=self.name,
            description=self.description,
            price=self.price,
            image_url=self.image_url,
            is_active=self.is_active
        )

    def delete(self, *args, **kwargs):
        retailer_id = self.get_retailer_id()
        # Sync with Meta Catalog
        from .utils import WhatsAppClient
        client = WhatsAppClient()
        client.delete_catalog_product(retailer_id)
        super().delete(*args, **kwargs)

    def __str__(self):
        return f"{self.name} - {self.shop.name}"

class Appointment(models.Model):
    shop = models.ForeignKey(BarberShop, on_delete=models.CASCADE, related_name='appointments')
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='appointments')
    service = models.ForeignKey(Service, on_delete=models.CASCADE)
    client_name = models.CharField(max_length=100)
    client_phone = models.CharField(max_length=20)
    start_time = models.DateTimeField()
    status = models.CharField(max_length=20, default='scheduled')
    created_at = models.DateTimeField(auto_now_add=True)

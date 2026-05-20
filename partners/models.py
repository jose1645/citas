from django.db import models
from django.conf import settings

class Partner(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='partner_profile')
    referral_code = models.CharField(max_length=20, unique=True)
    commission_rate = models.DecimalField(max_digits=5, decimal_places=2, default=20.00)
    total_earned = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    current_balance = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)

    class Meta:
        db_table = 'core_partner'

    def __str__(self):
        return f"Partner: {self.user.username} [{self.referral_code}]"

class CommissionPayout(models.Model):
    partner = models.ForeignKey(Partner, on_delete=models.CASCADE, related_name='commissions')
    shop_name = models.CharField(max_length=150)
    amount_paid = models.DecimalField(max_digits=10, decimal_places=2)
    commission_earned = models.DecimalField(max_digits=10, decimal_places=2)
    earned_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Comisión {self.commission_earned} de {self.shop_name}"

class PayoutLog(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pendiente de Pago'),
        ('paid', 'Transferido/Completado'),
        ('failed', 'Rechazado')
    ]
    partner = models.ForeignKey(Partner, on_delete=models.CASCADE, related_name='payouts')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    reference_number = models.CharField(max_length=100, blank=True, null=True)
    requested_at = models.DateTimeField(auto_now_add=True)
    paid_at = models.DateTimeField(blank=True, null=True)

    def __str__(self):
        return f"Retiro {self.amount} - {self.partner.user.username} ({self.status})"

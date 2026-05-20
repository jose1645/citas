from django.test import TestCase
from django.contrib.auth import get_user_model
from partners.models import Partner, CommissionPayout, PayoutLog

User = get_user_model()

class PartnersModelsTestCase(TestCase):
    def setUp(self):
        # 1. Create a User for the Partner
        self.user = User.objects.create_user(
            username="partner_user",
            password="test_password",
            is_partner=True
        )
        
        # 2. Create Partner profile
        self.partner = Partner.objects.create(
            user=self.user,
            referral_code="JOSE20",
            commission_rate=15.00,
            total_earned=100.00,
            current_balance=100.00
        )

    def test_partner_creation(self):
        self.assertEqual(self.partner.referral_code, "JOSE20")
        self.assertEqual(self.partner.commission_rate, 15.00)
        self.assertEqual(self.partner.total_earned, 100.00)
        self.assertEqual(str(self.partner), f"Partner: partner_user [JOSE20]")

    def test_commission_payout_creation(self):
        commission = CommissionPayout.objects.create(
            partner=self.partner,
            shop_name="Jose's Barber Shop",
            amount_paid=1000.00,
            commission_earned=150.00
        )
        self.assertEqual(commission.partner, self.partner)
        self.assertEqual(commission.shop_name, "Jose's Barber Shop")
        self.assertEqual(commission.commission_earned, 150.00)
        self.assertEqual(str(commission), "Comisión 150.0 de Jose's Barber Shop")

    def test_payout_log_creation(self):
        payout = PayoutLog.objects.create(
            partner=self.partner,
            amount=50.00,
            status="pending"
        )
        self.assertEqual(payout.amount, 50.00)
        self.assertEqual(payout.status, "pending")
        self.assertEqual(str(payout), "Retiro 50.0 - partner_user (pending)")

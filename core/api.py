from ninja import Router
from django.http import HttpResponse
from django.conf import settings
from .models import BarberShop, Appointment, Staff, Service
from .utils import WhatsAppClient
import json
import logging
import os

logger = logging.getLogger(__name__)
router = Router()

# Token de verificación desde settings
VERIFY_TOKEN = getattr(settings, 'WHATSAPP_VERIFY_TOKEN', "flowcuts_secret_token_2026")

@router.get("/webhook")
def verify_webhook(request, hub_mode: str = None, hub_verify_token: str = None, hub_challenge: str = None):
    """
    Endpoint para que Meta verifique el Webhook.
    """
    if hub_mode == "subscribe" and hub_verify_token == VERIFY_TOKEN:
        logger.info("Webhook verificado exitosamente.")
        return HttpResponse(hub_challenge)
    
    logger.warning("Fallo en la verificación del Webhook.")
    return HttpResponse("Verification failed", status=403)

@router.post("/webhook")
def receive_whatsapp_message(request):
    """
    Endpoint donde Meta envía los mensajes y eventos de WhatsApp.
    """
    try:
        data = json.loads(request.body)
        logger.info(f"Mensaje recibido: {json.dumps(data, indent=2)}")
        
        # Verificar que sea un mensaje de WhatsApp
        if not data.get("entry") or not data["entry"][0].get("changes"):
            return {"status": "ignored"}

        change = data["entry"][0]["changes"][0]["value"]
        
        # Ignorar si no hay mensajes (ej. actualizaciones de estado)
        if "messages" not in change:
            return {"status": "ignored"}

        message = change["messages"][0]
        from_number = message["from"]
        business_number_id = change["metadata"]["phone_number_id"]
        
        # 1. Identificar la Barbería por el ID del número de teléfono o por el metadata
        # Nota: En producción, cada barbería tendría su propio phone_number_id o estaríamos usando un WABA compartido.
        # Por ahora, buscaremos una barbería activa.
        shop = BarberShop.objects.filter(is_active=True).first() # Simplificación para MVP
        
        if not shop:
            logger.error("No active shop found")
            return {"status": "error", "message": "No active shop"}

        whatsapp = WhatsAppClient()
        from .services import BookingService

        # 2. Procesar el tipo de mensaje
        msg_type = message.get("type")

        if msg_type == "text":
            body = message["text"]["body"].lower()
            
            if "cita" in body or "hola" in body:
                # Obtener datos de la tienda para el Flow
                flow_data = BookingService.get_shop_data_for_flow(shop)
                
                # Enviar el Flow de reserva
                # Nota: Necesitamos un FLOW_ID válido de Meta
                flow_id = os.getenv("WHATSAPP_FLOW_ID", "1234567890") # Placeholder
                
                whatsapp.send_flow(
                    to=from_number,
                    flow_id=flow_id,
                    flow_token=f"booking_{from_number}",
                    flow_cta="Agendar Cita",
                    flow_data=flow_data
                )
                
            else:
                whatsapp.send_text(from_number, "Si deseas agendar una cita, escribe 'Cita'.")

        elif msg_type == "interactive":
            # Manejar respuestas interactivas o de Flows
            interactive = message["interactive"]
            if interactive["type"] == "nfm_reply":
                # Respuesta de un WhatsApp Flow
                response_data = json.loads(interactive["nfm_reply"]["response_json"])
                logger.info(f"Flow response: {response_data}")
                
                # Extraer datos de la respuesta (según el diseño del Flow)
                try:
                    appointment = BookingService.create_appointment(
                        shop=shop,
                        client_phone=from_number,
                        client_name=response_data.get("client_name", "Cliente"),
                        service_id=response_data.get("service_id"),
                        staff_id=response_data.get("staff_id"),
                        date_str=response_data.get("date"),
                        time_str=response_data.get("time")
                    )
                    
                    whatsapp.send_text(
                        from_number, 
                        f"¡Excelente {appointment.client_name}! Tu cita para {appointment.service.name} "
                        f"ha sido agendada para el {appointment.start_time.strftime('%d/%m %H:%M')}. "
                        f"Te esperamos en {shop.name}."
                    )
                except Exception as e:
                    logger.error(f"Error creando cita: {str(e)}")
                    whatsapp.send_text(from_number, "Hubo un problema al agendar tu cita. Por favor intenta de nuevo.")

        return {"status": "success"}
    except Exception as e:
        logger.error(f"Error procesando webhook: {str(e)}")
        return {"status": "error", "message": str(e)}

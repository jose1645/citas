from ninja import NinjaAPI
from core.api import router as core_router

api = NinjaAPI(title="FlowCuts API", version="1.0.0")

# Cambiamos /core/ por / para que las rutas cuelguen directo de /api/
api.add_router("/", core_router)

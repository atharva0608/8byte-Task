import logging
import sys

def setup_logging(log_level: str = "INFO"):
    logger = logging.getLogger()
    logger.setLevel(log_level)
    
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(log_level)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    
    # Remove all existing handlers
    for h in logger.handlers[:]:
        logger.removeHandler(h)
        
    logger.addHandler(handler)
    
    # Suppress noisy loggers
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)

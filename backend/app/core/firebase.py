"""Firebase Admin SDK initialization and token verification."""

import json
import logging
from typing import Any, Dict, Optional
import firebase_admin
from firebase_admin import auth, credentials

from app.core.config import settings

logger = logging.getLogger(__name__)

_firebase_app: Optional[firebase_admin.App] = None


class FirebaseTokenError(Exception):
    """Base exception for Firebase token errors."""
    pass


class InvalidTokenError(FirebaseTokenError):
    """Raised when a Firebase token is invalid or malformed."""
    pass


class ExpiredTokenError(FirebaseTokenError):
    """Raised when a Firebase token has expired."""
    pass


def initialize_firebase() -> firebase_admin.App:
    """Initialize Firebase Admin SDK singleton.
    
    Supports:
    1. Direct JSON secret in FIREBASE_CREDENTIALS_JSON (ideal for Render / CI)
    2. Local file path in FIREBASE_CREDENTIALS_PATH
    3. Application Default Credentials with FIREBASE_PROJECT_ID
    """
    global _firebase_app
    
    if _firebase_app is not None:
        return _firebase_app

    # Check if default app is already initialized
    try:
        _firebase_app = firebase_admin.get_app()
        logger.info("Retrieved existing Firebase Admin App instance.")
        return _firebase_app
    except ValueError:
        # App not yet initialized, proceed with initialization
        pass

    try:
        if settings.FIREBASE_CREDENTIALS_JSON:
            logger.info("Initializing Firebase Admin with inline JSON credentials.")
            cred_dict = json.loads(settings.FIREBASE_CREDENTIALS_JSON)
            cred = credentials.Certificate(cred_dict)
            _firebase_app = firebase_admin.initialize_app(cred)
        elif settings.FIREBASE_CREDENTIALS_PATH:
            logger.info(f"Initializing Firebase Admin with certificate file: {settings.FIREBASE_CREDENTIALS_PATH}")
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            _firebase_app = firebase_admin.initialize_app(cred)
        elif settings.FIREBASE_PROJECT_ID:
            logger.info(f"Initializing Firebase Admin with project ID: {settings.FIREBASE_PROJECT_ID}")
            _firebase_app = firebase_admin.initialize_app(
                options={"projectId": settings.FIREBASE_PROJECT_ID}
            )
        else:
            logger.warning("Initializing Firebase Admin with default credentials.")
            _firebase_app = firebase_admin.initialize_app()
            
        return _firebase_app
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
        raise


def verify_firebase_token(token: str) -> Dict[str, Any]:
    """Verify Firebase ID token and return decoded token claims.
    
    Raises:
        InvalidTokenError: If token is malformed, invalid, or verification failed.
        ExpiredTokenError: If token is expired.
    """
    initialize_firebase()
    
    if not token or not isinstance(token, str):
        raise InvalidTokenError("Token is empty or invalid.")

    try:
        decoded_token = auth.verify_id_token(token, check_revoked=False)
        return decoded_token
    except auth.ExpiredIdTokenError as e:
        logger.warning(f"Firebase token expired: {e}")
        raise ExpiredTokenError("Firebase ID token has expired.") from e
    except auth.RevokedIdTokenError as e:
        logger.warning(f"Firebase token revoked: {e}")
        raise InvalidTokenError("Firebase ID token has been revoked.") from e
    except (auth.InvalidIdTokenError, auth.CertificateFetchError, ValueError) as e:
        logger.warning(f"Invalid Firebase ID token: {e}")
        raise InvalidTokenError("Invalid Firebase ID token.") from e
    except Exception as e:
        logger.error(f"Unexpected error verifying Firebase ID token: {e}")
        raise InvalidTokenError("Failed to verify authentication token.") from e

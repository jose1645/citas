import base64
import json
from Crypto.Cipher import AES, PKCS1_OAEP
from Crypto.PublicKey import RSA
from Crypto.Hash import SHA256

class FlowCrypto:
    def __init__(self, private_pem):
        """Initialize with the RSA Private Key (PEM format)"""
        self.private_key = RSA.import_key(private_pem)

    def decrypt_request(self, encrypted_flow_data_b64, encrypted_aes_key_b64, initial_vector_b64):
        """
        Decrypt the request from Meta using pycryptodome (same as flow repo).
        """
        encrypted_flow_data = base64.b64decode(encrypted_flow_data_b64)
        encrypted_aes_key = base64.b64decode(encrypted_aes_key_b64)
        iv = base64.b64decode(initial_vector_b64)

        # 1. Decrypt AES key using RSA-OAEP (SHA256)
        cipher_rsa = PKCS1_OAEP.new(self.private_key, hashAlgo=SHA256)
        aes_key = cipher_rsa.decrypt(encrypted_aes_key)

        # 2. Decrypt Flow Data using AES-GCM
        # In Flows, the last 16 bytes are the tag
        tag = encrypted_flow_data[-16:]
        ciphertext = encrypted_flow_data[:-16]

        cipher_aes = AES.new(aes_key, AES.MODE_GCM, nonce=iv)
        decrypted_payload_bytes = cipher_aes.decrypt_and_verify(ciphertext, tag)

        decrypted_payload = json.loads(decrypted_payload_bytes.decode('utf-8'))
        return decrypted_payload, aes_key, iv

    def encrypt_response(self, response_dict, aes_key, iv):
        """
        Encrypt the response back to Meta using pycryptodome.
        """
        # WhatsApp strict JSON formatting
        response_bytes = json.dumps(response_dict, separators=(",", ":")).encode("utf-8")
        
        # 1. Invert the Initial Vector
        flipped_iv = bytearray()
        for byte in iv:
            flipped_iv.append(byte ^ 0xFF)
        flipped_iv = bytes(flipped_iv)

        # 2. Encrypt Response using AES-GCM
        cipher_aes = AES.new(aes_key, AES.MODE_GCM, nonce=flipped_iv)
        ciphertext, tag = cipher_aes.encrypt_and_digest(response_bytes)
        
        # 3. Concatenate ciphertext + tag and return base64
        encrypted_payload = ciphertext + tag
        return base64.b64encode(encrypted_payload).decode('utf-8')

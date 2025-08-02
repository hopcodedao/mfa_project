from cryptography.fernet import Fernet  
from django.conf import settings  
import base64  
import hashlib  
import os  
  
class FaceEmbeddingEncryption:  
    def __init__(self):  
        # Tạo key từ SECRET_KEY của Django  
        key_material = settings.SECRET_KEY.encode()  
        # Sử dụng SHA256 để tạo key 32 bytes  
        key = hashlib.sha256(key_material).digest()  
        # Encode base64 để tạo Fernet key  
        self.fernet_key = base64.urlsafe_b64encode(key)  
        self.cipher = Fernet(self.fernet_key)  
      
    def encrypt_embedding(self, embedding_str):  
        """Mã hóa face embedding string"""  
        if not embedding_str:  
            return None  
        try:  
            # Chuyển string thành bytes  
            embedding_bytes = embedding_str.encode('utf-8')  
            # Mã hóa  
            encrypted_bytes = self.cipher.encrypt(embedding_bytes)  
            # Trả về dạng base64 string để lưu trong database  
            return base64.b64encode(encrypted_bytes).decode('utf-8')  
        except Exception as e:  
            print(f"Lỗi mã hóa face embedding: {e}")  
            return None  
      
    def decrypt_embedding(self, encrypted_embedding):  
        """Giải mã face embedding"""  
        if not encrypted_embedding:  
            return None  
        try:  
            # Decode base64  
            encrypted_bytes = base64.b64decode(encrypted_embedding.encode('utf-8'))  
            # Giải mã  
            decrypted_bytes = self.cipher.decrypt(encrypted_bytes)  
            # Trả về string  
            return decrypted_bytes.decode('utf-8')  
        except Exception as e:  
            print(f"Lỗi giải mã face embedding: {e}")  
            return None  
  
# Singleton instance  
face_encryption = FaceEmbeddingEncryption()
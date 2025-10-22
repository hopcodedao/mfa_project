# mfa_project/core/token_serializers.py  
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer  

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):  
    @classmethod  
    def get_token(cls, user):  
        token = super().get_token(user)  

        # Thêm thông tin tùy chỉnh vào token  
        token['user_code'] = user.user_code  
        token['role'] = user.role  
        token['first_name'] = user.first_name  
        token['last_name'] = user.last_name  

        return token
from django.core.management.base import BaseCommand  
from core.models import User  
from core.encryption import face_encryption  
  
class Command(BaseCommand):  
    help = 'Mã hóa tất cả face embeddings hiện có trong database'  
  
    def add_arguments(self, parser):  
        parser.add_argument(  
            '--dry-run',  
            action='store_true',  
            help='Chỉ hiển thị những gì sẽ được thực hiện mà không thực sự thay đổi',  
        )  
  
    def handle(self, *args, **options):  
        users_with_embeddings = User.objects.exclude(face_embedding__isnull=True).exclude(face_embedding='')  
          
        self.stdout.write(f'Tìm thấy {users_with_embeddings.count()} người dùng có face embedding')  
          
        encrypted_count = 0  
        for user in users_with_embeddings:  
            # Kiểm tra xem embedding đã được mã hóa chưa  
            try:  
                # Thử giải mã, nếu thành công thì đã được mã hóa rồi  
                decrypted = face_encryption.decrypt_embedding(user.face_embedding)  
                if decrypted:  
                    self.stdout.write(f'User {user.user_code} đã có embedding được mã hóa')  
                    continue  
            except:  
                # Nếu không giải mã được, có thể là plaintext  
                pass  
              
            if not options['dry_run']:  
                # Giả định embedding hiện tại là plaintext  
                original_embedding = user.face_embedding  
                # Mã hóa lại  
                user.set_face_embedding(original_embedding)  
                user.save(update_fields=['face_embedding'])  
                encrypted_count += 1  
                self.stdout.write(f'✅ Đã mã hóa embedding cho user {user.user_code}')  
            else:  
                self.stdout.write(f'[DRY RUN] Sẽ mã hóa embedding cho user {user.user_code}')  
                encrypted_count += 1  
          
        if options['dry_run']:  
            self.stdout.write(self.style.WARNING(f'DRY RUN: Sẽ mã hóa {encrypted_count} face embeddings'))  
        else:  
            self.stdout.write(self.style.SUCCESS(f'Hoàn tất! Đã mã hóa {encrypted_count} face embeddings'))
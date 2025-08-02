import re
from django.core.management.base import BaseCommand
from core.models import Faculty, AdministrativeClass

# Dữ liệu bạn cung cấp, được cấu trúc lại dưới dạng dictionary
# Key là tên Khoa (phải khớp chính xác với tên Khoa bạn đã tạo trong DB)
# Value là một danh sách các tên Lớp sinh hoạt/Chi đoàn
CLASS_DATA = {
    "Khoa Công nghệ Thông tin": [
        "Chi đoàn Khoa học dữ liệu 2021", "Chi đoàn Khoa học máy tính 2021", "Chi đoàn Hệ thống thông tin 2021",
        "Chi đoàn Công nghệ thông tin 2021", "Chi đoàn Kỹ thuật phần mềm 2021", "Chi đoàn Công nghệ thông tin 2022",
        "Chi đoàn Hệ thống thông tin 2022", "Chi đoàn Khoa học dữ liệu 2022", "Chi đoàn Khoa học máy tính 2022",
        "Chi đoàn Kỹ thuật phần mềm 2022", "Chi đoàn Công nghệ thông tin 2023", "Chi đoàn Hệ thống thông tin 2023",
        "Chi đoàn Kỹ thuật phần mềm 2023", "Chi đoàn Khoa học máy tính 2023", "Chi đoàn Khoa học dữ liệu 2023",
        "Chi đoàn Công nghệ thông tin 2024", "Chi đoàn Kỹ thuật phần mềm 2024", "Chi đoàn Hệ thống thông tin 2024",
        "Chi đoàn Khoa học máy tính 2024", "Chi đoàn Khoa học dữ liệu 2024"
    ],
    "Khoa Công nghệ Sinh Hóa - Thực phẩm": [
        "Chi đoàn Công nghệ thực phẩm 2021", "Chi đoàn Công nghệ kỹ thuật hóa học 2021", "Chi đoàn Công nghệ sinh học 2021",
        "Chi đoàn Công nghệ sinh học 2022", "Chi đoàn Công nghệ thực phẩm 2022", "Chi đoàn Công nghệ kỹ thuật hóa học 2022",
        "Chi đoàn Công nghệ kỹ thuật hóa học 2023", "Chi đoàn Công nghệ sinh học 2023", "Chi đoàn Công nghệ thực phẩm 2023",
        "Chi đoàn công nghệ kỹ thuật hóa học 2024", "Chi đoàn công nghệ sinh học 2024", "Chi đoàn công nghệ thực phẩm 2024"
    ],
    "Khoa Kỹ thuật xây dựng": [
        "Chi đoàn Quản lý xây dựng 2021", "Chi đoàn CN kỹ thuật công trình xây dựng 2021", "Chi đoàn Quản lý xây dựng 2022",
        "Chi đoàn CN kỹ thuật công trình xây dựng 2022", "Chi đoàn Quản lý xây dựng 2023", "Chi đoàn CN kỹ thuật công trình xây dựng 2023",
        "Chi đoàn CN kỹ thuật công trình xây dựng 2024", "Chi đoàn Quản lý xây dựng 2024"
    ],
    "Khoa Kinh tế – Quản lý công nghiệp": [ # Đã sửa lại tên khoa cho khớp
        "Chi đoàn Kỹ thuật hệ thống công nghiệp 2021", "Chi đoàn Logistics và Quản lý chuỗi cung ứng 2021",
        "Chi đoàn Quản lý công nghiệp 2021", "Chi đoàn Kế toán 2021", "Chi đoàn Tài chính ngân hàng 2021",
        "Chi đoàn Quản trị kinh doanh 2022", "Chi đoàn Quản lý công nghiệp 2022", "Chi đoàn Kỹ thuật hệ thống công nghiệp 2022",
        "Chi đoàn Logistics và Quản lý chuỗi cung ứng 2022", "Chi đoàn Kế toán 2022", "Chi đoàn Tài chính ngân hàng 2022",
        "Chi đoàn Quản lý công nghiệp 2023", "Chi đoàn Kỹ thuật hệ thống công nghiệp 2023",
        "Chi đoàn Logistics và Quản lý chuỗi cung ứng 2023", "Chi đoàn Kế toán 2023", "Chi đoàn Tài chính ngân hàng 2023",
        "Chi đoàn Quản trị kinh doanh 2023", "Chi đoàn Quản trị kinh doanh 2024", "Chi đoàn Kế toán 2024",
        "Chi đoàn Tài chính ngân hàng 2024", "Chi đoàn Quản lý công nghiệp 2024", "Chi đoàn Kỹ thuật hệ thống công nghiệp 2024",
        "Chi đoàn Logistics và Quản lý chuỗi cung ứng 2024"
    ],
    "Khoa Điện - Điện tử - Viễn thông": [
        "Chi đoàn Công nghệ kỹ thuật năng lượng 2021", "Chi đoàn CN kỹ thuật cơ điện tử 2021", "Chi đoàn CN kỹ thuật điện, điện tử 2021",
        "Chi đoàn CN kỹ thuật năng lượng 2022", "Chi đoàn CN kỹ thuật điện, điện tử 2022", "Chi đoàn CN kỹ thuật cơ điện tử 2022",
        "Chi đoàn CN kỹ thuật điện, điện tử 2023", "Chi đoàn CN kỹ thuật năng lượng 2023", "Chi đoàn CN kỹ thuật điều khiển và tự động hóa 2023",
        "Chi đoàn CN kỹ thuật cơ điện tử 2023", "Chi đoàn Công nghệ kỹ thuật điện, điện tử 2024", "Chi đoàn Công nghệ kỹ thuật năng lượng 2024",
        "Chi đoàn Công nghệ kỹ thuật vi mạch bán dẫn 2024"
    ],
    "Khoa Khoa học xã hội": [
        "Chi đoàn Ngôn ngữ Anh năm 2021", "Chi đoàn Luật năm 2021", "Chi đoàn Luật năm 2022", "Chi đoàn Ngôn ngữ Anh năm 2022",
        "Chi đoàn Ngôn ngữ Anh khóa 2023", "Chi đoàn Luật khóa 2023", "Chi đoàn Luật khóa 2024", "Chi đoàn Ngôn ngữ Anh khóa 2024"
    ],
    "Khoa Kỹ thuật cơ khí": [
        "Chi đoàn CN kỹ thuật cơ điện tử 2021", "Chi đoàn CN kỹ thuật điều khiển và tự động hóa 2021",
        "Chi đoàn CN kỹ thuật Điều khiển và tự động hóa 2022", "Chi đoàn CN kỹ thuật cơ điện tử 2022",
        "Chi đoàn CN kỹ thuật cơ điện tử 2023", "Chi đoàn CN kỹ thuật điều khiển và tự động hóa 2023",
        "Chi đoàn CN kỹ thuật điều khiển và tự động hóa 2024", "Chi đoàn CN kỹ thuật cơ điện tử 2024"
    ]
}


class Command(BaseCommand):
    help = 'Tự động thêm dữ liệu các Lớp sinh hoạt (Chi đoàn) vào database từ một cấu trúc định sẵn.'

    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.SUCCESS('Bắt đầu quá trình thêm dữ liệu các lớp sinh hoạt...'))
        
        created_count = 0
        skipped_count = 0

        for faculty_name, class_names in CLASS_DATA.items():
            try:
                # Lấy đối tượng Khoa từ database
                faculty = Faculty.objects.get(name=faculty_name)
                self.stdout.write(f'Đang xử lý Khoa: {faculty.name}')

                for full_class_name in class_names:
                    # Dùng regex để tìm năm (4 chữ số) trong tên lớp
                    year_match = re.search(r'(\d{4})', full_class_name)
                    if not year_match:
                        self.stdout.write(self.style.WARNING(f'  - Bỏ qua: không tìm thấy năm trong "{full_class_name}"'))
                        continue
                    
                    year = int(year_match.group(1))

                    # Tạo mã lớp tự động (viết tắt các chữ cái đầu)
                    # Ví dụ: "Chi đoàn Khoa học máy tính 2021" -> "KHMT2021"
                    name_part = full_class_name.replace(str(year), '').strip()
                    # Bỏ các tiền tố không cần thiết
                    name_part = name_part.replace('Chi đoàn', '').replace('Lớp', '').replace('năm', '').replace('khóa', '').strip()
                    # Lấy các chữ cái đầu
                    acronym = ''.join(word[0] for word in name_part.upper().split())
                    class_code = f"{acronym}{year}"

                    # Dùng get_or_create để tránh tạo trùng lặp nếu chạy lại lệnh
                    obj, created = AdministrativeClass.objects.get_or_create(
                        class_code=class_code,
                        defaults={
                            'faculty': faculty,
                            'year_of_admission': year
                        }
                    )
                    
                    if created:
                        self.stdout.write(self.style.SUCCESS(f'  + Đã tạo: {obj.class_code} ({full_class_name})'))
                        created_count += 1
                    else:
                        self.stdout.write(self.style.NOTICE(f'  = Bỏ qua (đã tồn tại): {obj.class_code}'))
                        skipped_count += 1

            except Faculty.DoesNotExist:
                self.stdout.write(self.style.ERROR(f'LỖI: Không tìm thấy Khoa "{faculty_name}" trong database. Vui lòng kiểm tra lại tên.'))

        self.stdout.write(self.style.SUCCESS('-----------------------------------------'))
        self.stdout.write(self.style.SUCCESS(f'Hoàn tất! Đã tạo {created_count} lớp mới, bỏ qua {skipped_count} lớp đã tồn tại.'))
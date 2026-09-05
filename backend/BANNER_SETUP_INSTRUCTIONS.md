# KhOrder Banner System — Laravel Backend Setup

## 1. Copy Files

```
backend/database/migrations/2024_01_01_000001_create_banners_table.php
  → your-laravel-project/database/migrations/2024_01_01_000001_create_banners_table.php

backend/app/Models/Banner.php
  → your-laravel-project/app/Models/Banner.php

backend/app/Http/Controllers/Api/BannerController.php
  → your-laravel-project/app/Http/Controllers/Api/BannerController.php

backend/app/Http/Controllers/Api/AdminBannerController.php
  → your-laravel-project/app/Http/Controllers/Api/AdminBannerController.php
```

## 2. Add Routes

Add the banner routes from `backend/routes/api.php` to your existing `routes/api.php`.

## 3. Run Migration

```bash
php artisan migrate
```

## 4. Setup Storage Link

```bash
php artisan storage:link
```

This creates a symlink from `public/storage` → `storage/app/public`.
Uploaded banner images are stored in `storage/app/public/banners/`.

## 5. Update APP_URL

Make sure `APP_URL` in `.env` is correct so image URLs are generated properly:

```
APP_URL=http://127.0.0.1:8000
```

## 6. CORS

Ensure your `config/cors.php` allows your Flutter app's origin:

```php
'allowed_origins' => ['*'],
```

## API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/banners` | None | Active banners (customer) |
| GET | `/api/admin/banners` | Admin | All banners |
| POST | `/api/admin/banners` | Admin | Create banner (multipart) |
| PUT | `/api/admin/banners/{id}` | Admin | Update banner (multipart) |
| DELETE | `/api/admin/banners/{id}` | Admin | Delete banner |

## Upload Format

```
Content-Type: multipart/form-data

Fields:
- image: file (required for create, optional for update)
- title: string (optional)
- is_active: boolean (optional, default true)
- sort_order: integer (optional, default 0)
```

## Validation

- Image: required, must be image type, jpeg/jpg/png/webp/gif, max 5MB
- Title: optional string, max 255 chars
- Sort Order: optional integer, min 0

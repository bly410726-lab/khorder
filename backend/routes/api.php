<?php

use App\Http\Controllers\Api\AdminBannerController;
use App\Http\Controllers\Api\BannerController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes — Banner Endpoints
|--------------------------------------------------------------------------
| Add these routes to your existing Laravel api.php routes file.
| The middleware 'auth:sanctum' and 'admin' should match your existing setup.
|
| For customer: no auth required for viewing active banners.
| For admin: requires authenticated admin user.
*/

// Customer: Active banners (public)
Route::get('/banners', [BannerController::class, 'index']);

// Admin banner management (requires admin auth)
Route::prefix('admin')->middleware(['auth:sanctum', 'admin'])->group(function () {
    Route::get('/banners', [AdminBannerController::class, 'index']);
    Route::post('/banners', [AdminBannerController::class, 'store']);
    Route::put('/banners/{id}', [AdminBannerController::class, 'update']);
    Route::delete('/banners/{id}', [AdminBannerController::class, 'destroy']);
});
